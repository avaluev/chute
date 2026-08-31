# Capability Map Update Findings — 2026-08-31

## Summary
Removed two Finder rows and their parent: `seed-rules` (JTBD 7) and `checkpoint-here` (JTBD 12). Menu reduced from 6 rows to 5 rows; Finder surface reduced from 7 JTBDs to 5 JTBDs; total time reduced from 89.0 min/day to 75.8 min/day.

## Changes to `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md`

### 1. ASCII menu diagram (lines 27–39)
**Old:** 6 rows, including "Set Up for an Agent ▸" parent with two children (`Add Agent Rules`, `Save a Checkpoint`)  
**New:** 5 rows, removed the entire "Set Up for an Agent" parent and its children  
**Result:** Diagram now shows exactly what `finder-actions --menu` returns: 5 rows, 9 actions

### 2. Row table (lines 41–51)
**Old:** 9 rows (lines 43–51 in old file)  
**New:** 7 rows (removed lines 54–55: `seed-rules` and `checkpoint-here`)  
**Affected JTBDs:** JTBD 7 (9.9 min) and JTBD 12 (3.3 min + ~20 min risk-adj) removed

### 3. Total surfaced through Finder (line 53)
**Old:** "7 of the 22 ledger JTBDs, ≈ 89.0 min/day" + risk-adjusted mention  
**New:** "5 of the 24 ledger JTBDs, ≈ 75.8 min/day"  
**Arithmetic:** 9.1 + 41.1 + 12.9 + 4.5 + 8.2 = 75.8 min (JTBD 1, 2, 3, 5, 22)  
**Delta:** 89.0 − 13.2 (7 + 12) = 75.8 ✓

### 4. Introduction summary (line 9)
**Old:** "11 actions in 6 rows"  
**New:** "9 actions in 5 rows"

### 5. Table B — CLI capabilities (lines 94, 102)
**JTBD 7 (`seed`):** Changed `✅` to `❌`, marked "JTBD 7 removed from Finder 2026-08-31"  
**JTBD 12 (`checkpoint`):** Changed `✅` to `❌`, marked "JTBD 12 removed from Finder 2026-08-31"

### 6. Gap table (lines 128–131)
**Added two rows:**
- ~~**7** Seed agent rule files~~ | `seed` | T1 | 9.9 min | folder — yes | **RETIRED 2026-08-31** — CLI-only now
- ~~**12** Pre-agent checkpoint~~ | `checkpoint` | T1 | 3.3 min | folder — yes | **RETIRED 2026-08-31** — CLI-only now

### 7. Row budget prose (lines 162–165)
**Old:** "Eight rows added to Finder's own already-long menu is the budget, and the six deferred jobs are worth ~23 min/day"  
**New:** "Five rows surfaced through Finder is the budget, and the remaining deferred jobs are worth ~23 min/day"

### 8. Removed prose
Deleted 4 lines describing "Set Up for an Agent ▸ Add Agent Rules" and "Set Up for an Agent ▸ Save a Checkpoint" (old lines 84–88).

## Verification
✅ `cd site && npm run check:claims` — passed (every documented chute command is in dispatch)  
✅ `cd site && npm run check:cases` — passed (19 cases checked, 0 failed)  
✅ `.build/release/chute finder-actions --menu` — confirmed 5 rows, 9 actions  
✅ JTBD totals recalculated and verified against site/src/lib/cases.ts

## File state
- Tree clean, no uncommitted work
- All edits confined to `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md`
- Ready for commit
