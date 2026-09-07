---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: decision
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:213
---
THE RATCHET — read this before deferring a coverage finding again
`Scripts/check-untested-logic.sh`, wired into `smoke.sh` §26 and therefore into CI.

`chutetests` links ChuteCore only. `Sources/ChuteApp` and `Sources/ChuteFinder` have **zero** unit
coverage. Two audits counted the decision points there and both named `ChuteFinderSync.run` as the
highest-value extraction. **Both times it was ranked and deferred, including by me on
2026-09-01.**

On 2026-09-02 the founder selected 34 items in a Python project, chose **Copy Folder Tree ▸ All
Levels**, and got thirteen `.pyc` files. One line:

```swift
controller.selectedItemURLs()?.first ?? controller.targetedURL()
```

It reads correctly. It is wrong for every multi-selection — `__pycache__` sorts first. 917
assertions and 144 end-to-end checks were green, and not one of them could see that line.

The rule that stops it recurring: **a file in those two targets may shrink freely and may never
grow.** Baseline in `Scripts/untested-logic.txt`, currently **161 across 12 files** (was 172 before
2026-09-04). A red run is
not fixed by re-recording; it is fixed by moving the decision into ChuteCore as a pure function
and testing it — the move `StatusMenu`, `ActionRequest`, `OnboardingSteps`, `ConfirmPrompt` and
`FinderTarget` have all now made. Perturbing the old one-liner back takes ChuteFinderSync 20 → 22
and goes red.

**Both of 2026-09-04's extractions are done** — `SessionMenu` 29 → 19, `ChuteFinderSync` 20 → 19.
**`main.swift` (43) is now the largest remaining by a wide margin**, and it is the next one. Mostly
AppKit wiring, but not all: `runSessionCommand` (`main.swift:280`) decodes a payload and picks what
to put on the clipboard, and the trial/licence branches decide what the menu is allowed to offer.
Take those two; leave the wiring where it is.
