# SPEC — Move 5: remove `unpack` entirely — Chute becomes Claude Code native

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: ONE agent.

Findings → `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-5-FINDINGS.md`.

## Why — read this before you touch anything

This deletes the product's **second-largest documented job** (28.5 min/day, JTBD 9). It is not a
mistake and it is not a cleanup. The owner decided it on 2026-08-31 after the ICP was settled as
**Claude Code / Cursor users**.

`unpack` exists for a person whose model cannot write to disk: they get four fenced code blocks in
a browser chat and must hand-create each file. Claude Code writes files itself, so that moment
never occurs for the ICP. The owner's test, applied to four rows this session and failed by all
four: *does this survive a user who has git, an OS with terminal shortcuts, and an agent with
filesystem access?*

Sunk cost is not a reason to keep it — `pathFromBody`, the shebang guard and the `staysInside`
symmetry fix all landed this week. They go too. Say so plainly in FINDINGS; do not hedge.

## What to delete

Work outward from the row so nothing is orphaned:

1. **The Finder row** `unpack-here` in `Sources/ChuteCore/FinderActions.swift`. Leave a one-line
   comment recording the date and the reason. Rows go 6 → 5.
2. **`Sources/ChuteCore/MarkdownUnpack.swift`** — the whole file, if and only if nothing else
   imports it. **GREP FIRST.** `validate` and `staysInside` may have callers you do not expect;
   if any exist outside `unpack`, keep exactly those and delete the rest, and say which in FINDINGS.
3. **`cmdUnpack`** in `Sources/chute/Commands/FileCommands.swift`, its `case "unpack"` in
   `Sources/chute/main.swift`, and its line in the `helpText` literal there.
4. **Tests**: the `MarkdownUnpack` and `MarkdownUnpack.staysInside` suites in
   `Sources/chutetests/CoreSuites.swift`, plus any unpack assertions in
   `Sources/chutetests/FinderActionsSuite.swift`.
5. **`Scripts/smoke.sh`**: every unpack section. Grep for `unpack` and remove each, including the
   dry-run/`--force` pair.
6. **`demo/verify.sh`** and any tape under `demo/` that exercises unpack. Delivery checks will
   drop from 13; report the new number.
7. **The case** `turn-an-answer-back-into-files` in `site/src/lib/cases.ts`, following the
   retirement convention recorded in `docs/specs/move-1-FINDINGS.md` — read that first.
8. **Counts**, re-derived from `cases.ts` after the edit, never copied: `marketing/06-FACT-SHEET.md`
   §Verification (the ONE place counts live) and the three totals in `docs/12-CAPABILITY-MAP.md`
   (menu diagram, row table, "Total surfaced through Finder"). `docs/03-JTBD-LEDGER.md` should
   mark JTBD 9 as retired rather than silently losing a row.

## Constraints

- **You do NOT own these — another agent is editing them right now:**
  `Sources/ChuteCore/ContextBuffer.swift`, `Sources/ChuteCore/StatusMenu.swift`,
  `Sources/ChuteApp/main.swift`, `Sources/chute/Args.swift`,
  `Sources/chute/Commands/ContextCommands.swift`, `Sources/chutetests/ContextBufferSuite.swift`,
  `Sources/chutetests/StatusMenuSuite.swift`.
  If a build error points into one of those, STOP, and report it in FINDINGS instead of editing.
- The destructive-action invariant in `FinderActionsSuite.swift` currently asserts the destructive
  set is exactly `["unpack-here"]`. With unpack gone that set is EMPTY. Do not delete the
  invariant — an empty set is a legitimate state and the rule must keep standing for the next
  action that changes files. Assert emptiness and say why in a comment.
- Do NOT commit, add, stash or checkout. Leave the tree dirty.

## Verify

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```
Baseline: **957 unit · 22 cases · 0 failed.** Every count will drop. Report the REAL numbers and
say what moved and why. Do NOT run `./Scripts/smoke.sh` — another agent is mid-edit; instead
verify your smoke.sh edits with `bash -n Scripts/smoke.sh` and report that the parent must run it.
