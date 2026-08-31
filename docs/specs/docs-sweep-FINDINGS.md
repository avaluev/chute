# Docs correctness sweep — FINDINGS — 2026-08-31

## Summary
Fixed all stale references to deleted `chute unpack` command and removed "Move Junk to Trash" / `clean-junk` from Finder menu documentation. Updated documentation to reflect the live state as of 2026-08-31.

## Changes by file

### /Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md
1. **Line 8**: "27 commands" → "26 commands" (verified: `.build/release/chute help | grep -cE '^  [a-z]'` = 26)
2. **Lines 27-42 (ASCII menu)**: Removed `Move Junk to Trash…` (● red), added `Add to Context Basket` (● blue)
3. **Line 56 (table)**: Removed row `| Move Junk to Trash… | clean-junk | chute clean <dir> | folder | 13 | 6.6 min | red |`
4. **Line 56 (table)**: Added row `| Add to Context Basket | basket-add | chute basket add <files> | selection | 22 | 8.2 min | blue |`
5. **Line 58 (total)**: "≈ 80.5 min/day" → "≈ 82.1 min/day" (arithmetic: removed 6.6 min, added 8.2 min)
6. **Lines 61-63 (summary)**: Removed text about pre-existing drift from clean-junk
7. **Lines 88-92 (descriptions)**: Removed descriptions for "Move Junk to Trash…" and "Open in Terminal" (deleted actions)
8. **Lines 80-81 (descriptions)**: Added description for "Add to Context Basket"
9. **Line 106 (CLI table)**: "buf add\|list\|flush\|clear | 22 | ❌" → "basket add\|list\|copy\|clear | 22 | ✅"
10. **Line 111 (CLI table)**: "clean [dir] | 13 | ✅" → "clean [dir] | 13 | ❌ | Removed from Finder 2026-08-31."

Verified commands:
- `.build/release/chute basket add <files>` ✓ works
- `.build/release/chute basket copy --format context` ✓ works

### /Users/sxope/Documents/2026/Development/37.chute/README.md
1. **Line 64**: Removed image markdown `![An agent's markdown answer becomes a real file tree](marketing/media/unpack.gif)` and blank lines
2. **Line 78 (was line 78, now 76)**: Replaced `chute unpack` example with:
   ```bash
   chute basket add src/*.ts            # collect files across folders
   chute basket copy --format context   # hand them over to the agent
   ```
3. **Line 92 (was line 92, now 91)**: Removed row `| chute unpack | Fenced code blocks → a real file tree...`
4. **Line 182 (was 182, now 180)**: "**`unpack` and `clean` preview by default.**" → "**`clean` previews by default.**"
5. **Line 183 (was 183, now 181)**: Removed entire line "**`unpack` refuses to escape its target directory**..."

Verified commands:
- All remaining README commands run successfully

### /Users/sxope/Documents/2026/Development/37.chute/site/src/lib/commands.json
1. **Lines 22-25**: Removed entry:
   ```json
   {
     "cmd": "chute unpack",
     "does": "Fenced code blocks → a real file tree. **Previews by default**, writes with --force"
   }
   ```

### /Users/sxope/Documents/2026/Development/37.chute/site/src/app/docs/page.tsx
1. **Line 32**: Replaced `chute unpack` with `chute basket add src/*.ts` and `chute basket copy --format context`

### /Users/sxope/Documents/2026/Development/37.chute/site/src/app/terms/page.tsx
1. **Line 88**: Removed "`unpack`," from the list of destructive operations, updated grammar from "unpack, clean, checkpoint" to "clean and checkpoint"

## Verification
- Build checks pass: `npm run check:claims && npm run check:cases` ✓
- All remaining documented commands verified to run without errors ✓
- JTBD total updated correctly: 80.5 - 6.6 + 8.2 = 82.1 ✓

## Ground truth checks
- `.build/release/chute help | grep -cE '^  [a-z]'` = 26 ✓
- `.build/release/chute finder-actions --menu` shows 11 actions, 6 rows with no clean-junk, includes Add to Context Basket ✓
- `.build/release/chute unpack` = "unknown command 'unpack'" ✓

## Stale references eliminated
- Deleted: `unpack` CLI command references (all 5 files checked)
- Deleted: "Move Junk to Trash" / `clean-junk` Finder row references (capability-map only)
- Deleted: "Open in Terminal" Finder action description (capability-map only)
- Updated: All references to basket/clipboard operations now point to the live `basket` command
