# SPEC — Move 3: a stale CLI must be able to say so

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: ONE agent. **You own only the files listed. Do not touch any other file.**

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift`

Findings → `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-3-FINDINGS.md`.

## Why — measured, not assumed

The owner's Homebrew `chute` is **54 commits behind HEAD** and is missing the `onboard` and
`resume` commands entirely. `chute --version` prints `0.2.0`; so does HEAD. Nothing on the machine
could reveal the gap. This is the SAME failure class that produced "Recent Copies never works"
two sessions ago, where the installed .app predated the fix by 55 minutes.

That class was already solved once for the app: `Scripts/build-app.sh` stamps a `ChuteBuild` key
(git short SHA + `-dirty` + UTC minute) into both Info.plists, and `Diagnostics.installedBuild()`
reads it back — `chute doctor` already prints it. **Reuse that. Do not invent a second mechanism.**

## What to do

1. **`chute --version` prints the build stamp.** Today it prints `chute \(ChuteVersion.current)`.
   Make it also print `Diagnostics.installedBuild()` when present, and say plainly when it is
   absent (a binary built outside `build-app.sh`, e.g. `swift build`). Absent must read as absent,
   never as current — that rule is already asserted in `DiagnosticsSuite`.
   Match the wording `chute doctor` already uses so the two agree.

2. **`chute` with no arguments: exit 0, print to stdout.** It currently exits **1** and writes the
   full help to **stderr**. That is wrong for the product's front door — a non-zero exit breaks
   pipes and scripts, and stderr gets swallowed by some wrappers. `chute help` already does the
   right thing; make the no-args path do the same.
   CAREFUL: check `Scripts/smoke.sh` for an assertion about the no-args exit code before you
   change it (grep for `unknown exits non-zero` and similar). If one exists, report it in FINDINGS
   — you do NOT own smoke.sh. An UNKNOWN command must still exit non-zero; only the NO-ARGUMENT
   case changes.

3. **`Scripts/release.sh`** — READ IT FIRST, in full, before editing. Report in FINDINGS what it
   actually does today (does it tag? build? update a Homebrew tap? push?). Then make the smallest
   change that lets the owner cut a release whose installed CLI matches HEAD. If the script already
   does this correctly and the real gap is that it was never RUN, say exactly that and change
   nothing — that is the right answer and it is worth more than an edit.

4. **One test** in `CoreSuites.swift`, matching the existing `T.suite` / `T.eq` one-liner style:
   the version string contains the stamp when one is present, and says "not stamped" when it is
   not. There is already an `installedBuild` test in `DiagnosticsSuite.swift` — read it and do not
   duplicate it; test the version STRING, not the plist reading.

## Constraints

- Do NOT change `Sources/ChuteCore/Version.swift`'s `current` value. `Scripts/build-app.sh` greps
  that literal in an exact shape; changing it breaks the build script.
- Do NOT touch `Scripts/build-app.sh` — the stamping already works and is committed.
- Do NOT tag, push, or publish anything. Report what the owner should run; do not run it.
- Be lazy: reuse `Diagnostics.installedBuild()`. No new files, no new types.

## Verify

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute --version
cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute; echo "no-args exit=$?"
cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute nosuchcommand; echo "unknown exit=$? (MUST be non-zero)"
```
Baseline: **996 unit assertions, 0 failed.** Report the REAL numbers.

Do NOT run `./Scripts/smoke.sh` (another agent is mid-edit). Do NOT commit, add, stash or checkout.
