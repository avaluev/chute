# Design — Agent Session Switcher

**Date:** 2026-08-26 · **Status:** awaiting review · **Subsystem:** 2 of 2

## Problem

One screen, many agents. At the moment this spec was written the founder's Mac had **8 Terminal
windows open, 5 of them running `claude`**, all full-screen-overlapping on a single display:

```
studylock      — chmod ◂ pyenv-rehash                      plain shell
studylock      — Freebuff: go ahead                        node, busy
sntz_mockups   — ✳ File-size gate refactor complete        claude, busy
docs           — -zsh                                      plain shell
BigDeal        — -zsh                                      plain shell
studylock      — ✳ Product roadmap and GTM strategy        claude, busy
36.macai       — ◑ Chut                                    claude, busy
sntz_mockups   — ✳ Claude Code                             claude, busy
```

Two of these needed a human. There is no way to tell which without ⌘-tabbing through all eight and
reading each one. Every switch costs the founder the thing agents were supposed to give back:
attention.

### The job

> When I am running five agents at once on one screen, I want to see every session, which project
> it belongs to, what it is doing, and **which ones are waiting for me** — and jump to any of them
> in one keystroke — so I stop hunting through overlapping windows.

Frequency: constant, all day. This is not a convenience; on a single display it is the difference
between five agents being leverage and being noise.

## What we get for free

Terminal.app's AppleScript dictionary already exposes everything needed. Verified output:

```
WINDOW id 207250 | name: sntz_mockups — ✳ File-size gate refactor complete — node ◂ claude
   TAB tty=/dev/ttys000 busy=true selected=true procs=login-zsh claude node … title=✳ File-size…
```

| Datum | Source | Use |
|---|---|---|
| Window id | `id of w` | focus target |
| Project | first segment of `name of w` | grouping and colour |
| Live status | `custom title of t` | Claude Code writes its current activity here |
| tty | `tty of t` | join key to hook state |
| busy | `busy of t` | fallback activity signal |
| processes | `processes of t` | `claude` present ⇒ agent session |
| selected | `selected of t` | which tab is frontmost |

No Accessibility permission. No screen recording. No polling of process tables.

## Architecture

```
Sources/ChuteCore/
  Session.swift            model + state enum + colour assignment   pure, tested
  SessionState.swift       state resolution priority rules          pure, tested
  TerminalAdapter.swift    protocol: discover() -> [Session]; focus(Session)
  TerminalAppAdapter.swift AppleScript implementation for Terminal.app
  HookState.swift          read/write ~/.chute/sessions/*.json      pure I/O
  HookInstaller.swift      safe merge into ~/.claude/settings.json
Sources/ChuteApp/
  SessionMenu.swift        NSMenu construction, badge, ⌥1…8
Sources/chute/Commands/
  SessionCommands.swift    chute sessions | focus | hooks install|uninstall|status
```

`TerminalAdapter` is a protocol from day one so iTerm2, Ghostty and Warp are ~60 lines each later
without touching the model, the menu, or the tests. Only `TerminalAppAdapter` ships in v1 —
Terminal.app is the only terminal installed on this machine, so it is the only one that can be
honestly verified.

### Model

```swift
public struct Session: Equatable {
    public let key: String          // "terminal:207250:ttys004" — stable identity
    public let app: TerminalKind    // .terminalApp (…iTerm, .ghostty later)
    public let windowID: Int
    public let tabIndex: Int
    public let tty: String          // "/dev/ttys004"
    public let project: String      // "36.macai"
    public let cwd: String?         // from hook payload when available
    public let title: String        // "◑ Chut"
    public let isAgent: Bool        // "claude" ∈ processes
    public let busy: Bool
    public let state: SessionState
    public let since: Date?         // when the state last changed
}

public enum SessionState: Int, Comparable {
    case blocked   = 0   // PermissionRequest — needs you NOW
    case waiting   = 1   // Stop — finished, awaiting your next prompt
    case working   = 2   // UserPromptSubmit — agent is running
    case idle      = 3   // plain shell, no agent
    case unknown   = 4   // discovered but unresolvable
}
```

`Comparable` by raw value gives the menu ordering for free: blocked first, idle last.

### State resolution — strict priority

```
1. Hook state file            ~/.chute/sessions/<tty>.json, if mtime < 6h   ← authoritative
2. Title glyph                mapped via GlyphTable                          ← fallback
3. busy flag                  busy ⇒ .working, else .waiting (agent) / .idle (shell)
4. .unknown
```

Rule: a hook state older than **6 hours** is treated as stale and ignored, so a crashed session
cannot pin a false "waiting" badge forever.

**Glyph mapping is empirical, not guessed.** Observed in the wild: `✳` and `◑` both appear on busy
Claude sessions. `GlyphTable` is a dictionary in one file with a comment recording what was
observed and when; an unrecognised glyph falls through to the busy flag rather than inventing a
state. If Claude Code changes its glyphs, one table changes.

### Hook integration — the precise signal

Chute installs four hooks. Each is a single-line shell command writing one small JSON file.

| Claude Code event | State written | Meaning |
|---|---|---|
| `PermissionRequest` | `blocked` | Claude is stopped, asking permission. **Highest priority.** |
| `Stop` | `waiting` | Turn finished; awaiting your next prompt |
| `UserPromptSubmit` | `working` | You sent something; the agent is running |
| `SessionStart` | `working` | Session began; registers cwd and project |

**Joining a hook to a terminal tab.** The hook is spawned by the `claude` process, so its parent's
tty *is* the tab's tty:

```sh
TTY=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' ')     # → ttys004
```

That maps directly onto AppleScript's `/dev/ttys004`. This is why the join key is the tty and not
the cwd — the founder had **two** windows in `sntz_mockups`, so cwd is not unique.

State file `~/.chute/sessions/ttys004.json`:

```json
{"tty":"ttys004","state":"blocked","cwd":"/Users/sxope/…/37.chute",
 "session_id":"40b25686-…","event":"PermissionRequest","ts":1756219200}
```

Written atomically (temp file + `mv`) so a half-written file is never read.

### Hook installation must not damage a live config

`~/.claude/settings.json` is the founder's global configuration, currently carrying 12 configured
hook events, each with exactly one matcher block containing long plugin commands. Losing it would
be worse than the problem this feature solves.

`chute hooks install` guarantees:

1. **Back up first** — copy to `~/.claude/settings.json.chute-backup-<ISO8601>`; abort if the copy
   fails.
2. **Parse, never template** — load as JSON, mutate the object, re-serialise. No text splicing.
3. **Append only** — add one entry to the `hooks` array of each of the four events. Existing
   entries are never read, reordered, or rewritten.
4. **Idempotent** — every injected command carries the literal marker `chute-session-state`.
   If present, that event is skipped. Running install twice is a no-op.
5. **Validate before replacing** — the new document must re-parse, must contain every top-level key
   the original had, and must contain at least as many entries under every pre-existing hook event.
   Any failure ⇒ leave the original untouched and report the reason.
6. **Reversible** — `chute hooks uninstall` removes exactly the marked entries and nothing else.
7. **Inspectable** — `chute hooks status` prints which events are wired, and the backup path.

The hook command itself never blocks Claude Code: it writes a file and exits, always `exit 0`,
stdout `{}`. A failure to write a status file must never break the founder's agent session.

## The menu

Opened by clicking `⤓` or pressing `⌥⌘N`.

```
NEEDS YOU  (2)
 ●  36.macai        BLOCKED · permission      2m      ⌥1
 ●  studylock       waiting                  14m      ⌥2
─────────────────────────────────────────────────
WORKING  (3)
 ◐  sntz_mockups    File-size gate refactor…          ⌥3
 ◐  sntz_mockups    Claude Code                       ⌥4
 ◐  studylock       Product roadmap and GTM…          ⌥5
─────────────────────────────────────────────────
SHELLS  (3)
 ○  docs            -zsh                              ⌥6
 ○  BigDeal         -zsh                              ⌥7
 ○  studylock       chmod ◂ pyenv-rehash              ⌥8
─────────────────────────────────────────────────
 New Agent Session in…                            ▸
 Chute Actions                                    ▸
─────────────────────────────────────────────────
 Hooks: installed ✓        Refresh        Quit Chute
```

- **Colour dot** per project, deterministic: stable hash of the absolute project path into a
  fixed 12-colour palette chosen to stay distinguishable in light and dark menus. Same project ⇒
  same colour forever, across restarts. Claude Code's own `/color` is not persisted anywhere on
  disk, so Chute owns this and does not depend on a Claude internal.
- **Number keys** `⌥1…⌥8` assigned top-down, so the most urgent session is always `⌥1`.
- **Age** shown only for `blocked`/`waiting` — how long it has been stuck on you.
- **Titles truncated** to 34 characters, middle-elided.
- **Chute Actions ▸** keeps the eight file actions reachable while the FinderSync extension
  (subsystem 1) is still being built. It is a submenu, not the headline.

### Badge

The menu bar title becomes `⤓ 2` when two sessions are blocked or waiting; plain `⤓` at zero.
This is the whole point: **the answer is visible without opening anything.**

### Focus

```applescript
tell application "Terminal"
  set frontmost of window id 207250 to true
  set selected of tab 1 of window id 207250 to true
end tell
activate application "Terminal"
```

`chute focus <key>` exposes the same thing to the CLI and to scripts.

### New Agent Session in… ▸

Lists the distinct projects currently on screen. Selecting one runs the existing
`chute sandbox --dir <project> --yolo` launcher. No new mechanism — it reuses FR-08.

## Refresh strategy

AppleScript costs ~40–80 ms for eight windows. Running that on a timer would burn CPU all day for
a menu that is closed 99% of the time.

| Trigger | What runs | Why |
|---|---|---|
| Menu about to open | full AppleScript discovery | fresh, and the cost is hidden by the click |
| Hook state file changes | badge recount only, no AppleScript | `DispatchSource` on `~/.chute/sessions` — event-driven, zero polling |
| 60 s timer | badge recount only | catches sessions that died without a hook |

**Zero AppleScript while the menu is closed.** Idle CPU stays at nil, satisfying NFR-02.

## Error handling

| Failure | Behaviour |
|---|---|
| Terminal.app not running | Menu shows "No terminal sessions" — not an error |
| AppleScript denied (Automation permission) | One-time explainer item that deep-links to Privacy settings; badge falls back to hook files alone |
| AppleScript times out (>2 s) | Abandon the run, show the last known list marked stale |
| Hook file corrupt | Ignore that one file, resolve by title/busy; never crash the menu |
| `settings.json` unparseable at install time | Refuse to install hooks, print the parse error and the line, change nothing |
| Window closed between discovery and focus | AppleScript error swallowed; list refreshes |

## Testing

**Pure, in the assert harness (`swift run chutetests`):**
- `GlyphTable` mapping, including an unknown glyph falling through to `busy`
- State priority: hook beats title beats busy; a 7-hour-old hook file is ignored
- Colour assignment: deterministic, stable across runs, distinct for the founder's five projects
- Session key stability when a title changes but the window does not
- Title truncation with CJK and emoji (no broken graphemes)
- `HookInstaller` against **fixtures of the real `settings.json` shape**: appends to a populated
  array; is idempotent on second run; refuses and changes nothing on malformed input; uninstall
  restores byte-identical content
- `TerminalAppAdapter` parsing against **recorded AppleScript output** (the real 8-window capture
  above, checked in as a fixture) — no AppleScript needed to run the tests

**End-to-end (`Scripts/smoke.sh`):**
- `chute sessions --json` returns valid JSON with one entry per real window
- `chute hooks install` on a **copy** of settings.json → 4 events gain one entry, all original keys
  survive, second run is a no-op, uninstall restores the original exactly

**Manual gate (a human, once):**
1. Menu bar shows `⤓` with a badge matching the number of idle Claude windows
2. Open the menu — every window appears, grouped, coloured by project
3. Press `⌥1` — that window comes to the front
4. Answer a prompt in one session — its badge state changes within a second

## Definition of done

- [ ] `chute sessions` lists every Terminal window with correct project, state and tty
- [ ] Badge count matches reality with five agents running
- [ ] `⌥1…⌥8` focus the right window every time
- [ ] `chute hooks install` is proven idempotent and reversible against a real-shaped fixture
- [ ] Zero AppleScript calls while the menu is closed (verified by instrumenting the adapter)
- [ ] Menu opens in under 150 ms with 8 windows
- [ ] All existing checks still green: 55 unit assertions, 39 smoke checks

## Deliberately out of scope

| Not doing | Why |
|---|---|
| Closing or killing sessions from the menu | Not requested; destructive; ⌘W in the focused window already works |
| iTerm2 / Ghostty / Warp adapters | Not installed here, so not honestly testable. The protocol makes each ~60 lines later. |
| VS Code integrated terminals | Not enumerable by AppleScript; would need fragile Accessibility scraping |
| Reading Claude Code transcripts for richer status | The hooks give the state directly; parsing another tool's internal files is a maintenance trap |
| Reordering or renaming windows | Terminal.app owns that |

## Open question for the founder

Claude Code's title glyphs (`✳`, `◑`) were observed but their exact meanings are not documented.
The design degrades safely — unknown glyph falls back to the busy flag — but if you know what they
mean, the mapping gets sharper for sessions without hooks installed.
