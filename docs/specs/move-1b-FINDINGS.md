# FINDINGS — Move 1b: Delete sandbox row

**Date: 2026-08-31**

## What was changed

### Files and line numbers

| File | Change | Lines |
|---|---|---|
| `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift` | Deleted sandbox-here action; added comment | Removed 209-228, replaced with comment at 209-210 |
| `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift` | Updated paid surface test (removed sandbox-here), updated agentSetup children, updated comment | Lines 177-182, 187-189, 196 |
| `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/cases.ts` | Removed `a-clean-room-for-a-risky-agent` case | Removed lines 122-131 |
| `/Users/sxope/Documents/2026/Development/37.chute/marketing/06-FACT-SHEET.md` | Updated Finder actions count 12→11, assertions 992→973, cases 25→23, headline | Lines 30, 61, 67, 96-98 |
| `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md` | Removed sandbox from diagram, table, descriptions; updated totals and CLI reference | Lines 9, 39-42, 57-58, 62-63, 65, 87-91, 118, 250-251 |

## Submenu decision

**"Set Up for an Agent" remains a submenu with 2 children.**

After sandbox deletion, the submenu holds:
- seed-rules (JTBD 7, 9.9 min/day — above the ~10 min/day one-click threshold)
- checkpoint-here (JTBD 12, 3.3 min/day — below, but bundled with seed-rules)

A submenu with 2 children is useful: the user hovers once and chooses between two distinct jobs. This meets the ledger rule: seed-rules is individually worth one click, and checkpoint-here piggybacks as its sibling for the 8-row budget.

Verification of `rows()` mechanics:
- Actions with same `parentTitle` group under one Row
- Submenu holder is created with title=parentTitle and children=[all ids with that parent]
- No inline promotion occurs; submenu remains a single drawn row

Result: 7 rows unchanged (submenu holder stays).

## Totals before and after

### Cases
- **Before:** 24 cases
- **After:** 23 cases
- **Removed:** `a-clean-room-for-a-risky-agent` (JTBD 6, Finder surface, 7.3 min/day savings)

### Finder menu
- **Before:** 12 actions, 7 rows
- **After:** 11 actions, 7 rows (submenu holder unchanged)

### Finder surface min/day (derived from cases.ts)
- **Before:** 41.1 + 28.5 + 12.9 + 9.1 + 9.9 + 7.3 + 4.5 + 6.6 + 3.3 = 123.2 min/day (9 JTBDs)
- **After:** 41.1 + 28.5 + 12.9 + 9.1 + 9.9 + 4.5 + 6.6 + 3.3 = 115.9 min/day (8 JTBDs)
- **Arithmetic verified:** removed 7.3 min/day from JTBD 6

### App surface total (verified via npm run check:cases)
- **120.8 min/day** — includes all paid cases (Finder + menubar surfaces)
- **CLI surface:** 83.5 min/day (free cases)
- **Total ledger:** ~204 min/day across 23 jobs

### Test assertions
- **Before:** 984 unit assertions
- **After:** 973 unit assertions
- **Difference:** –11 assertions
- **Reason:** Fewer tests for row/submenu composition; removed 1 child from agentSetup validation
- **Result:** ✅ 973 assertions passed (swift run -c release chutetests)

### Verification checks
- **Cases check:** ✅ 23 cases verified against ledger
- **Claims check:** ✅ "no page names a retired Finder action" — sandbox-here no longer referenced
- **Command verification:** `swift run chute finder-actions --menu` shows 7 rows

## Spec accuracy notes

- Spec said "with `sandbox-here` gone it holds only `seed-rules`" — this was incomplete. Checkpoint-here also exists in the submenu, bringing total children to 2. Submenu promotion rule does not apply.
- Spec's submenu rule is correct: 1 child = wasted hover, promote it. We have 2 children, so rule does not trigger.
- All new totals derived directly from cases.ts after deletion; no numbers copied from spec.
- Baseline (984 assertions, 24 cases) from previous agent's state verified ✓
