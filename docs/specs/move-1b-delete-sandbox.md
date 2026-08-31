# SPEC — Move 1b: delete the `New Scratch Folder` row

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: ONE agent. **You own only these files.**

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/cases.ts`
- `/Users/sxope/Documents/2026/Development/37.chute/marketing/06-FACT-SHEET.md`
- `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md`

Findings → `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-1b-FINDINGS.md`.

## Why

The owner's instruction, verbatim: **"DELETE this function!"** — about `New Scratch Folder`
(action id `sandbox-here`). It is his call and it is not up for re-litigation.

The reasoning behind it, for the record: Chute's ICP was settled today as **Claude Code / Cursor
users**. Those agents ship their own permission and sandboxing model, so "a fresh folder where the
agent can run wild" solves a problem the ICP's tooling already solves. The row cost 7.3 min/day in
a ledger costed for a different persona.

## What to do

1. **Delete the `sandbox-here` ChuteAction** from `ChuteActions.all` in `FinderActions.swift`.
   Leave a one-line comment saying it was removed on 2026-08-31 on the owner's instruction, and
   that `chute sandbox` still exists. A deletion with no reason gets re-added in six months.

2. **Check whether `Set Up for an Agent` still deserves to be a submenu.** It held two children;
   with `sandbox-here` gone it holds only `seed-rules` ("Add Agent Rules"). **A submenu with one
   child is a hover that buys nothing** — promote `Add Agent Rules` to a top-level row and drop the
   parent. Verify how `ChuteActions.rows()` builds submenu holders from `parentTitle` before you
   change anything, and update the suite's row count and title array to match.

3. **Retire the case** `a-clean-room-for-a-risky-agent` in `site/src/lib/cases.ts`, following
   whatever retirement convention that file uses (the previous agent recorded it in
   `docs/specs/move-1-FINDINGS.md` — read that first).

4. **Re-cost.** Derive every new total yourself from `cases.ts` after the edit; do not copy a
   number from this spec or any doc. Update `marketing/06-FACT-SHEET.md` (the ONE place counts
   live) and the three places in `docs/12-CAPABILITY-MAP.md` (menu diagram, row table, and the
   "Total surfaced through Finder" figure).

## Constraints

- Do NOT touch `Sources/chute/Commands/AgentCommands.swift`. `cmdSandbox` and `launchTerminal`
  stay — the CLI keeps the capability, and `launchTerminal` has other callers.
- Do NOT delete `sandbox` from the CLI dispatch or from `helpText`.
- Another agent owns `Sources/ChuteCore/ContextBuffer.swift`, `StatusMenu.swift`,
  `ChuteApp/main.swift`, `Sources/chute/Args.swift`, `ContextCommands.swift`,
  `ContextBufferSuite.swift` and `StatusMenuSuite.swift` right now. Read anything; edit only yours.
- Be lazy: a deletion, a possible submenu promotion, and number corrections. Nothing else.

## Verify

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```
Baseline: **986 unit assertions, 24 cases, 0 failed.** The unit count will drop again — say what it
went from and to, and why. Do NOT run `./Scripts/smoke.sh`. Do NOT commit, add, stash or checkout.
