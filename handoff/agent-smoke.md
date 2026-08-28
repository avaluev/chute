# Agent F — smoke coverage for onboard/resume — 2026-08-28

Before: smoke 152 passed/0 failed, headless 128 passed/0 failed.
After:  smoke 157 passed/0 failed, headless 130 passed/0 failed.

Added 3 assertions for `chute onboard` (exit 0, names "Copy Files as Context",
prints "Next:"), gated behind HEADLESS like `doctor` — it calls the same live
Finder osascript probe via `Diagnostics.liveEnv()`.
Added 2 assertions for `chute resume` (fails gracefully with no session,
error names "no session"), run unconditionally — safe headless since Terminal
isn't running there, so `TerminalAppAdapter` never reaches osascript.

Perturbed "and explains why" (resume) to a bogus substring: tally went to
156 passed / 1 failed, confirmed FAIL line, then restored the exact string.

`chute onboard` writes NOTHING to the owner's real state: it only reads
Diagnostics (Finder/pluginkit/ps), and its one write (`endToEndProbe`) is a
temp file in `NSTemporaryDirectory()` removed via `defer`, plus a
save/restore clipboard round-trip. Ran with real HOME. For `resume`, ran with
`HOME="$T"` (isolated) since it reads real `~/.chute/sessions` hook state and
the owner may have a live session right now — isolating HOME guarantees a
deterministic "no session" case without touching or depending on their real
session state.
