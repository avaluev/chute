# FINDINGS — Move 1: Delete terminal row

**Date: 2026-08-31**

## What was changed

### Files and line numbers

| File | Change | Lines |
|---|---|---|
| `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift` | Deleted terminal action; added comment | Removed 262-268, replaced with comment at 262-263 |
| `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift` | Updated row count from 8→7, updated title array, updated comment, fixed `.open` kind check | Lines 72-82, 142-144 |
| `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/cases.ts` | Removed `open-a-terminal-where-you-are` case | Removed 152-160 |
| `/Users/sxope/Documents/2026/Development/37.chute/marketing/06-FACT-SHEET.md` | Updated Finder actions count 13→12, rows 8→7 | Line 30 |
| `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md` | Removed terminal from diagram and table; updated totals | Lines 44, 62, 64, 68-69 |

## Totals before and after

### Cases
- **Before:** 25 cases
- **After:** 24 cases
- **Removed:** `open-a-terminal-where-you-are` (JTBD 8, Finder surface, 5.9 min/day savings)

### Finder menu
- **Before:** 14 actions, 8 rows, 10 ledger JTBDs, ≈129 min/day
- **After:** 13 actions, 7 rows, 9 ledger JTBDs, ≈123 min/day
- **Arithmetic:** 41.1 + 28.5 + 12.9 + 9.1 + 9.9 + 7.3 + 4.5 + 6.6 + 3.3 = 123.2 min/day
  (Copy Paths + Unpack + New File + Paths + Seed + Sandbox + Tree + Clean + Checkpoint)

### Test assertions
- **Before:** 996 unit assertions
- **After:** 984 unit assertions
- **Difference:** –12 assertions (fewer row assertions expected)
- **Result:** ✅ 984 assertions passed

### Cases and claims verification
- **Cases check:** 24 cases verified against ledger ✅
- **Claims check:** "no page names a retired Finder action" ✅

## Convention for retiring cases

**Convention found:** None documented. The file header (lines 1-19) explains the data structure but contains no convention for retiring cases. Following the spec instruction "If none exists, remove the entry," the terminal case was removed entirely from the `CASES` array rather than marked or moved to a separate list.

## Terminal row references found

Searched for all references to the terminal action across the five files:

| File | Reference | Status |
|---|---|---|
| FinderActions.swift | id: "terminal" | ✅ Deleted |
| FinderActions.swift | title: "Open in Terminal" | ✅ Deleted |
| FinderActions.swift | kind: .open | ✅ Deleted |
| FinderActionsSuite.swift | Title array entry "Open in Terminal" | ✅ Updated |
| FinderActionsSuite.swift | `kind: .open` class used check | ✅ Updated (now checks `.destructive` instead) |
| cases.ts | slug: "open-a-terminal-where-you-are" | ✅ Removed |
| CAPABILITY-MAP.md | Row in diagram "Open in Terminal ● indigo" | ✅ Removed |
| CAPABILITY-MAP.md | Table row with JTBD 8, 5.9 min | ✅ Removed |
| CAPABILITY-MAP.md | "10 of the 24" / "≈ 129 min/day" | ✅ Updated to 9 of 24 / ≈ 123 min/day |
| FACT-SHEET.md | "13 actions, 8 rows" | ✅ Updated to 12 actions, 7 rows |

All references purged. The CLI `chute open` and `launchTerminal` function (used by `sandbox`) were **not** modified as per spec constraint.

## Spec accuracy notes

- Spec says to derive totals "yourself from `cases.ts`" — correctly done by summing `savedMinutes` of all remaining Finder-surface cases
- Spec says baseline is "996 unit assertions, 25 cases" — spec baseline matches pre-change state ✓
- Unit count drop explanation: Previously asserted 8 rows and their titles; now asserts 7 rows and their (shorter) title array
