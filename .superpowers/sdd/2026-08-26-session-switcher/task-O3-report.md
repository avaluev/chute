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
