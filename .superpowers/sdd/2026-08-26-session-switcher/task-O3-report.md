# Task O3 report — First-run window

## Status: DONE

## Deviation from the brief

The brief pointed to `.superpowers/sdd/2026-08-26-session-switcher/task-O3-brief.md`, which does
not exist in this repo. The actual task content lives inline in
`/Users/sxope/Documents/2026/Development/37.chute/.claude/worktrees/agent-adfa308a6beaa516b/docs/superpowers/plans/2026-08-26-session-switcher.md`
lines 2067-2231 ("Task O3: First-run window"). Used that as the source of truth; the code block
in that section was copied verbatim into `FirstRunWindow.swift` with no changes — it compiled
as written.

## Files touched

- Created: `/Users/sxope/Documents/2026/Development/37.chute/.claude/worktrees/agent-adfa308a6beaa516b/Sources/ChuteApp/FirstRunWindow.swift`
  (verbatim from the plan — no fixes needed, compiled clean).
- Modified: `/Users/sxope/Documents/2026/Development/37.chute/.claude/worktrees/agent-adfa308a6beaa516b/Sources/ChuteApp/main.swift`
  - `applicationDidFinishLaunching`: added `FirstRunWindow.showIfNeeded()` as the last line.
  - `buildMenu()`: added a "Setup Check…" `NSMenuItem` before the Quit item, with `target = self`
    set explicitly (the brief's snippet omitted `target`; every other menu item in this file sets
    it explicitly rather than relying on responder-chain fallback to the app delegate — matched
    that existing convention for consistency/robustness, not a functional necessity).
  - Added `@objc func openSetup() { FirstRunWindow.show() }`.
  - Nothing else in main.swift was changed.

## Verification (actual results)

1. `swift run chutetests` → `✅ 205 assertions passed` (unchanged from baseline; this task adds
   no unit tests, matches instructions).
2. `swift build -c release 2>&1 | tail -3` → `Build complete! (24.96s)`, zero *new* warnings.
   One pre-existing warning remains, unrelated to this task:
   `Sources/ChuteApp/main.swift:109:13: warning: variable 'hotKeyID' was never mutated; consider
   changing to 'let' constant` — confirmed via `git stash` that this warning exists at line 103
   on the pre-task baseline too (just shifted 6 lines down by my additions). It sits inside
   `registerHotKey()`, which this task's scope explicitly excludes ("change nothing else"), so
   it was left untouched and is reported rather than silently fixed.
3. `./Scripts/build-app.sh` → `built dist/Chute.app`, `size: 936K`.

`./Scripts/install.sh` was NOT run and the app was NOT launched, per instructions (another agent
is working concurrently; installing/launching is left to the controller).

## Interfaces consumed (all merged, none redefined)

- `Diagnostics.run(_:)`, `Diagnostics.liveEnv()`, `Check`, `CheckOutcome` from
  `/Users/sxope/Documents/2026/Development/37.chute/.claude/worktrees/agent-adfa308a6beaa516b/Sources/ChuteCore/Diagnostics.swift`
  — confirmed signatures match the brief's usage exactly before writing any code.
- `Shell.run(_:_:)` from
  `/Users/sxope/Documents/2026/Development/37.chute/.claude/worktrees/agent-adfa308a6beaa516b/Sources/ChuteCore/Shell.swift`.

## The three rules, how they're satisfied

1. **No dead ends** — `FirstRunWindow.row(_:)` always appends the `why` label (with `fix` as a
   tooltip) for any failing outcome; no failing row exists without visible reason text.
2. **Fixes re-verify, never repaint** — `Handler.fixAll()` runs `chute doctor --fix`, then on
   completion rebuilds the entire content view via `FirstRunWindow.makeBody()`, which re-calls
   `Diagnostics.run(Diagnostics.liveEnv())` — a fresh probe, not a cached/painted state.
3. **Skip never nags** — `Handler.skip()` calls `FirstRunWindow.markSeen()` (writes
   `~/.chute/state.json`) before closing; `showIfNeeded()` checks that file's existence and no-ops
   if present. The window stays reachable via the "Setup Check…" menu item regardless of skip
   state.

## Files NOT touched

`Sources/chute/` and `Sources/ChuteCore/` — untouched, per instructions.

## Fix round 1 of 5

Coordinator flagged three defects in the plan's own transcribed code, plus a tracking issue.

**FINDING 1 (Critical) — main-thread beachball.** `makeBody()` called
`Diagnostics.run(Diagnostics.liveEnv())` synchronously, and `liveEnv()` shells out to
`osascript`/`pluginkit`/`ps` via blocking `Process.waitUntilExit()`. Every launch froze the UI
before it could draw — indistinguishable from a crash on an `LSUIElement` app with no Dock icon.
Fixed by splitting `makeBody()` into `makeBody(outcomes: [CheckOutcome]?)`: `nil` renders a
"Checking your setup…" placeholder immediately; `show()` now draws that placeholder synchronously
then calls the new `refresh()`, which does the probe on `DispatchQueue.global(qos: .userInitiated)`
and hops back to main only to swap in the real content view. `fixAll()`'s post-fix re-verification
now calls `refresh()` instead of calling `makeBody()` inline on main.

**FINDING 2 (Important) — fix instruction was tooltip-only.** `o.check.fix` was set as
`why.toolTip`, discoverable only by hovering. `row(_:)` now returns a vertical `NSStackView`: the
mark+title row, then the `why` reason line, then a new `→ <fix>` line with `isSelectable = true` so
a command-shaped fix can be copied directly.

**FINDING 3 (Minor) — Skip could nag silently.** `markSeen()` swallowed both `FileManager` calls
with `try?`; if `~/.chute` were unwritable, Skip would appear to work and the window would return
on the next launch with no signal why. Changed to `@discardableResult static func markSeen() -> Bool`
using `do/catch`, logging via `NSLog` on failure and returning `false` — the catch still returns
rather than throwing upward, so launch is never blocked by this.

**Tracking cleanup.** `git rm --cached .superpowers/sdd/2026-08-26-session-switcher/task-O3-report.md`
— the scratch report directory should not be tracked in the repo; the file itself was left on disk.

### Verification (fix round 1, actual results)

1. `swift run chutetests` → `✅ 205 assertions passed` (unchanged).
2. `swift build -c release 2>&1 | tail -3` → `Build complete! (2.08s)`. Warning count unchanged at
   1 — the same pre-existing `Sources/ChuteApp/main.swift:109:13` `hotKeyID` var/let warning from
   before this fix round; no new warnings.
3. `./Scripts/build-app.sh` → `built dist/Chute.app`, `size: 952K` (up from 936K — the extra rows,
   `refresh()`/placeholder logic, and the do/catch in `markSeen()` account for the size increase).
4. Confirmed by reading `Sources/ChuteApp/FirstRunWindow.swift` that the only `Diagnostics.run`
   call site is line 49, inside the `DispatchQueue.global(qos: .userInitiated).async` closure that
   starts at line 48 inside `refresh()`. Every caller of `Diagnostics` reaches it exclusively
   through `refresh()`:
   - Launch path: `showIfNeeded()` (line 11) → `show()` (line ~24, draws the placeholder, then
     calls `refresh()` at the end) → `refresh()` (line 47) → global-queue closure (line 48) →
     `Diagnostics.run` (line 49, off-main) → `DispatchQueue.main.async` (line 50) only swaps the
     content view, no diagnostics work on main.
   - Post-fix path: `Handler.fixAll()` → its own global-queue closure (line 125) runs
     `Shell.run(binary, ["doctor", "--fix"])` off-main → `DispatchQueue.main.async` (line 127) calls
     `FirstRunWindow.refresh()`, which immediately re-dispatches to the global queue (line 48) for
     the fresh `Diagnostics.run` (line 49) — never executed synchronously on main.
   No `Diagnostics` call remains reachable from the main thread in either path.

`./Scripts/install.sh` still NOT run; the app was NOT launched, per instructions.
