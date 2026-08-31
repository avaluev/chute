# SPEC — Move 1: delete the `Open in Terminal` row, and re-cost honestly

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: ONE agent. **You own only the files listed. Do not touch any other file.**

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/cases.ts`
- `/Users/sxope/Documents/2026/Development/37.chute/marketing/06-FACT-SHEET.md`
- `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md`

Findings → `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-1-FINDINGS.md`.

## Why

macOS ships **New Terminal at Folder** and **New Terminal Tab at Folder** in the same right-click
menu, four rows below Chute's `Open in Terminal`. A menu that repeats the OS teaches the reader
that its rows are noise. The owner asked for the row's deletion; it is a decision, not a bug.

The capability is NOT being deleted — `chute open` stays exactly as it is, and so does
`launchTerminal`, which `sandbox` depends on. Only the Finder ROW goes.

## What to do

1. **Delete the `terminal` ChuteAction** from `ChuteActions.all` in `FinderActions.swift`
   (id `"terminal"`, title `"Open in Terminal"`, template `["open", "{dir}"]`).
   Leave a short comment where it was, saying it was removed because macOS ships the same row, and
   that `chute open` still does it. A deletion with no reason gets re-added in six months.

2. **Update `FinderActionsSuite.swift`.** It asserts `rows().count == 8` and the exact title array
   ending in `"Open in Terminal"`. Both become 7 and the shortened array. The existing comment on
   that assertion says "Change this number on purpose or not at all" — you ARE changing it on
   purpose; update the comment to say why 7.
   Check the whole suite for other references to the terminal action (symbol uniqueness, submenu
   parenting, `kind: .open` counts) and fix each.

3. **Retire the case** `open-a-terminal-where-you-are` in `site/src/lib/cases.ts`.
   READ the file's header comments first — there may be a documented convention for retiring a
   case (a flag, a removal, a `retired` list). Follow whatever convention exists. If none exists,
   remove the entry.
   Note `npm run check:claims` asserts "no page names a retired Finder action" — run it.

4. **Re-cost, do not silently drop.** Removing that case changes the site's totals.
   - Compute the new totals yourself from `cases.ts` after the edit. Do NOT copy 211.6 from this
     spec — derive it and report the real number.
   - `marketing/06-FACT-SHEET.md` is the ONE place counts live. If any number there changes,
     change it there. Do not create a second copy anywhere.

5. `docs/12-CAPABILITY-MAP.md` lists the row in a menu diagram and a row table, and states a
   "Total surfaced through Finder" figure. Update all three consistently.

## Constraints

- Do NOT touch `Sources/chute/Commands/AgentCommands.swift` (`cmdOpen`/`launchTerminal` stay).
- Do NOT delete `chute open` from the CLI dispatch or from `helpText`.
- Be lazy: this is a deletion plus number corrections. No refactoring, no new abstractions.

## Verify — run these, read the tally, never trust an exit code

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```
Baseline: **996 unit assertions, 25 cases, 0 failed.** Unit count will DROP slightly (fewer rows
asserted) — that is expected; report the REAL number you get, and say why it moved.

Do NOT run `./Scripts/smoke.sh` (another agent is mid-edit elsewhere). Do NOT commit, add, stash
or checkout. Leave the tree dirty; the parent commits.
