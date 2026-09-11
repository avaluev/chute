# Chute menu-bar drop-down — design brief

Handed to a visual designer with no access to the codebase. Everything below is derived from the
actual source that builds this menu today — file paths point at the exact place a claim comes
from, so you can ask an engineer to re-check anything that matters to a decision.

Source files this brief is built from (all under
`/Users/sxope/Documents/2026/Development/37.chute/`), **updated 2026-09-08** for the three-column
redesign that shipped that day:

- `Sources/ChuteCore/StatusMenu.swift` — what is in the menu, in what order, and the three-column
  `SessionRow` each session row carries (the model)
- `Sources/ChuteApp/SessionMenu.swift` — how that model becomes an `NSMenu` via `attributedTitle`
  and tab stops (the renderer — decides nothing, see its own header comment)
- `Sources/ChuteCore/SessionDot.swift` — the row's traffic-light dot geometry. Moved out of
  `SessionMenu.swift` on 2026-09-08 after shipping with two of its five states invisible — see §4
- `Sources/ChuteCore/ProjectName.swift` — the one place a session's name is derived (git repo root
  leaf → cwd leaf → terminal window-title head → `nil`), added 2026-09-08
- `Sources/ChuteCore/PathAbbrev.swift` — the path/name truncation rules col 1's second line uses,
  added 2026-09-08
- `Sources/ChuteCore/MenuBarMark.swift` — the menu-bar icon and its state pip
- `Sources/ChuteCore/Session.swift` — the five session states
- `Sources/ChuteCore/SessionCommands.swift` — the ⌥ alternate commands per session
- `Sources/ChuteApp/ServersMenu.swift` — the Local Servers submenu
- `Sources/ChuteCore/SystemVitals.swift` — the CPU/memory numbers on a row
- `Sources/ChuteCore/SessionPhrasing.swift` — the wording on a row
- `docs/specs/MENUBAR-LAYOUT-CALIBRATION.md` — the measured tab stops, fonts and character budgets
  the column layout is built from
- `brand/tokens.json` — the palette and type this design must use

---

## 1. What this thing is for

The person using Chute runs somewhere between five and thirteen coding-agent sessions at once —
Claude Code, Codex, Antigravity — each in its own terminal tab, each working on some project. An
agent session moves through a loop: you give it a prompt, it works, it either stops because it
needs a decision from you (a permission prompt) or stops because it's done and is waiting for the
next prompt, or it just keeps working. With thirteen terminal tabs open there is no way to tell,
by looking at the terminal app, which tab is which of those three things — every tab looks the
same until you click into it. This menu is the answer to one question, asked dozens of times a
day: **which one needs me, and what is everything else doing?** Everything else it shows —
CPU/memory load, a basket of files to paste into an agent, what's listening on localhost — is
secondary to that one job.

---

## 2. Function inventory

Built in order by `StatusMenu.model(...)` (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift:149`).
Everything below is a row or a group of rows in one flat `NSMenu`; nothing floats free of this
order.

**State and project headers are gone, deleted 2026-09-08** — see §5. There is no row left in this
table whose only job is to label a group; sort order, the dot, and the words on the row carry
that now.

| # | Row / section | Present when | Data shown | Click does |
|---|---|---|---|---|
| 1 | **"Cannot read Terminal — click to fix"** | `problem != nil` — Chute lost the ability to read Terminal.app (e.g. Automation permission revoked) | a tooltip carrying the raw problem string | opens System Settings → Automation (`Command.openAutomationSettings`) |
| 2 | separator | after row 1, only if row 1 is present | — | — |
| 3 | **Column header**, `PROJECT · AGENT · STATE · LOAD` | once, only when `sessions` is non-empty | the same three-column shape a session row uses, uppercased, disabled — a `.note` node carrying a `SessionRow` (`StatusMenu.swift:197-201`) | nothing — disabled row |
| 4 | **Session row** | one per live terminal session, sorted state → oldest-first-in-state → project name → tty (`StatusMenu.swift:189-192`) | see §3 below | brings that terminal tab forward (`Command.focusSession`) |
| 5 | **⌥ session-command alternates** (up to 4, stacked on the same row slot) | per session, only for commands that session can actually do — see §2a | the same row, with line 1's state cell replaced by the command's own title | runs that command (copy to clipboard, or open tmux) — see `SessionCommand.available`, `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SessionCommands.swift:51` |
| 6 | separator | at every **state boundary** within the sorted list — never before the first row, since the column header already opens the section (`StatusMenu.swift:203-209`) | — | — |
| 7 | separator | after the last session, only if `sessions` is non-empty | — | — |
| 8 | **"No terminal sessions"** | `sessions.isEmpty && problem == nil` | static text | nothing |
| 9 | **Basket submenu**, e.g. `Basket  (3)` | only when the basket has ≥1 entry — hidden entirely otherwise | count in the title; children are file rows, newest first | opens submenu — see §2b |
| 10 | **Local Servers submenu**, e.g. `Local Servers  (2)` or `No Local Servers Running` | always present; content is discovered live via two `lsof` calls when the menu opens (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/ServersMenu.swift:8`) | one row per listening port, its label, loopback-only vs. network-reachable in the tooltip | opens submenu — see §2c |
| 11 | separator | always | — | — |
| 12 | **"Turn On Chute Notifications…"** | only when `notificationsDenied` — a fallback HUD notification was actually refused by the OS | tooltip explains why this is the last channel left | opens Notification Settings (`Command.openNotificationSettings`) |
| 13 | **"Setup…"** | always | — | opens the setup flow (`Command.openSetup`) |
| 14 | **"Report a Problem…"** | always | — | `Command.reportProblem` |
| 15 | **"Settings…"** | always | — | `Command.openSettings` |
| 16 | separator | always | — | — |
| 17 | **"Quit Chute"** | always, last row | — | quits the app; targets `NSApp`, not Chute — see note at `StatusMenu.swift:351` |

**2a. The ⌥ alternates.** Each session can offer up to four extra actions, each revealed by
holding a specific modifier combination while the menu is open (AppKit's "alternate item"
mechanism — one physical row slot, whichever alternate matches the held modifiers is what's
drawn). Defined in `SessionCommand.modifiers(for:)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SessionCommands.swift:40`):

| Command | Modifier | Shown when |
|---|---|---|
| Copy Session ID | ⌥ | the hook reported a session id at all |
| Copy Resume Command | ⌥⇧ | the agent's resume syntax is known (currently: recognised agents only) |
| Continue in tmux | ⌥⌘ | resume syntax known **and** tmux is installed on this Mac |
| Copy Cost So Far | ⌥⌃ | a transcript exists and has token usage to report |

A command that cannot work for a given session is not shown — never shown disabled. There is no
row that tells the reader "hold ⌥" other than the tooltip on the session row itself.

**2b. Basket submenu**, from `StatusMenu.basket(_:tokens:)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift:315`):
- One row per saved file, newest first: `<filename>      <relative time>`, e.g.
  `middleware.ts      3 min` — the file's parent folder is included when needed to disambiguate,
  and a moved/deleted file reads `<name> — missing` instead of vanishing.
- separator
- "Copy Basket as @mentions"
- "Copy Basket as Context   (~2k tokens)" — token count via `TokenEstimate.badge`
- "Empty Basket"

**2c. Local Servers submenu**, from
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/ServersMenu.swift:8`:
- One row per listening port (its label; tooltip says loopback-only vs. network-reachable and its
  pid), each opening its own sub-submenu of "Open in Browser", "Copy <url>", "Stop It (kill
  <pid>)".
- separator
- "Copy Server List (n)" — re-discovers servers at click time rather than reusing what was shown
  when the menu opened.

---

## 3. The data on a session row

**Two lines, three columns, not one joined string.** A row is a `StatusMenu.SessionRow`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift:117-139`) —
six cells, laid out over real `NSTextTab` stops at 200pt and 500pt
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SessionMenu.swift:85-93`,
measured in `docs/specs/MENUBAR-LAYOUT-CALIBRATION.md`):

```
col 1 (project / title)       col 2 (state / agent)          col 3 (load / note)
line 1:  project name          state + duration                CPU · memory
line 2:  the tab's own title    agent · model · effort          runaway ⚠ / peaked note
```

Built in `StatusMenu.rows(for:...)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift:253`). The
pieces, and whether each is always present:

| Field | Cell | Always present? | Source | Example |
|---|---|---|---|---|
| Project name | col 1, line 1 | Always — `Session.project` is derived once, from the hook's `cwd` via the git repo root, never from Terminal's window title (`ProjectName.swift`). `nil` prints `tty ttys004` instead of a blank | `Session.project`, clamped by `StatusMenu.clampedProjectName` | `sntz_mockups` |
| Tab title | col 1, line 2 | Always, and never a blank — this is the cell that tells two sessions in the SAME directory apart, which the path it replaced (2026-09-11) could not do: six agents in one repo drew six identical rows. The agent's own spinner glyph (`✳`, `◑`) is stripped — it repeats the state dot. A title that names a category rather than a session (Antigravity writes a literal `Terminal`; `claude` writes `Claude Code` before it has named the conversation) or that just repeats the project falls back to `terminal ttys011`, and no `cwd` at all still outranks both with `no project derived` + col 1 **dimmed** (`MenuNode.dim`). The full path moves to the tooltip | `SessionTitle.meaningful`, tail-truncated by `PathAbbrev.name` | `checkout flow rewrite` |
| State + duration | col 2, line 1 | Always — every state prints something here, never blank. Idle and unknown deliberately carry **no duration**: a confident number next to a state Chute admits it doesn't know is the exact mistake that got the old status badge deleted | `SessionPhrasing.held` for blocked/waiting/working; fixed strings for idle/unknown | `blocked 22 min`, `ready 3 min`, `working 5 min`, `no agent running`, `no hook — Chute cannot see this` |
| Agent · model · effort | col 2, line 2 | Present whenever an agent is running; model only when the hook's transcript names one, effort only when it is not the default (`"medium"` is furniture) | `SessionPhrasing.detail` | `Claude Code · Opus 5 · xhigh` |
| CPU · memory | col 3, line 1 | Present whenever the session has ≥1 live process; percent of ONE core, so `177%` means under two cores pinned. Empty — not `0%` — when there is no live process to measure | `StatusMenu.loadColumns` | `177% · 3.0 GB` |
| Runaway / peak note | col 3, line 2 | Only one of the two, never both: `runaway ⚠` when CPU ≥250% of one core or memory ≥8 GB, else a peak note when a process peaked at ≥1.5× its current size and ≥512 MB. Otherwise blank | `StatusMenu.loadColumns` | `runaway ⚠`, `peaked 6.1 GB` |

**`mostly X`, the field that named which one process held most of a session's memory, is gone** —
`loadColumns` only ever returns the two load cells above; a row no longer says which program is
using it, only how much.

**A real row, two lines:**

```
sntz_mockups                              blocked 22 min          177% · 3.0 GB
~/dev/sntz_mockups                        Claude Code · Opus 5 · xhigh
```

A quieter row, no load at all because nothing is currently running:

```
37.chute                                  ready 3 min
~/dev/37.chute                            Claude Code · Sonnet 5
```

A shell with no agent, and no `cwd` behind the name at all — col 1 reads dimmed:

```
tty ttys004                               no agent running
no project derived
```

---

## 4. The state model

Five states, `SessionState` (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Session.swift:8`),
ordered by urgency — this is also the sort order sessions appear in:

| State | What it means | Row dot: colour | Row dot: shape | Icon pip |
|---|---|---|---|---|
| **blocked** | Agent hit a permission prompt — it is stopped, waiting on a decision only you can make | `systemRed` | filled **square**, 9pt | filled **square**, red |
| **waiting** | Agent finished its turn and is waiting for your next prompt | `systemGreen` | filled **circle**, 9pt | filled **circle**, green |
| **working** | Agent is actively running | `systemOrange` | **ring** (34% hole), 9pt | **ring**, orange |
| **idle** | A plain shell — no agent running in it at all | `tertiaryLabelColor` (grey) | small filled dot, 5pt | no pip (quiet mark) |
| **unknown** | Chute has no hook data for this session — the agent ships no hooks (Antigravity today) or the hook hasn't reported yet | `tertiaryLabelColor` (grey) — **same colour as idle** | **ring** (25% hole), **7pt** | no pip (quiet mark) |

Source: `SessionDot.image(_:)` and its `ink`/`form` tables in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SessionDot.swift:45-70` — moved
out of `SessionMenu.swift` on 2026-09-08, see the postmortem below; the icon pip table (`pips`) in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MenuBarMark.swift:109`.

**The two hard rules, both enforced in the row dot today, both must survive redesign:**

1. **Shape carries the meaning; colour is the redundancy, not the other way round.** Roughly 1 in
   12 men in this product's own audience cannot reliably separate the red from the green used
   here. Squint, or view in grayscale, and the three "needs action" states must still read as
   three different things from shape alone: filled square (blocked) vs. filled circle (waiting) vs.
   ring (working). **Fixed 2026-09-08** — blocked and waiting used to share a 9pt filled disc and
   differ only by colour, which broke this exact rule; they are a square and a circle now (see the
   postmortem below for why the fix wasn't as simple as changing a corner radius).
2. **Unknown must never look like "all clear."** idle and unknown deliberately share the same
   grey ink so neither reads as more or less alarming than the other by colour — the only thing
   separating "you have a quiet shell" from "Chute has no idea what this session is doing" is
   shape (small filled dot vs. ring). An un-instrumented machine — someone who has only ever used
   Antigravity, which ships no hooks — must not have a menu that reads as calm. It should read as
   uninstrumented. **`unknown`'s ring grew from 5pt to 7pt on 2026-09-08** because at 5pt its hole
   rasterises away to nothing at 1×, so it painted the identical pixels as `idle` — the two states
   this rule exists to keep apart looked exactly alike. See the postmortem.

**Postmortem: the dot that drew nothing.** `blocked` and `waiting` — the two states the whole
product exists to surface — painted **nothing at all**, for this product's entire life, until
2026-09-08. The drawing code built a "hole" the same size as the outer shape and relied on
`NSBezierPath`'s `.evenOdd` winding rule to cancel it to a solid fill:

```swift
let hole = r.insetBy(dx: f.d * f.hole, dy: f.d * f.hole)   // f.hole == 0 meant "filled"
path.append(NSBezierPath(roundedRect: hole, ...))
path.windingRule = .evenOdd
```

Under `.evenOdd`, a point inside both rectangles has a crossing number of two — even — which is
*outside* the filled region. The same rectangle twice does not cancel the hole, it cancels the
**shape**. `hole: 0` never meant "filled"; it meant "draw nothing." Nothing could catch it:
`Scripts/check-untested-logic.sh` counts branches, and this code had none — it was branch-free and
wrong. It lived in `Sources/ChuteApp/`, a target `chutetests` cannot link, so no assertion could
import it either. The only instrument that could have caught it was somebody looking, and the menu
had never been rendered to an image before that day. Once it was — see `Scripts/screens.sh` —
the fix moved the geometry into `Sources/ChuteCore/SessionDot.swift`, where `SessionDotSuite`
renders every token and counts the pixels it actually painted. A dot that draws nothing now fails
the build. That suite immediately caught the second bug above (`unknown` at 5pt). **Any redesign
that touches this geometry must keep a pixel-counting test on it** — a branch-free drawing routine
with a plausible-sounding comment is exactly the shape of bug this whole product's testing
doctrine exists to catch, and here it beat the doctrine for a full release.

**Worth flagging to the designer as a real gap, not a design opinion:** the menu-bar *icon*
itself only carries a pip for blocked/waiting/working — a positive claim backed by a fresh hook.
When every session is `idle` and when every session is `unknown`, the icon shows the identical
quiet mark in both cases (`MenuBarMark.image`, plain, no pip). So at the icon level — not the
row level inside the dropdown — "nothing needs you" and "I have no idea what any of these are
doing" currently look the same. Rows inside the dropdown do distinguish them (see table above);
the icon does not. Whether that's acceptable or needs its own pip is a real open question — verify
with the founder before assuming either answer.

---

## 5. The current layout — what ships as of 2026-09-08

What renders today is still a single flat `NSMenu` — no window, no custom view, just `NSMenuItem`
rows handed to AppKit — built by `SessionMenu.render(_:into:...)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SessionMenu.swift:179`). What
changed is everything about how a row is drawn. In order, top to bottom:

- one column header row, `PROJECT · AGENT · STATE · LOAD` uppercased and disabled — printed once,
  only when there is at least one session, never repeated per group because there are no more
  groups to repeat it for
- session rows, each two lines over three real tab-stopped columns (§3): a 12×12 traffic-light dot
  image, then `attributedTitle` text laid out at the 200pt and 500pt stops measured in
  `docs/specs/MENUBAR-LAYOUT-CALIBRATION.md` — project/path in col 1, state/agent in col 2,
  load/note in col 3, monospaced digits in col 3 so the numbers do not jitter as `LiveVitals`
  rewrites them every two seconds
- a separator at every **state boundary**, never at the top — sort order (blocked → waiting →
  working → idle → unknown, oldest-first within a state) puts the thing that has been costing you
  the most at the very top of the list, with no header needed to say so
- the Basket, Local Servers, and utility rows below, in the fixed order from §2

**State and project section headers are deleted, 2026-09-08**
(`StatusMenu.swift:176-183`, the comment block headed "COLUMNS, NOT HEADERS"). What used to be
"`NEEDS YOU (2)`" printed once per group, and a project sub-header printed again inside it, is now
carried entirely by the row itself: the dot's shape says the state, the state cell's own words say
it again in text (`blocked 22 min`), and the project name is on every single row rather than
hidden behind a sub-header that only appeared when ≥2 sessions shared both a state and a project.
Two sessions in the same project simply repeat their project name — that repetition is what the
columns buy, and it replaced seven sub-headers over eight rows on the founder's own machine on
2026-09-08, the same session that measured the ragged-column and no-hierarchy failures below being
fixed rather than just described.

**What this fixed, plainly, from the layout this replaced:**

- **Run-on rows, no columns — fixed.** The old row was one string built by joining fields with
  three literal spaces, which does not align under a proportional font: a 6-character project name
  and an 18-character one pushed everything after them to a different horizontal position on every
  row. Real `NSTextTab` stops fix this for any string, not just the common case.
- **No visual weight hierarchy — fixed.** Project name, state, and load now carry three distinct
  registers: 13pt semibold for project/state, 11pt regular for agent/note, 12pt monospaced-digit
  for the numbers, at three different `NSColor` label levels. The thing that needs your attention
  (`blocked 22 min`) is no longer typographically identical to the least important thing on the row.
- **Section headers shouting, and a two-level hierarchy doing a three-level job — moot.** There is
  one level of hierarchy left (the row itself), not three, because the two levels above it were
  deleted rather than restyled.
- **List length is unchanged in the worst case** — a machine with 13 sessions across five states
  still shows up to 13 rows before the Basket/Local Servers/Settings block, because nothing
  collapses. What changed is that each of those 13 rows now carries its own identity (project,
  path, state, load) instead of relying on a header two scroll-positions above it to say which
  group it belonged to.
- **No affordance at all for the ⌥ alternates, unchanged.** Still nothing beyond the tooltip on the
  session row itself — this was not part of the 2026-09-08 redesign and remains open, see §9.

## 5a. The name and path — a confidence level, not just a label

`Session.project` is derived exactly once, by `ProjectName.of(cwd:windowTitle:)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/ProjectName.swift:54`): the
git repository root's leaf name, then the `cwd`'s own leaf, then the terminal window-title head,
then `nil`. **Never Terminal's window title first** — before 2026-09-08 the menu derived a
session's name from the title (a string another process writes and the user can reconfigure) while
a different surface derived it from the hook's `cwd`, so the same session could be named two
different things in two places with nothing in the UI to notice. One derivation now, forwarded from
both call sites.

The row says which confidence level it got. Col 1's second line carried the path the name came
from until 2026-09-11, when the tab's own title took the cell (`SessionTitle.swift`) and the path
moved to the tooltip: the path was a second copy of the project name on almost every row, and on a
machine running six agents inside ONE repo it was the same second copy six times, which is how six
distinct sessions rendered as one row repeated. The title is the only field that differs.
**The name is still never derived from it** — a label that sits beside a row and names nothing may
be wrong in a way a name may not. When there is no `cwd` at all — the
derivation fell back to a window-title guess, or found nothing — col 1 reads **dimmed**
(`tertiaryLabelColor` instead of `labelColor`) and line 2 reads `no project derived` instead
of a fabricated-looking blank — that answer outranks the title, because a row Chute cannot place is
worth more than telling two such rows apart. **"No project derived" is a real, displayable answer, not an error
state** — `Session.project` is `String?`, and `nil` is data, never a sentinel string like `"—"`
(a directory can legitimately be named `—`, so a sentinel would make a real project indistinguishable
from no project at all). Two sessions that share a git repository root — `/a/b/repo` and
`/a/b/repo/site` — now print the identical project name, because they are the same project; before
2026-09-08 they could print two different names depending on which surface asked.

---

## 6. The design problem, as constraints

Not solutions — these are the things any layout has to solve, stated as problems:

- **Scanning 13 rows for the one that needs you.** The reader isn't reading top to bottom; they're
  scanning for the one row (or handful) in a `blocked` or `waiting` state, ideally in well under a
  second, ideally without needing the state header text at all — colour/shape should get there
  first.
- **CPU/memory legible without dominating.** These numbers matter (they're how a runaway agent
  gets caught) but they are not the primary signal on the row — state and duration are. A layout
  that gives the numbers equal or greater visual weight than the state has it backwards.
  Simultaneously, a layout that makes them require a hover/reveal defeats their purpose — the
  founder's own history here (§8) is that a number seen only when scanned is a number nobody
  scans for on a bad day.
- **Three levels of hierarchy in a ~360pt-wide menu.** State group → project (sometimes) →
  session. **Resolved 2026-09-08 by deletion, not by a third register** — see §5 and §9: rather
  than finding a third visual weight, the state and project header LEVELS were removed and their
  information folded into the one level left (the row itself). Whether that is the right call for
  every future addition to this menu, or whether some future grouping need brings a real header
  back, is open — but "two registers doing a three-level job" is no longer the shape of the
  problem, because there is only one level now.
- **Never let unknown read as calm.** Whatever visual system replaces the current one has to carry
  this rule forward independent of colour choices — see §4's hard rules.

---

## 7. Hard technical constraints

This is real, not negotiable by aesthetic preference:

- **This is an `NSMenu`, not a window.** Every row is an `NSMenuItem`. There is no custom canvas
  by default, no arbitrary HTML/CSS-style layout, no scroll container.
- **Available today, zero technical risk:**
  - `attributedTitle` — full control of font, weight, colour, and **tab stops**, which is the
    fix for the ragged-column problem in §5. This is the single highest-leverage lever available
    without new engineering risk.
  - `image` — any `NSImage` you can draw, per row (the dots are already this).
  - `indentationLevel` — integer steps. Every row sets it to 0 today: the two-level header/row
    structure that used to need it is gone (§5), and `MenuNode.indent` is kept as a field only
    because the renderer still assigns it unconditionally, at no branch cost.
  - separators, submenus (already used for Basket and Local Servers), and `isAlternate` rows
    behind modifier keys (already used for the ⌥ commands).
- **Possible, but expensive: `NSMenuItem.view`.** A fully custom `NSView` per row buys total
  layout control — real columns, real weight hierarchy, badges, whatever you want — but every
  accessibility behaviour AppKit gives a plain `NSMenuItem` for free (VoiceOver reading order,
  keyboard highlight/navigation, Increase Contrast/Reduce Transparency response) has to be
  rebuilt by hand for that view. It also adds code that `Scripts/check-untested-logic.sh`
  (`/Users/sxope/Documents/2026/Development/37.chute/Scripts/check-untested-logic.sh`) counts
  against a per-file budget of untested decision points in the `ChuteApp` target — that target
  cannot be linked by the test suite at all (see the header comment at
  `StatusMenu.swift:1-18`), so any branch added there is, by construction, untestable by the
  project's own gate. A custom-view redesign is a real engineering cost, not just a drawing task.
- **Not possible in an `NSMenu` at all:** hover animation, web-style flexible layout, internal
  scrolling of the row list.
- **Must work in:** dark and light menu bars, Increase Contrast, and Reduce Transparency — all
  four are real settings real users of this product run, not edge cases.
- **System font metrics.** This is a native macOS menu-bar drop-down. It must look like one, not
  like a web app rendered into a popover.

---

## 8. What must not change, and why

Both of these cost the founder a real, shipped mistake before they were fixed. Treat them as
non-negotiable unless you're explicitly re-opening that decision with the founder directly.

- **No count in the menu-bar icon itself.** A count used to live there, inferred from Terminal's
  `busy` flag and a spinner glyph Claude Code writes into its window title and never clears. It
  read `Working (7)` over seven sessions none of which was working, because the glyph is stale
  evidence, not live state. It was deleted in commit `2849347` and the full postmortem is in
  the comments at `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MenuBarMark.swift:42-54`
  and `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SessionMenu.swift:30-41`.
  The icon today asserts something weaker than a count — "at least one live tty has a fresh hook
  saying so" — on purpose. Do not reintroduce a number here.
- **`unknown` is a real, visible answer, not a fallback bucket.** It must never be folded into
  `idle` for visual convenience. An agent that ships no hooks is a genuinely different fact from a
  plain shell with nothing running, and the reader needs to be able to tell "Chute can't see this"
  from "there's nothing to see."
- **Nothing may be shown that Chute cannot prove from a hook.** Every field in §3 traces back to
  either a hook record or a directly-measured process reading (`ps`/kernel data via
  `SystemVitals`/`ProcessMetrics`) — never inferred from a window title, a spinner glyph, or a
  guess. If a redesign wants a new piece of information on a row, the first question is "where
  does Chute get this from," and "we don't, yet" is a real and acceptable answer that just means
  the row can't show it yet.

---

## 9. What was actually built, and what is still open

The three directions this section used to sketch were a conversation starter, written before any
of them existed. §5 is no longer that conversation — it is what shipped. This section records which
direction the founder actually took, how far past it the build went, and what §6-§8's own open
questions still are, unresolved, today.

### What shipped: past Direction A, not Direction B or C

The build is closest to the old **"Direction A — fix the columns, keep the structure."** Real tab
stops via `attributedTitle` at measured stops (§3, §5) is exactly that lever, and it is still the
only lever used — `NSMenuItem.view` (the old Direction C) was never adopted, and nothing here is a
submenu-per-state rollup (the old Direction B).

**But the structure was not "kept."** Direction A's own sketch still showed `NEEDS YOU` and
per-project sub-headers; what shipped deleted both (§5, §5's "COLUMNS, NOT HEADERS" citation). That
was not the cheap, structure-preserving path Direction A described — it was the harder call that
the columns alone made the headers redundant, and the founder took it rather than stopping at
typography. Direction B's core idea (collapse what you don't need to look at right now) was
rejected outright: nothing in the shipped menu is collapsed or hidden behind a submenu-click,
because ordering by state and putting the dot + duration on every row already answers "which one
needs me" without a click, which is the one job this whole menu exists to do (§1). Direction C's
custom-view cost was never worth paying — the shipped design gets a real two-line, three-column row
entirely out of `NSMenuItem.attributedTitle`, at the accessibility and testability cost of exactly
zero, which is what made it the version that actually got built.

### Still open — not settled by this redesign

- **No affordance for the ⌥ alternates**, beyond a tooltip on hover. Named as a gap before
  2026-09-08 (§5's last bullet) and unchanged by it — the redesign touched what a row shows, not
  how the ⌥/⌥⇧/⌥⌘/⌥⌃ commands are discovered.
- **The icon-level idle-vs-unknown gap is still real.** `MenuBarMark.pips`
  (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MenuBarMark.swift:109-113`)
  carries pips for `blocked`/`waiting`/`working` only — idle and unknown both draw the plain quiet
  mark, identically, at the menu-bar icon. Inside the dropdown the row dot tells them apart (§4);
  the icon still cannot. This was flagged as an open question before the redesign and the redesign
  did not touch `MenuBarMark` at all, so it is exactly as open as it was.
- **`NSMenu.size`'s alternate-item double-count, unconfirmed.** `docs/specs/MENUBAR-LAYOUT-CALIBRATION.md`'s
  own last section says `NSMenu.size` sums a two-line row plus its hidden `isAlternate` alternate as
  if both are visible (88pt vs 49pt for the row alone), and asks for someone to confirm by holding
  ⌥ with the menu open that it doesn't visibly grow. That confirmation is not recorded anywhere as
  having happened. Do it before trusting menu height math for anything new.
- **`mostly X` is gone from the menu row, though not from the product.** The old row said which
  single process held most of a session's memory; `StatusMenu.loadColumns` (§3) only returns CPU,
  memory, and one of a runaway warning or a peak note — `SessionLoad.top` is no longer read there.
  `SessionLoad.label` still produces `mostly X` for `chute sessions`
  (`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/SessionCommands.swift:82`),
  so the two surfaces now disagree on how much a row says about load. Whether the menu should show
  it too was not evaluated as part of this brief.
