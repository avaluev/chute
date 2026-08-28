# FINDINGS — Move 0+2: honest signals

Repo: `/Users/sxope/Documents/2026/Development/37.chute`. Tree left dirty; nothing committed,
staged, stashed, or checked out — per instructions.

## What changed, by file

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Diagnostics.swift`
- `:5-9` — `public enum Severity: Sendable, Equatable { case blocker, note }`.
- `:21,23` — `Check` gained `let severity: Severity`, defaulting to `.blocker` in `init`.
- `:84` `cli`, `:99` `terminal` — marked `severity: .note`.
- `:100-110` — new `hooks` check (id `"hooks"`, `severity: .note`), replacing the old "deliberately
  no hooks check" comment block. Fix text is the spec's near-verbatim line, backticks dropped
  since no other check's fix string uses markdown and this text renders literally in
  `FirstRunWindow`.
- `:55,59,65` — `DiagnosticsEnv` gained `var hooksWired: Bool` (default `false`, matching "most
  machines never ran `chute hooks snippet`").
- `:164` — `run(_:)` adds the `hooks` outcome: `env.hooksWired`, detail `"wired"` /
  `"not wired — badge stays dark"`.
- `:233,238-240` — `liveEnv()` computes `hooksWired` from
  `HookInstaller.status(settingsPath: claudeSettingsPath).values.allSatisfy { $0 }` — **read-only**,
  same call `chute hooks status` already makes. "Wired" means all four events present; a partially
  wired setup still reads as unwired, which matches "the badge will stay dark" (a badge fed by only
  some of the four events is not a working badge). `claudeSettingsPath` reuses the same
  `~/.claude/settings.json` expression `SessionCommands.swift:177` already uses.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/DoctorCommand.swift`
- `:119-121` — the one exit-code change. `blockerFailures = failures.filter { severity == .blocker }`;
  `exit(0)` when that's empty, else the existing `os`-fails-with-2 logic, now keyed off
  `blockerFailures` instead of `failures`. Nothing else in this file touched. `repair(_:dryRun:)`
  already had no case for `"hooks"` — its `default:` branch already carried a comment anticipating
  it ("hooks deliberately has none either") — so Part 2's "no automatic fix" requirement needed zero
  changes there.
- **Side effect found, not caused by me**: `blocked` (`:65-67`, unedited) is
  `prerequisites.contains { !$0.passed }`, and `hooks` is a prerequisite. So a failing `hooks` note
  still trips the existing "skip end-to-end, print `— end-to-end test skipped`" path and the
  printed summary becomes `"→ 1 of 9 checks failed"` instead of `"→ all 10 checks passed"` on any
  machine without hooks wired — most of them. The spec scoped me to "the one exit-code change";
  extending `blocked` past prerequisite-severity would be a second change to a file I was told to
  touch minimally, so I left it. Exit code is unaffected (verified below) — only the printed
  summary line and whether end-to-end runs change. Flagging for the parent to decide if `blocked`
  should also become blocker-only.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift`
- `:43-44` — `Command` gained `.openSetup`, `.copyHooksSnippet`.
- `:108,148-159` — `model(...)` gained `hasHookRecords: Bool = true`. When `!hasHookRecords &&
  !sessions.isEmpty`, emits one row: `"Agent status needs a hook — Copy the Snippet"`,
  `.command(.copyHooksSnippet)`, `payload: HookInstaller.manualSnippet()`. Placed right after the
  `problem` row, before session grouping.
- `:230-238` — `standardItems`: when `!unlocked`, emits one `.note` row, `"Local Servers and Recent
  Copies are behind the licence"`, in place of the `.servers` node and `recentCopies(...)`. The gate
  itself (`if unlocked {...} else {...}`) is unchanged in shape — nothing new is unlocked.
- `:249` — `"Setup…"` row, `.command(.openSetup)`, added to `standardItems` (so it survives an
  expired trial like Settings/Report a Problem/Quit already do).

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/FirstRunWindow.swift`
- `:22-30` (`showIfNeeded`) — opens only when `failing.contains(where: { severity == .blocker })`.
- `:96-131` (`makeBody`) — **decision, per spec's "your call, justify it": notes do NOT render in
  this window**, blockers only, both for the count in the title and for the rows drawn. Reason:
  `cli`/`terminal`'s own fix text ("Informational only — nothing is broken") reads as an
  instruction next to blocker rows captioned "needs your permission" — rendering it here just moves
  the exact false alarm this spec exists to kill from the title into the body. `chute doctor`
  already prints a failing note; a second surface for the same fact, worded as a permission
  problem, adds confusion without adding information.
- Also in `makeBody`: added an empty-failures branch (`"Chute is set up correctly"`, one "Close"
  button, no "Fix It"). **Not explicitly asked for by the spec**, but load-bearing: Part 3.2 wires
  the previously-dead `openSetup()` into a real menu row, and Part 1 makes the window open-only-on-
  blocker. Together, a user with a fully clean install who clicks the new "Setup…" row now reaches
  `makeBody` with zero blocker failures — without this branch the title would have read `"0 things
  need your permission"`. Verified this path compiles and is exercised by the manual `chute doctor`
  runs below (same filter logic, `Diagnostics.run` on a healthy env).

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/Onboarding.swift`
- `:33-45` — `showIfFirstRun()` no longer writes `"onboarded"`; added `static var hasOnboarded: Bool`
  so `main.swift` reads the same flag through one name instead of a second string literal.
- `:150-156` (`Handler.next()`) — the write moved into the `index >= steps.count - 1` (Finish)
  branch, unconditional on any step's `done` state, so Skip-to-Finish still counts.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift`
- `:45-53` — `applicationDidFinishLaunching`: `Onboard.hasOnboarded ? FirstRunWindow.showIfNeeded()
  : Onboard.showIfFirstRun()` — one or the other, never both.
- `:117` — `populateBody` passes `hasHookRecords: !HookState.readAll().isEmpty` into
  `StatusMenu.model`. A second, cheap `HookState.readAll()` call (the first is inside
  `discoverSessionsForMenu()`); not threaded through to avoid changing that method's signature for
  one extra read of a small directory.
- `:154-155` — `selector(for:)` gained `.openSetup → #selector(openSetup)` and `.copyHooksSnippet →
  #selector(copyHooksSnippet(_:))`. The switch is exhaustive by design (existing comment at `:142`);
  this is what made both new cases fail to compile until wired, which is the guard working.
- `:206` — `openSetup()` was already there (dead code the spec named); only the selector wiring
  was missing, now fixed.
- `:211-215` — new `copyHooksSnippet(_:)`, reads `representedObject as? String`, calls the existing
  `deliver(_:_:label:)`.

### Tests — `DiagnosticsSuite.swift` / `StatusMenuSuite.swift`
- `DiagnosticsSuite.swift:16` — count 9→10, comment rewritten to explain hooks is present,
  read-only, `.note`.
- `:25` — `good` env gained `hooksWired: true` so "a healthy environment passes them all" still
  means all ten.
- `:50-73` — replaced the old "there is no hooks check" assertion with: `cli`/`terminal`/`hooks`
  are all `.note` (loop); exactly 3 notes / (count-3) blockers; unwired hooks fails with detail
  containing "badge stays dark" and fails exactly one check; wired hooks passes.
- `StatusMenuSuite.swift:47` — `"Setup…"` added to the expired-trial escape list.
- `:55-61` — expired trial shows `"behind the licence"`; a licensed one never does.
- `:206-219` — new section: `hasHookRecords: false` + live sessions → the row appears, with the
  right `.command(.copyHooksSnippet)` kind and `payload == HookInstaller.manualSnippet()`; default
  (hooks presumed wired) shows nothing; empty sessions + no hook records also shows nothing (zero
  CURRENT vs. zero EVER, kept distinct).

## RED perturbations (all reverted before the final run)

1. **Exit-code guard.** This machine's hooks are actually wired (`chute doctor` shows `hooks: wired`
   normally — the "unwired here" assumption in the dispatch note didn't hold today). Forced
   `hooksWired: false` at `Diagnostics.swift:233` and rebuilt:
   ```
   → 1 of 9 checks failed
   ✗ Agent status hooks   not wired — badge stays dark
   — end-to-end test skipped: fix the above first
   exit=0
   ```
   Confirms the load-bearing claim: a failing `.note` prints and does not flip the exit code.
   Reverted, rebuilt, confirmed `chute doctor` returns to `→ all 10 checks passed`, `exit=0`.

2. **Severity default.** Removed `severity: .note` from the `cli` check (back to default
   `.blocker`) at `Diagnostics.swift:84`, rebuilt `chutetests`:
   ```
   ❌ 2 failed, 989 passed
     • Diagnostics › 'cli' is informational, not a blocker (line 56)
     • Diagnostics › every other check is still a blocker by default (line 59)
   ```
   Reverted, rebuilt, back to `✅ 991 assertions passed`.

3. **Deleted menu row.** Removed the `"Setup…"` line at `StatusMenu.swift:249`, rebuilt:
   ```
   ❌ 1 failed, 990 passed
     • StatusMenu › an expired trial still offers Setup… (line 48)
   ```
   Reverted, rebuilt, back to `✅ 991 assertions passed`.

## Final tallies (real numbers, this machine, after every revert)

```
swift build -c release && swift run -c release chutetests   → ✅ 991 assertions passed (baseline 971, 0 failed)
./Scripts/smoke.sh                                            → smoke: 173 passed, 0 failed (baseline 173)
CHUTE_HEADLESS=1 ./Scripts/smoke.sh                            → smoke: 145 passed, 0 failed (baseline 145)
.build/release/chute doctor; echo exit=$?                     → all 10 checks passed, exit=0
```
`git status --short` shows exactly the 8 owned files modified plus the untracked `docs/specs/` —
nothing else touched, nothing staged.

## smoke.sh — nothing for the parent to change

Grepped `Scripts/smoke.sh` for a hardcoded "all 9 checks passed" — it isn't there. Its only doctor
assertions are: `--json` shape (`id`+`passed` per row, unaffected by the count), and
`has "doctor names a fix" ... "checks"` (a bare substring match against the word "checks", which
both `"→ all N checks passed"` and `"→ N of M checks failed"` satisfy). Neither depends on the
count being 9 or on the exit code — `set -uo pipefail` with no `-e`, and every `doctor` call runs
inside `$(...)` consumed by `has`/`hasnt`, so a non-zero exit from `doctor` itself was never load-
bearing for smoke.sh either. Confirmed empirically: `./Scripts/smoke.sh` is 173/173 clean both
before and after this change.

One thing NOT in the three required gates: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/preflight-recording.sh:39` does match on `*"all"*"checks passed"*`. On a machine
where hooks aren't wired that pattern will now legitimately fail to match (the line becomes `"→ N
of 9 checks failed"`), same as the `blocked`/skip side effect noted above. I do not own this script
and it isn't part of the three verify commands, so I left it — flagging in case the parent wants it
updated to also accept `"of"*"checks failed"`.

## Where the spec's assumptions didn't hold

- **Baselines.** Spec said 962 unit / 158 smoke / 130 headless; actual dispatch-time baseline was
  971/173/145 (given at dispatch, confirmed real). Final: 991/173/145 — unit assertions grew by 20
  (new severity/hooks/menu-row coverage), smoke and headless counts unchanged (no smoke.sh line
  needed editing, see above).
- **DoctorCommand.swift.** Spec described `applyFixes` as a second switch to avoid duplicating;
  by dispatch time it was already collapsed into the single `repair(_:dryRun:)` the current-state
  note described, and its `default:` branch already had a comment anticipating the `hooks` check.
  So Part 2's "applyFixes must have NO case for it" was already true before I touched the file —
  nothing to add there.
- **This machine's hooks state.** The dispatch note said "hooks are unwired here"; by the time I
  ran `chute doctor` they were wired (`~/.claude/settings.json` already carries all four events).
  Verified the exit-code claim by perturbation instead of by natural machine state (see above).
- Everything else in the spec — file list, line numbers for the root-cause citations, the
  `HookInstaller.status`/`manualSnippet()` API shapes, `OnboardStep`/`Onboarding.steps` structure —
  matched the tree exactly.
