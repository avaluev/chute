# Architecture

Three build targets, one rule about where decisions are allowed to live, and a script that
enforces the rule instead of a sentence someone has to remember. Read this before you add a
branch anywhere in `Sources/`.

## The three targets, and why the split exists

`Package.swift` declares four things that build, three of them shipping code:

| Target | What it is | Linked by `chutetests`? |
|---|---|---|
| [`ChuteCore`](../Sources/ChuteCore) | Every decision: session state, menu contents, path truncation, project-name derivation, hook parsing, Finder-action dispatch | **Yes** |
| [`ChuteApp`](../Sources/ChuteApp) | The menu-bar app — `NSMenu`/`NSWindow` wiring that turns `ChuteCore`'s output into pixels | **No** |
| [`ChuteFinder`](../Sources/ChuteFinder) | The sandboxed `FIFinderSync` extension | **No** |
| [`chute`](../Sources/chute) | The CLI — a thin `ArgParse` dispatcher over `ChuteCore` | Runs its own logic through `ChuteCore`; the dispatcher itself is a thin switch |
| [`chutetests`](../Sources/chutetests) | The suite — a plain executable with an assert harness, not an `XCTest` target | — |

`chutetests` depends on `ChuteCore` only ([`Package.swift`](../Package.swift)). That one line is
the whole architecture: **anything written directly into `ChuteApp` or `ChuteFinder` cannot be
imported by a test, at all, by construction** — not "low coverage," zero, permanently, no matter
how careful the author is. [`Scripts/check-untested-logic.sh`](SCRIPTS.md#check-untested-logicsh)
counts decision points in those two targets; as of this commit it is 138 across 11 files
(`./Scripts/check-untested-logic.sh`), and that number may fall but never rise without someone
deliberately re-recording the baseline.

`XCTest` ships with Xcode, and this repo builds with the Command Line Tools only — see
[`CONTRIBUTING.md`](../CONTRIBUTING.md). That constraint is *why* `chutetests` is a plain
executable instead of a `.testTarget`, and it is why the ChuteCore/ChuteApp split has to be
enforced by a script rather than by `swift test --enable-code-coverage`: there is no coverage
tool available to measure the gap in the first place.

## The rule this repo learned the hard way

Every decision that has ever lived in `ChuteApp` or `ChuteFinder` instead of `ChuteCore` has
shipped a bug nobody could see until a human looked at a screenshot:

- **The traffic-light dot drew nothing.** The row dot for `blocked` and `waiting` — the two
  states this product exists to surface — painted zero pixels for the product's entire life. The
  drawing code built a "hole" the same size as the outer shape and relied on
  `NSBezierPath.evenOdd` to cancel it into a solid fill; under even-odd winding, the same rectangle
  twice cancels the *shape*, not the hole. `hole: 0` never meant "filled," it meant "draw
  nothing." The code was branch-free, so `check-untested-logic.sh` had nothing to count — it lived
  in `Sources/ChuteApp/`, unreachable by any assertion, and 917 green assertions and 144 green
  end-to-end checks never touched it. It was only caught once `Scripts/screens.sh` rendered the
  menu to a PNG and somebody looked. The fix moved the geometry into
  [`Sources/ChuteCore/SessionDot.swift`](../Sources/ChuteCore/SessionDot.swift), where
  `SessionDotSuite` now renders every state and counts the pixels it actually painted — a dot that
  draws nothing fails the build. Full account:
  [`docs/specs/MENUBAR-DESIGN-BRIEF.md`](specs/MENUBAR-DESIGN-BRIEF.md) §4.
- **The project name could be silently wrong.** Before 2026-09-08, one code path derived a
  session's project name from the hook's `cwd`; a different call site derived it from Terminal's
  window title — a string another process writes and the user can freely rename. The same session
  could read two different names in two different places with nothing in the UI to say so, and
  nothing tested it because the derivation lived where a test could not reach it. The fix is
  [`Sources/ChuteCore/ProjectName.swift`](../Sources/ChuteCore/ProjectName.swift): one derivation
  (git repo root leaf → `cwd` leaf → window-title head → `nil`), forwarded from both call sites,
  covered by `NameDeriveSuite`.

Both bugs shipped past a green suite. Neither could have been caught by writing more tests in the
usual sense — there was nowhere for a test to attach. The fix in both cases was the same move:
**pull the decision into `ChuteCore` as a pure function, and let a test import it.** That move is
now a standing rule, not a one-off refactor:
[`Sources/ChuteCore/StatusMenu.swift`](../Sources/ChuteCore/StatusMenu.swift)'s header names five
prior extractions that made the same trade (`SessionCommand`, `ActionRequest`, `OnboardingSteps`,
`ConfirmPrompt`, `FinderTarget`).

## The ratchet that enforces it

[`Scripts/check-untested-logic.sh`](../Scripts/check-untested-logic.sh) counts decision points
(`if`, `guard`, `switch`, `case`, `for`, `while`, `&&`, `||`, comments stripped first) per file in
`Sources/ChuteApp/*.swift` and `Sources/ChuteFinder/*.swift`, and compares the count against a
committed baseline ([`Scripts/untested-logic.txt`](../Scripts/untested-logic.txt)). A file may
shrink freely. It may never grow, and a new file may not appear, without someone running
`--record` — a visible line in a diff, not a silent tolerance bump. The fix for a red run is never
to raise the number; it is to move the new branch into `ChuteCore` and test it. Full mechanics and
what this specific check cannot catch: [`docs/SCRIPTS.md`](SCRIPTS.md#check-untested-logicsh).

## The menu-open data flow

What happens between a hook writing a JSON record to disk and a session row appearing under the
🪂 icon:

```
agent hook (Claude Code, on Stop/Notification/etc.)
   │  writes ~/.chute/sessions/<key>.json  { state, timestamp, cwd, transcript path, … }
   ▼
HookState.swift            reads and parses the record for a given tty/session key
   │
   ▼
StateResolver.resolve(hook:isAgent:now:staleAfter:)      (Sources/ChuteCore/StateResolver.swift)
   │  a hook younger than 6h wins outright; a hook from the future is untrusted, not "fresh";
   │  no usable hook + a live agent process → .unknown; no hook + no agent → .idle
   ▼
Session (Sources/ChuteCore/Session.swift)   — one of blocked / waiting / working / idle / unknown
   │  ProjectName.of(cwd:windowTitle:) derives the name (git root leaf → cwd leaf → title → nil)
   │  PathAbbrev truncates the path that backs it; SystemVitals measures CPU/memory live
   ▼
StatusMenu.model(...) (Sources/ChuteCore/StatusMenu.swift:149)
   │  pure data: sorts sessions (state → oldest-in-state → project → tty), builds every row,
   │  decides which rows exist at all (Basket only if non-empty, Local Servers always, …) —
   │  nothing here touches AppKit, so StatusMenuSuite can assert all of it headlessly
   ▼
SessionMenu.render(_:into:...) (Sources/ChuteApp/SessionMenu.swift:179)
   │  renders StatusMenu's model to a real NSMenu — attributedTitle, NSTextTab stops at 200pt/
   │  500pt, the SessionDot image per row. Decides nothing; a title, a tab stop, an image, never
   │  a fact. See its own header comment for that division.
   ▼
NSMenu drops down under the 🪂 icon
```

`ServersMenu` (`Sources/ChuteApp/ServersMenu.swift`) is a parallel branch off the same menu-open
event: it re-discovers listening ports live via `lsof` each time the menu opens, rather than
reusing anything from the session pipeline above.

The full row-by-row inventory — every menu item, when it appears, what it shows, what a click
does — is [`docs/specs/MENUBAR-DESIGN-BRIEF.md`](specs/MENUBAR-DESIGN-BRIEF.md), written for a
designer with no codebase access; every claim in it cites the source line it came from.

## The state model, and why `unknown` is a real answer

Five states, ordered by urgency (`Sources/ChuteCore/Session.swift`), which is also the sort order
sessions appear in: **blocked** (a permission prompt — stopped, waiting on a decision only you can
make), **waiting** (agent finished its turn, waiting for your next prompt), **working** (actively
running), **idle** (a plain shell, no agent in it at all), **unknown** (no usable hook data — the
agent ships no hooks, or hasn't reported yet).

`unknown` is not a fallback bucket and must never be folded into `idle` for visual convenience — a
rule stated explicitly in [`docs/specs/MENUBAR-DESIGN-BRIEF.md`](specs/MENUBAR-DESIGN-BRIEF.md) §8
and enforced by construction in `StateResolver.resolve`: the function's only two non-hook outcomes
are `.unknown` (a process that looks like an agent, but says nothing) and `.idle` (no agent
process at all) — there is no third path that guesses. An agent that ships no hooks (Antigravity,
as of this writing) is a genuinely different fact from a plain shell with nothing running, and the
row says so: `idle` and `unknown` deliberately share the same grey ink so neither reads as more or
less alarming by *colour*, and are told apart only by *shape* (`SessionDot.swift`) — a small
filled dot for idle, a ring for unknown. An uninstrumented machine must read as uninstrumented,
never as calm. `Session.project` follows the same discipline: it is `String?`, and `nil` prints
`"no project derived"` rather than a sentinel like `"—"`, because a directory can legitimately be
named `—` and a sentinel would make a real project indistinguishable from no project at all.

This is the same discipline `StateResolver.swift`'s own header names for the bug that motivated
it: on 2026-09-04 the menu bar read `Working (7)` with not one of the seven sessions actually
working, because two proxies (Terminal's `busy` flag, a stale glyph Claude Code writes into window
titles and never clears) were being read as evidence. The fix was not a better guess — it was
removing the guess: a hook, or `.unknown`. A guess dressed as a state is worse than a blank,
because it puts a number on the menu-bar badge, and a badge that cries wolf is a badge people stop
reading.

## Directory map

```
Sources/ChuteCore/     49 files, ~6,500 lines — every decision, linked by all three binaries
Sources/ChuteApp/      10 files, ~1,800 lines — AppKit wiring only, zero test coverage
Sources/ChuteFinder/    1 file,    222 lines — the FIFinderSync extension, zero test coverage
Sources/chute/          2 files + Commands/ — CLI dispatch over ChuteCore
Sources/chutetests/    34 suite files — the assert harness (no XCTest; see CONTRIBUTING.md)
```

Line and decision-point counts drift; re-derive rather than trust the numbers above —
`wc -l Sources/ChuteCore/*.swift` and `./Scripts/check-untested-logic.sh` print the current ones.
