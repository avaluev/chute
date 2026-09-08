# Chute menu-bar drop-down — design brief

Handed to a visual designer with no access to the codebase. Everything below is derived from the
actual source that builds this menu today — file paths point at the exact place a claim comes
from, so you can ask an engineer to re-check anything that matters to a decision.

Source files this brief is built from (all under
`/Users/sxope/Documents/2026/Development/37.chute/`):

- `Sources/ChuteCore/StatusMenu.swift` — what is in the menu, in what order (the model)
- `Sources/ChuteApp/SessionMenu.swift` — how that model becomes an `NSMenu` (the renderer)
- `Sources/ChuteCore/MenuBarMark.swift` — the menu-bar icon and its state pip
- `Sources/ChuteCore/Session.swift` — the five session states
- `Sources/ChuteCore/SessionCommands.swift` — the ⌥ alternate commands per session
- `Sources/ChuteApp/ServersMenu.swift` — the Local Servers submenu
- `Sources/ChuteCore/SystemVitals.swift` — the CPU/memory numbers on a row
- `Sources/ChuteCore/SessionPhrasing.swift` — the wording on a row
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

Built in order by `StatusMenu.model(...)` (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift:101`).
Everything below is a row or a group of rows in one flat `NSMenu`; nothing floats free of this
order.

| # | Row / section | Present when | Data shown | Click does |
|---|---|---|---|---|
| 1 | **"Cannot read Terminal — click to fix"** | `problem != nil` — Chute lost the ability to read Terminal.app (e.g. Automation permission revoked) | a tooltip carrying the raw problem string | opens System Settings → Automation (`Command.openAutomationSettings`) |
| 2 | separator | after row 1, only if row 1 is present | — | — |
| 3 | **State section header**, e.g. `NEEDS YOU   2` | once per distinct state present among current sessions, in state order (blocked → waiting → working → idle → unknown) | the state's name + count of sessions in it (`sectionTitle`, line 221) | nothing — disabled row |
| 4 | **Project sub-header**, e.g. `sntz_mockups` | only when ≥2 sessions share *both* the same state *and* the same project (line 165-168) | project name only | nothing — disabled row, indent 1 |
| 5 | **Session row** | one per live terminal session | see §3 below | brings that terminal tab forward (`Command.focusSession`) |
| 6 | **⌥ session-command alternates** (up to 4, stacked on the same row slot) | per session, only for commands that session can actually do — see §2a | title only, no numbers | runs that command (copy to clipboard, or open tmux) — see `SessionCommand.available`, `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/SessionCommands.swift:51` |
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
| 17 | **"Quit Chute"** | always, last row | — | quits the app; targets `NSApp`, not Chute — see note at `StatusMenu.swift:298` |

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

One row's title is built as `prefix + suffix(load)` in `StatusMenu.rows(for:...)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift:235`).
The pieces, and whether each is always present:

| Field | Always present? | Source | Example |
|---|---|---|---|
| Project name | Only when the row is NOT under a project sub-header (i.e. it's the only session for that project in that state) | `Session.project` | `sntz_mockups` |
| Agent label | Present whenever an agent is running; reads `no agent running` for a plain shell | `SessionPhrasing.agentLabel` | `Claude Code`, `Codex`, `Antigravity` |
| Model | Only when the hook's transcript names one (older hooks may not) | `AgentTranscript.displayModel` | `Opus 5`, `Sonnet 5` |
| Effort | Only when it is NOT the default (`"medium"` is never shown — it's furniture) | `AgentTranscript.effort` | `high`, `xhigh` |
| Time-in-state | Only for blocked/waiting/working; **never shown for idle or unknown** — a confident duration next to a state Chute admits it doesn't know is the exact mistake that got the old status badge deleted | `SessionPhrasing.held` | `blocked 22 min`, `ready 3 min`, `working 5 min` |
| CPU % | Present whenever the session has at least one live process; percent of ONE core, so 177% means under two cores pinned | `SessionLoad.label` | `177% CPU` |
| Memory | Same gate as CPU — real resident footprint, summed across the session's whole process tree | `SessionLoad.label` | `3.0 GB memory` |
| Peak-memory note | Only when a process peaked at ≥1.5× its current size AND that peak is ≥512 MB — this is deliberately rare | `SessionLoad.peakNote` | `(peaked 6.1 GB)` |
| "mostly X" | Only when one program holds ≥50% of the session's memory | `SessionLoad.label` | `mostly claude` |
| Runaway warning | Only when CPU ≥250% of one core OR memory ≥8 GB | `StatusMenu.isRunaway` | `⚠` appended after the numbers |

**A full example, real fields, from the founder's own machine on 2026-09-08** (this is the exact
string the task brief was written against):

```
sntz_mockups   Claude Code · Opus 5 · xhigh   blocked 22 min   177% CPU · 3.0 GB memory · mostly claude
```

A quieter row, same shape, fewer fields firing:

```
Claude Code · Sonnet 5   ready 3 min   4% CPU · 210 MB memory
```

A shell with no agent — almost every field drops out:

```
28.tallyapp   no agent running
```

Every segment above is joined with **three literal spaces** (`"   "`), not a tab stop or a
column — see §5 for why that matters.

---

## 4. The state model

Five states, `SessionState` (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Session.swift:8`),
ordered by urgency — this is also the sort order sessions appear in:

| State | What it means | Row dot: colour | Row dot: shape | Icon pip |
|---|---|---|---|---|
| **blocked** | Agent hit a permission prompt — it is stopped, waiting on a decision only you can make | `systemRed` | filled disc, 9pt | filled **square**, red |
| **waiting** | Agent finished its turn and is waiting for your next prompt | `systemGreen` | filled disc, 9pt | filled **circle**, green |
| **working** | Agent is actively running | `systemOrange` | **ring** (34% hole), 9pt | **ring**, orange |
| **idle** | A plain shell — no agent running in it at all | `tertiaryLabelColor` (grey) | small filled disc, 5pt | no pip (quiet mark) |
| **unknown** | Chute has no hook data for this session — the agent ships no hooks (Antigravity today) or the hook hasn't reported yet | `tertiaryLabelColor` (grey) — **same colour as idle** | small **ring** (34% hole), 5pt | no pip (quiet mark) — *verify: see note below* |

Source: `dot(_:)` and its `ink`/`form` tables in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SessionMenu.swift:63-93`;
the icon pip table (`pips`) in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MenuBarMark.swift:103`.

**The two hard rules, both enforced in the row dot today, both must survive redesign:**

1. **Shape carries the meaning; colour is the redundancy, not the other way round.** Roughly 1 in
   12 men in this product's own audience cannot reliably separate the red from the green used
   here. Squint, or view in grayscale, and the three "needs action" states must still read as
   three different things from shape alone: filled-large (blocked) vs. filled-large (waiting) —
   *these two currently share a shape and differ only by colour* — vs. ring (working). **Flag
   this for the designer explicitly: blocked and waiting are both a 9pt filled disc today, red vs.
   green only.** That is the one place the current implementation does not yet honour its own
   rule, and it is worth fixing in any redesign, not just preserving.
2. **Unknown must never look like "all clear."** idle and unknown deliberately share the same
   grey ink so neither reads as more or less alarming than the other by colour — the only thing
   separating "you have a quiet shell" from "Chute has no idea what this session is doing" is
   shape (filled dot vs. ring). An un-instrumented machine — someone who has only ever used
   Antigravity, which ships no hooks — must not have a menu that reads as calm. It should read as
   uninstrumented.

**Worth flagging to the designer as a real gap, not a design opinion:** the menu-bar *icon*
itself only carries a pip for blocked/waiting/working — a positive claim backed by a fresh hook.
When every session is `idle` and when every session is `unknown`, the icon shows the identical
quiet mark in both cases (`MenuBarMark.image`, plain, no pip). So at the icon level — not the
row level inside the dropdown — "nothing needs you" and "I have no idea what any of these are
doing" currently look the same. Rows inside the dropdown do distinguish them (see table above);
the icon does not. Whether that's acceptable or needs its own pip is a real open question — verify
with the founder before assuming either answer.

---

## 5. The current layout, honestly

What renders today is a single flat `NSMenu` — no window, no custom view, just `NSMenuItem` rows
handed to AppKit — built by `SessionMenu.render(_:into:...)`
(`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SessionMenu.swift:119`). In
order, top to bottom:

- UPPERCASE, disabled section headers (`NEEDS YOU   2`) — AppKit's stock disabled-item styling,
  not a real section-header control (`NSMenuItem.sectionHeader` exists since macOS 14 but this
  targets macOS 13, per the comment at `SessionMenu.swift:95`)
- indented, disabled project sub-headers one level in, only when they group ≥2 rows
- session rows: a small coloured dot image, then one long run-on string built by joining fields
  with three literal spaces — project, agent · model · effort, time-in-state, CPU/memory — with no
  column, no tab stop, no distinct visual weight between "what this is" and "what it's costing"
- separators between state groups
- the Basket, Local Servers, and utility rows below, in the fixed order from §2

**Where it fails, plainly:**

- **Run-on rows, no columns.** Three literal spaces under a proportional system font do not align
  into columns across rows of different length — a project name of 6 characters and one of 18
  push everything after it to a different horizontal position on every row. The CPU/memory
  numbers, which are the thing you'd want to visually scan down a list to compare, are ragged.
- **No visual weight hierarchy.** The project name, the state duration, and the CPU/memory
  numbers are all the same font, weight, and colour, differing only in a dot's colour to the left.
  The one thing on the row that actually needs your attention (blocked 22 min) is typographically
  identical to the least important thing on it (mostly claude).
- **Section headers shout.** Uppercase disabled text is the only tool in play for "this is a
  group," reused for both the state header and, one indent in, effectively for the project name
  too — there is no second register between "the loudest text on the menu" and "a plain row."
- **The list can run to 13+ rows** before you reach the Basket / Local Servers / Settings block —
  this is the actual number the founder hit on 2026-09-08 that prompted the state-grouping work in
  the first place (see the long comment at `StatusMenu.swift:130`). Five states × however many
  project sub-groups × however many sessions per group, plus up to 4 hidden ⌥ alternates per
  session that don't add height but do add depth to the ⌥/⌥⇧/⌥⌘/⌥⌃ story nobody currently explains
  anywhere in the menu itself.
- **No affordance at all for the ⌥ alternates**, beyond a tooltip on hover, which is invisible
  until you've already found the row and paused on it.

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
  session. The current implementation only gets two visually distinct registers (uppercase
  header, indented sub-header) to do a three-level job, and the third level (the session row
  itself) has no visual distinction from the sub-header above it beyond a dot and one more indent
  step.
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
  - `indentationLevel` — integer steps, used today for the two-level header/row structure.
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

## 9. Three worked layout directions

None of these is the recommendation — they're starting points for a conversation between the
founder and the designer. Widths below are the ~360pt reference width; ASCII columns are
illustrative, not exact character counts.

### Direction A — "Fix the columns, keep the structure"

Keep today's flat-list, two-level structure (state header → session rows, project sub-headers only
when they group something) exactly as is, and fix only the typography: real tab stops via
`attributedTitle` so CPU/memory numbers land in a fixed right-hand column regardless of project
name length, and a weight/colour step between "what needs your attention" (duration) and "cost"
(CPU/memory) — duration in the label colour, CPU/memory in `tertiaryLabelColor`.

```
 NEEDS YOU                                                    2
 ● sntz_mockups  Claude Code · Opus 5 · xhigh   blocked 22 min
                                     177% CPU · 3.0 GB · mostly claude ⚠
 ● 28.tallyapp   Codex · high                     blocked 4 min
                                                    12% CPU · 640 MB
 ──────────────────────────────────────────────────────────────
 READY FOR A PROMPT                                            1
 ○ 37.chute      Claude Code · Sonnet 5             ready 3 min
                                                     4% CPU · 210 MB
 ──────────────────────────────────────────────────────────────
 WORKING                                                        3
   sntz_mockups
 ◐  Claude Code · Opus 5              working 1 min · 40% · 1.1 GB
 ◐  Claude Code                       working 8 min · 88% · 2.4 GB
   28.tallyapp
 ◐  Codex · high                      working 12 min · 5% · 300 MB
```

**Cost:** none beyond §7's "available today" lever. Same `NSMenuItem` rows, same accessibility
behaviour, same testability — `attributedTitle` is a value the model layer can still hand the
renderer as plain strings plus formatting rules the renderer applies mechanically. This is the
cheapest direction and the lowest-risk one to ship.

### Direction B — "Collapse to the state, expand on demand"

Show only state headers and a one-line-per-state rollup by default (`NEEDS YOU — sntz_mockups,
28.tallyapp`), each opening a submenu of that state's full session rows rather than listing every
session flat in the top-level menu. Nothing needing you is ever more than one click deep; sessions
you don't currently need to think about (idle, working-and-fine) stay collapsed by default.

```
 ▸ NEEDS YOU (2)            sntz_mockups, 28.tallyapp
 ▸ READY FOR A PROMPT (1)   37.chute
 ▸ WORKING (3)              sntz_mockups (×2), 28.tallyapp
 ▸ NO AGENT (4)
 ▸ NO STATUS — HOOKS NOT REPORTING (1)
 ──────────────────────────────────────
 Basket (3)
 Local Servers (2)
```

**Cost:** still all standard `NSMenuItem` + submenu — no `NSMenuItem.view` needed. The real cost
is behavioural, not visual: this trades "one glance sees everything" for "one glance sees counts,
one click sees detail," which is a genuine product decision (does the founder want to see the
CPU/memory numbers without opening a submenu, e.g. to catch a runaway session at a glance?) — not
just a layout question. Also loses the "blocked sits at the top, unmissable" property that ordering
by state currently gives for free, unless NEEDS YOU is always pre-expanded.

### Direction C — "Custom row, real hierarchy"

A genuinely two-line, two-weight row per session via `NSMenuItem.view`: a bold line for state +
duration + project, a lighter second line for agent/model/CPU/memory, with the state dot as a
real inline glyph rather than a menu-item image, and a proper distinct visual treatment for
project sub-headers vs. state headers (e.g. a filled rounded chip for state, small-caps grey text
for project).

```
┌──────────────────────────────────────────────┐
│ ● sntz_mockups                  blocked 22 min│
│   Claude Code · Opus 5 · xhigh                │
│   177% CPU · 3.0 GB memory · mostly claude  ⚠ │
├──────────────────────────────────────────────┤
│ ○ 37.chute                        ready 3 min │
│   Claude Code · Sonnet 5 · 4% CPU · 210 MB    │
└──────────────────────────────────────────────┘
```

**Cost:** the most expensive direction by far. Needs `NSMenuItem.view` per session row (§7) —
VoiceOver labels, keyboard highlight state, and Increase Contrast/Reduce Transparency response all
become code this project has to write and maintain by hand instead of getting from AppKit for
free, and that code lands in exactly the target (`ChuteApp`) the test suite cannot link, against
an untested-decision-point budget that is currently near zero for new branches. This direction
should not be picked without the founder explicitly accepting that trade — it is real ongoing
engineering cost, not a one-time design cost.
