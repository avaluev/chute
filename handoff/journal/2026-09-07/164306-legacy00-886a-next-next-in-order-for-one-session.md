---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: next
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:191
---
NEXT — in order, for one session
1. **The three founder items below.** Nothing in the repo is blocked on anything but those.
2. ~~One error-handling pass~~ — **done 2026-09-03**. Three LOWs left open in the findings file
   (M18, L12, L13) with reasons; P10 (`--naming`) was decided, not deferred.
3. ~~The next two ratchet extractions~~ — **done 2026-09-04**, 172 → 161. Continue with
   `main.swift`'s two real decisions; see THE RATCHET.
4. **Then the texts and the JTBDs.** Re-read every user-facing string against the naming law at
   `Sources/ChuteCore/FinderActions.swift:10` — including the four sentences that moved into
   ChuteCore on 2026-09-04, which are now the only copy of themselves. Retire the ledger rows for
   the six deleted jobs properly (struck through + dated, the way FR-06 was).
5. **Re-run the FULL smoke on a quiet machine** before the next release — this session ran the
   headless 150 only, deliberately.

**Then, and only then, custom user actions.** `ChuteAction` is pure data and `argv()` already
substitutes `{files}`/`{dir}`, so reading `~/.chute/actions.json` is ~40 lines. But it turns an
opinionated 5-row menu into a platform, macOS already ships Automator Quick Actions and Shortcuts
for exactly this, and it means Chute executes commands the user wrote. **Design it before
building it.**

---
