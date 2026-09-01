# Chute

**Drop context into your agent.**

A macOS utility for people who spend all day driving coding agents. It turns a Finder selection
into agent-ready context, and turns agent output back into files.

Offline. Zero telemetry. No account. No launch daemon, no background service, and not one line
of network code.

![Copy files and contents from Finder, with a token count](marketing/media/bundle.gif)

---

## Why

Running agents 10 hours a day means paying a tax on every loop:

| You do this | Times a day | By hand | With Chute | Saves |
|---|---|---|---|---|
| Feed it a folder, one file at a time | 17 | 150 s | 5 s | **41.1 min/day** |
| Paste the clipboard into a new file | 25 | 35 s | 4 s | 12.9 min/day |
| Type a file path into a prompt | 32 | 20 s | 3 s | 9.1 min/day |
| Collect files across folders, then hand them over | 12 | 45 s | 4 s | 8.2 min/day |
| Show it the shape of a folder | 10 | 30 s | 3 s | 4.5 min/day |
| Find out what is holding port 3000 | 11 | 30 s | 3 s | 4.9 min/day |

That is **~80 minutes a day** — 80.7, for the app's own surface. Every figure comes from
[`site/src/lib/cases.ts`](site/src/lib/cases.ts), which `site/scripts/check-cases.mjs` re-derives
from [`docs/03-JTBD-LEDGER.md`](docs/03-JTBD-LEDGER.md) on every build.

Two honest notes, because they are the first things a sceptic asks. **These are timings of one
person's workflow**, not a study. And the free MIT CLI carries another 75.3 min/day of its own —
the 156.0 total is real and it is not a number to wave at a buyer, because two thirds of it costs
nothing.

---

## Install

The free, MIT command-line tool:

```bash
brew install avaluev/tap/chute
```

The Chute.app (Finder menu, menu-bar switcher, hotkey):

```bash
./Scripts/install.sh
```

Installs `~/Applications/Chute.app` (menu bar `⤓`, hotkey `⌥⌘N`). The CLI comes from Homebrew.

Remove it completely at any time:

```bash
./Scripts/uninstall.sh
```

**Three ways to use it:** right-click in Finder — the actions sit inline in the context menu,
with no `Chute ▸` hop to open first — the `⌥⌘N` hotkey anywhere, or the `chute` CLI.

The Finder menu is a sandboxed `FIFinderSync` extension inside the app. `install.sh` registers and
enables it for you; if it ever goes missing, tick it in System Settings → Privacy & Security →
Extensions → Finder → ☑ Chute, or run `pluginkit -e use -i dev.valuev.chute.finder`.

---

## The loop

```bash
# context in — select files in Finder, or name them
chute paths src/*.ts                 # clean absolute paths → clipboard
chute bundle src/ --format xml       # every file's contents in one blob + token count
chute tokens src/                    # will this fit the window?

# work safely
chute checkpoint .                   # snapshot everything, including untracked files
chute sandbox spike-auth --yolo      # folder + git + CLAUDE.md + terminal running claude

# artifacts out
chute basket add src/*.ts            # collect files across folders
chute basket copy --format context   # hand them over to the agent
chute new                            # clipboard → a correctly named, correctly typed file
chute diff . --copy                  # what did the agent actually change?
```

## Every command

| Command | Does |
|---|---|
| `chute paths <files…>` | Absolute paths for a prompt. `--format posix\|quoted\|relative\|at` |
| `chute bundle <files…>` | Files + contents in one blob. `--format xml\|md` |
| `chute tokens <files…>` | Estimated token cost, per file and total |
| `chute tree [dir]` | Directory skeleton, junk excluded. `--depth N` |
| `chute new` | Clipboard → new file, named from its `# heading`, extension from its syntax |
| `chute seed [dir]` | `CLAUDE.md`, `.cursorrules`, `AGENTS.md`, `SCRATCHPAD.md`. Never overwrites |
| `chute note "…"` | Append to `SCRATCHPAD.md` — where you left off |
| `chute latest [dir]` | Reveal the newest artifact. `--quicklook` |
| `chute clean [dir]` | List agent scratch files. **Lists by default**, Trashes with `--force` |
| `chute sandbox [name]` | Folder + git + rules + terminal + agent. `--agent claude\|codex\|gemini --yolo --each` |
| `chute open [dir]` | Terminal or editor here. `--with terminal\|editor` |
| `chute ports` | Every local server: port, what it is, which project, reachable from where. `--kill 3000` |
| `chute checkpoint [dir]` | Snapshot before the agent runs — never touches your worktree |
| `chute diff [dir]` | What changed. `--copy` puts the patch on the clipboard |
| `chute redact` | Mask API keys and tokens before sharing |
| `chute gist <files…>` | Secret gist, URL on the clipboard |
| `chute dataurl <image>` | Base64 data URL for vision prompts. `--markdown` |
| `chute basket add\|list\|copy\|clear` | Collect files across folders, hand them over once — `copy` gives `@mentions` or the files themselves |
| `chute prompt decompose\|ponytail` | Prompt templates: split work into 15-min tasks; cut over-engineering |
| `chute env inject [dir]` | Keychain → `.env`. Refuses unless `.env` is gitignored |
| `chute sessions` | Every terminal session, grouped by state. `--json` |
| `chute focus <key\|project\|N>` | Bring that session to the front. Asks when a name matches several |
| `chute hooks snippet\|uninstall\|status` | Agent status hooks — printed for YOU to paste; Chute never edits your settings |
| `chute doctor` | Check every prerequisite and say how to fix it. `--fix --json` |

Add `--no-copy` to any command to keep the clipboard untouched.

---

## Which agent is waiting for you

![Sessions grouped by whether they need you](marketing/media/sessions.gif)


```bash
chute sessions          # → 9 session(s), 2 need you
chute focus studylock   # by project name — asks if several match, never guesses
chute focus 3           # or by the number sessions printed
chute doctor            # what is not wired up yet, and the exact fix
```

The menu bar `⤓` carries the count of sessions that want you. Click it for the list, colour-coded
per project. Click a row to bring that terminal forward, or use `chute focus <name|N>` from
anywhere.

**The badge needs hooks to be interesting, and wiring them is your call, made by your hand.**
Without them Chute can only read the terminal title glyph and the busy flag, so every session
reads `working` and the badge stays dark. With them, Claude Code reports `blocked` (a permission
prompt) and `waiting` (your turn) as they happen.

**Chute never writes to `~/.claude/settings.json` — or to any other tool's configuration.**
Your agent setup is fragile and it is yours; no menu-bar utility should be editing it, however
carefully. So:

```bash
chute hooks status            # read-only: what is wired now
chute hooks snippet           # prints the JSON — paste it into settings.json yourself,
                              # or add the same commands via Claude Code's /hooks menu
chute hooks uninstall         # removes exactly the blocks OLD Chute versions added (≤0.1.0
                              # wrote them) — backs up first, touches nothing of yours
```

The hook commands themselves only ever write to `~/.chute/sessions/` and always exit 0, so a
Chute failure can never break an agent session.

Only live terminals count toward the badge: a hook record from a window you have since closed is
ignored, so the number never inflates behind your back.

---

## What is running locally

The menu bar lists every local server, so you never again hunt for which of six terminals holds
port 3000:

```
Local servers (8)
  :3000 · next · studylock       ▸ Open in Browser · Copy the URL · Stop It (kill 55868)
  :5432 · postgres
```

Each row names the port, what the process actually is, and the project folder it is running in.
`chute ports` prints the same list, and says whether each one is reachable from your whole network
or only from this Mac. `chute ports --kill 3000` frees a port.

macOS's own background listeners (AirPlay on 7000, `rapportd` on a random high port) are left out —
they are never what the question "what is running?" means.

---

## Safety

Chute is built to be trusted with a repo an agent is about to rampage through.

- **`clean` previews by default.** Nothing is deleted without `--force`.
- **`checkpoint` cannot lose work.** It stages into a private index file, so your real index,
  your worktree and `HEAD` are never touched. It only ever adds a branch.
- **`new` and `seed` never overwrite.** Collisions become `-2`, `-3`.
- **`clean` moves files to the Trash**, never `rm`.
- **`env inject` reads the Keychain only**, prints key names but never values, and refuses to
  create a `.env` that git would track.
- **No network code at all.** `grep -rn 'URLSession\|NSURLConnection' Sources/` returns nothing.
  One command, `chute gist`, uploads — by shelling out to your own `gh`, with your own
  credentials, on the files you name, after redacting keys and tokens. Chute never opens a socket.

---

## How this was built

Six weeks, one person, coding agents doing most of the typing — and about a fifth of the repository
by volume is the machinery that checks the other four fifths.

That ratio is the whole finding. Agents made writing code cheap and left the cost of trusting it
exactly where it was, so the interesting engineering moved into the gates:

| Gate | What it checks that a normal test does not |
|---|---|
| [`Scripts/check-metrics.sh`](Scripts/check-metrics.sh) | a **magnitude** against something physical — RAM, cores, a load of known size. Written after a CPU figure shipped 24× wrong with every shape assertion green |
| [`Scripts/check-untested-logic.sh`](Scripts/check-untested-logic.sh) | decision points in targets no test can import may **shrink freely and never grow**. Written after a one-line bug shipped past 917 green assertions |
| [`Scripts/acceptance.sh`](Scripts/acceptance.sh) | all 9 Finder actions against a hostile tree — symlink loops, 10 MB files, quotes in filenames |
| [`site/scripts/check-claims.mjs`](site/scripts/check-claims.mjs) | every published claim against the **artifact that implements it** — the CLI's dispatch switch, `du` on the bundle, `spctl` on the app. Not against a list a human maintains |

The method, the five ways a green suite lied, and the seven rules that came out of it are written
up in full:

**→ [The harness is the product](marketing/11-BUILDING-WITH-AGENTS.md)** — how to build this way,
with every bug that taught each rule.

Two companion documents, both decision memos rather than narrative:

- [Can I sell a DMG without an Apple ID?](marketing/09-APPLE-AND-DISTRIBUTION.md) — the Gatekeeper
  wall measured in clicks, the Homebrew cask deadline of 2026-09-01, and the arithmetic that
  settles it
- [`handoff/NEXT.md`](handoff/NEXT.md) — the live state of the project, including what is broken

## Development

```bash
swift build -c release                # build
swift run -c release chutetests       # the unit suite
CHUTE_HEADLESS=1 ./Scripts/smoke.sh   # the CLI end to end, no GUI
./Scripts/smoke.sh                    # + the Finder/Terminal sections
./Scripts/build-app.sh                # assemble Chute.app, stamped with the git SHA
```

The tally each of those prints lives in `marketing/06-FACT-SHEET.md` §Verification, and only
there. This block used to carry its own copies — "751 assertions", "128 passed" — and both were
wrong by the time anyone read them. Run the gate and read its tally; a count copied into a second
file is a count nobody re-derived.

No third-party dependencies. Builds with Command Line Tools — Xcode is not required.
`swift test` is unavailable on a CLT-only toolchain (XCTest ships with Xcode), so the suite is a
plain executable with an assert harness instead.

Specs live in [`docs/`](docs/): business requirements, FR/NFR, the JTBD ledger, the customer
journey map, and the definition of done.

---

## Licence

Chute is open-core, and the split is in the files rather than only in this paragraph.

| | |
|---|---|
| **MIT** | `Sources/chute/` (the CLI), `Sources/ChuteCore/`, `Sources/chutetests/`, `Scripts/`, and everything outside `Sources/` except `Resources/` |
| **All rights reserved** | `Sources/ChuteApp/`, `Sources/ChuteFinder/`, `Resources/` — the paid app, each with its own `LICENSE` |

The CLI is free and MIT, forever, and `install.sh` symlinks it straight out of the app bundle. The
Finder right-click menu and the menu-bar session switcher are the $19 app: their source is
published so it can be read and audited, not so it can be redistributed.

The scope note at the top of [`LICENSE`](LICENSE) is the authoritative version, and
`Scripts/smoke.sh` §25 fails if a new directory under `Sources/` is not named in it.
