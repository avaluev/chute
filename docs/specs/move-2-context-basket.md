# SPEC — Move 2: Recent Copies becomes the Context Basket

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: ONE agent — the entry type threads through every one of these files.

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/ContextBuffer.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ContextCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Args.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/ContextBufferSuite.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/StatusMenuSuite.swift`

Findings → `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-2-FINDINGS.md`.

## Why — the owner's own words, and what was actually true

He said Recent Copies "doesn't work at all" and "contains a hardcoded shit". Measured: the row IS
there, unlocked, showing four entries **written on 29 Aug and unchanged since**. Two of them
(`Decomposition prompt`, `Anti-bloat prompt`) are CLI commands he never ran — debugging fixtures
from an earlier session.

Root cause: **only 3 of 10 Finder actions ever write to the store**, and the ones he uses daily
write nothing. The list cannot change no matter what he does. From outside, an unchanging list is
indistinguishable from a hardcoded one. He was right about the symptom.

`ContextBuffer.swift`'s own header already says it exists for **JTBD 22 — "the files I need are in
four different folders and the clipboard holds one thing."** That is a BASKET. It shipped as a log
of arbitrary text. This move makes the implementation match the header.

## The one decision everything follows from

**A basket entry is a FILE PATH, not a blob of text.**

Consequences, all simplifications:

| Today | After |
|---|---|
| stores `text` (a copy of the content) | stores a path; content is read at flush |
| `maxEntryBytes = 2MB`, silently dropped | **delete the constant** — a path is 200 bytes |
| row shows `label` → `"1 full path"` | row shows the filename and its parent folder |
| `flushText()` emits `--- context 1 ---` | emits a real `ContextBundle.xml` with a token count |
| every `Out.deliver` auto-files its output | only an explicit add files anything |

That last row is the fix for the fixture junk. `Out.deliver`'s automatic recording
(`Sources/chute/Args.swift:80`) is what filled the list with prompts he never asked to keep.
**Delete the auto-record.** The `record:` parameter added last session then has one caller and
should go with it — check, and delete it too if so.

Deletions are the point of this move. Ship less code than you started with where you can.

## What to build

1. **`ContextBuffer` stores paths.** Keep the storage shape that already works (one JSON file per
   entry under `~/.chute/buffer`, 0700/0600, newest-last ordering, the permission-repair code).
   `Entry` becomes `{ name, path, date }`. `preview` becomes the file's own name plus enough of its
   parent to disambiguate two `index.ts` from different folders — that ambiguity is the whole job.
   **A path that no longer exists must be visible as missing, not silently skipped.** Rule 4 of the
   measurement doctrine: a refusal is not a zero.

2. **`bundleText()` replaces `flushText()`**, and it must produce **exactly** what `chute bundle`
   produces for the same files. There is already ONE definition of that:
   `assembledBundle(_:_:)` in `Sources/chute/Commands/ContextCommands.swift`. If it is not
   reachable from ChuteCore, move it to `ChuteCore/ContextBundle.swift` and have BOTH call sites
   use it — do not copy it. Two definitions of "the bundle" is the exact defect a previous commit
   collapsed out of `doctor --fix`.

3. **The menu, in `StatusMenu.swift` — pure data, as it already is.**
   Rewrite `recentCopies(_:)` as `basket(_:)`:
   - empty → renders nothing (keep that; it is right)
   - non-empty → a section titled `Basket (n)` whose children are the file rows, then a separator,
     then `Copy Basket as Context` and `Empty Basket`
   - **the count must be visible without hovering.** Being a submenu near the bottom of a long menu
     is why the owner reported "no row at all". Put `Basket (n)` where it is read, high in the
     menu, not buried under Local Servers.
   - the `Copy Basket as Context` row carries the token count, via `TokenEstimate.badge` — that is
     the number the job exists to give him.

4. **`ChuteApp/main.swift`** — wire the commands. `bufferCopyOne` becomes "reveal this file in
   Finder" or drop it; `bufferFlush` becomes the bundle copy; `bufferClear` becomes Empty Basket.
   **A click on a row whose entry has been evicted is currently a silent no-op**
   (`main.swift:180`, `guard let entry = ... else { return }`). Say something instead.

5. **`chute buf` → `chute basket`** in `ContextCommands.swift`, subcommands `add|list|copy|clear`.
   Keep `buf` as an undocumented alias exactly as `flush`→`all` was kept, and note in FINDINGS the
   exact `helpText` line the parent must change (you do NOT own `Sources/chute/main.swift`).

## Tests — headless, in the two suites you own

Match the existing `T.suite` / `T.eq` / `T.ok` one-liner style.

- an empty basket renders no section
- three files render `Basket (3)`, one `Copy Basket as Context`, one `Empty Basket`
- **the basket's bundle text is byte-identical to `ContextBundle.xml` over the same three files**
  — this is the DRY assertion, and it is the one that matters
- two files with the same basename from different folders render two distinguishable rows
- a path that has been deleted from disk is shown as missing, not silently dropped
- adding the same path twice leaves one entry (the existing dedupe, now on path)

## Constraints

- Do NOT touch `Sources/ChuteCore/FinderActions.swift` — the parent adds the `Add to Basket` row.
  Report in FINDINGS the exact CLI invocation that row should use.
- Do NOT touch `Sources/chute/main.swift` or `Scripts/smoke.sh` — report needed lines instead.
- KISS: one entry type, one store, no migration path for the old text entries. Four stale fixture
  files in the owner's `~/.chute/buffer` are worth zero; a migration for them is worth less.
  Old-format files must be **ignored without crashing**, and that needs a test.
- DRY: one definition of the bundle. One definition of the store. The menu is a second surface,
  never a second implementation — the file header already says so.

## Verify

```bash
swift build -c release && swift run -c release chutetests
```
Baseline: the parent will give you the real current number at dispatch. Report what you get.

**Perturb before believing.** Restore the 2MB silent `return` and watch the refusal assertion fail;
make `bundleText` emit its own format and watch the byte-identical assertion fail. Record the real
failing counts.

Do NOT run `./Scripts/smoke.sh`. Do NOT commit, add, stash or checkout.
