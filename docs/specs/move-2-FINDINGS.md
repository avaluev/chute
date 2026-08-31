# FINDINGS — Move 2: Context Basket

Spec: `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-2-context-basket.md`
(read in full, including THE ICP DECISION, before implementing).

## What changed, file:line

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/ContextBuffer.swift` (rewritten, 155 → 135 lines)
- `Entry` is now `{ name, path, date }` — `text`/`label` gone. `:21`
- `Entry.preview` (`:29`) — filename + immediate parent, e.g. `auth/index.ts`; appends
  `" — missing"` when `FileManager.fileExists` says the path is gone. Never filters — Rule 4.
- `maxEntryBytes` deleted entirely (was `:41` in the old file). No replacement — a path needs no
  size guard.
- `entries()` (`:54`) — same JSON-per-file store, same 0700/0600, same newest-last ordering.
  Old-format files (`{ts,label,text}`, no `"path"` key) fail the `guard` and are skipped, not
  crashed on — this is the ignore-without-crashing behaviour the spec asked for, achieved for
  free by the shape change rather than by an explicit version check.
- `record(text:label:)` → `add(_ path: String)` (`:74`). Dedup now on `path`, not `text`.
- `flushText()` → two functions:
  - `mentionText()` (`:107`) — `PathFormat.render(paths, style: .at, separator: .space)`. Reused
    verbatim, not reimplemented.
  - `bundleText()` (`:116`) — `ContextBundle.assemble(paths).text`.
- `extension ContextBundle { static func assemble(...) }` (`:127`) — **see "The ownership
  conflict I hit" below** for why this lives here instead of moving into `ContextBundle.swift`.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/StatusMenu.swift`
- `Command` enum: `bufferCopyOne` → `bufferReveal`; added `bufferMentions`. `:46-49`
- `model(...)` gained `recentTokens: Int = 0` (`:108`) — the token count for "Copy Basket as
  Context" needs a disk read (`ContextBundle.assemble` reads file contents), so the caller reads
  once and hands in a number, the same way `hasHookRecords` hands in a fact instead of this file
  reading `~/.chute/sessions` itself. Kept the file's "pure data" guarantee intact.
- `standardItems(...)` (`:235`) — **Basket is now emitted before `Local Servers`** (`:244`),
  not after. Old position was why "no row at all" was reported: the submenu parent's title was
  always visible without hovering (same as today), the actual problem was that it sat far enough
  down a long menu to be scrolled past.
- `recentCopies(_:)` → `basket(_:tokens:)` (`:290`). Children: file rows (payload = `path`, click
  reveals in Finder) → separator → `Copy Basket as @mentions` → `Copy Basket as Context (~Nk
  tokens)` → `Empty Basket`. Still a `.submenu` — the spec's own wording ("whose **children** are
  the file rows") maps to the existing `Kind.submenu([MenuNode])` case, not to `.header`.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift`
- `populateBody` (`:114-124`) reads `ContextBuffer()` once, computes `basketTokens` only when
  `basketEntries` is non-empty (skips the disk read otherwise), passes both into `StatusMenu.model`.
- `bufferReveal(_:)` (`:194`) replaces `bufferCopyOne` — reveals the file in Finder
  (`NSWorkspace.selectFile`). Two guards, each says something instead of the old silent no-op at
  the file's old `:180`: entry evicted from the store since the menu drew → "That file is no
  longer in the basket"; entry still tracked but the file itself is gone from disk → "That file
  no longer exists on disk".
- `bufferMentions()` (`:210`) — new, copies `mentionText()`.
- `bufferFlush()` (`:219`) — copies `bundleText()` instead of the old string-join; **no longer
  clears the basket after copying** (see "Decisions" below).
- `bufferClear()` (`:227`) — same body, message now "Basket emptied".
- `deliver(_:_:)` (`:307`) — dropped the `label:` parameter and the `ContextBuffer().record(...)`
  call. Every call site in this file (session-command clipboard copies, the hooks snippet) updated
  to 2-arg calls. These were never file paths, so under the new "a basket entry is a path" rule
  there was nothing left for this to hand the basket anyway.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ContextCommands.swift`
- `assembledBundle(_:_:)` (`:20`) is now a **2-line wrapper** over `ContextBundle.assemble`,
  picking the format out of `Args`. `cmdBundle`/`cmdTokens` call sites unchanged.
- `cmdBasket(_ a: Args)` (`:110`) replaces the body of the old `cmdBuf`. Subcommands `add` (`:116`,
  needs `a.paths(dropping: 1)` — see Args.swift below), `list` (`:121`), `copy` (`:128`, `--format
  mentions|context`, default `mentions`), `clear` (`:140`).
- `cmdBuf(_ a: Args) { cmdBasket(a) }` (`:151`) — the one-line alias the spec asked to keep, and
  the reason `Sources/chute/main.swift`'s existing `case "buf": cmdBuf(args)` still compiles
  untouched.
- Dropped: the `--keep` flag (no callers left — see "no auto-clear" decision below) and the
  `record: false` argument to `Out.deliver` (the parameter it fed no longer exists).

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Args.swift`
- `Out.deliver` (`:87`) — deleted the `record` parameter and the auto-record call entirely. This
  is the actual fix for the "hardcoded" complaint: it was `Out.deliver` that filed a copy of
  every command's stdout into the old store, not something specific to `buf`.
  `label` stays in the signature — see "The ownership conflict I hit", item 2.
- `Args.paths(dropping:defaultToCWD:)` (`:50`) — added `dropping: Int = 0`, one new parameter on
  an existing method, so `basket add`'s path parsing reuses the same `--files-from` support as
  `paths`/`bundle`/`tree` instead of a second hand-rolled path parser.

### `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/ContextBufferSuite.swift` and `StatusMenuSuite.swift`
Rewritten for the new shape. Every bullet in the spec's "Tests" section is covered; see the
perturbation section below for proof they actually catch regressions, not just pass.

## The ownership conflict I hit

Two places where the spec's literal instructions collide with "you own exactly these seven
files," resolved in favour of the file list (it says explicitly it's the constraint agents break):

1. **`ContextBundle.swift` is not one of the seven.** The spec says "if `assembledBundle` is not
   reachable from ChuteCore, move it to `ChuteCore/ContextBundle.swift`." It already *was*
   reachable — `ContextBundle.xml`/`.markdown` are already public in ChuteCore — so no move was
   needed. What I actually needed was the small glue (`FileScan.bundleFiles` + `ProjectRoot.of` +
   pick a format) that `assembledBundle` already had, made callable from `ContextBuffer.swift`
   too. I declared it as `extension ContextBundle { static func assemble(...) } ` **inside**
   `ContextBuffer.swift` — Swift extensions can live in a different file than the type they
   extend within the same module, so this reuses the type without a byte of `ContextBundle.swift`
   changing. Confirmed with `git diff` on that file: empty.

2. **Four call sites outside the seven files call the old `ContextBuffer` API directly** — not
   through `Out.deliver`, so deleting `Out.deliver`'s auto-record did not fix them:
   - `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:130`
     — `ContextBuffer().record(patch, label: "Diff · what the agent changed")` inside `cmdDiff`.
     `patch` is a git diff's text, not a path.
   - `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:197`
     — `ContextBuffer().record(url, label: "Secret gist URL")` inside `cmdGist`. `url` is a gist
     URL, not a path.
   - `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ImageCommands.swift:32`
     — `ContextBuffer().record(path, label: "Image · ...")` inside `cmdPasteImage`. `path` here
     genuinely *is* a file path (the just-saved PNG).
   - `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ImageCommands.swift:76-77`
     — inside `watchForRename`, `buf.entries().filter { $0.text == path }...` then
     `buf.record(current, label: ...)`. `current`/`path` are also file paths.

   `record`/`Entry.text` no longer exist, so these four lines fail to compile
   (`swift build -c release` output captured below). I did not edit either file — outside the
   seven. Exact one-line fixes for the parent, consistent with "only an explicit add files
   anything":
   - GitCommands.swift:130 — delete the line. `cmdDiff --copy` already does
     `Clipboard.write(patch)` two lines above; the basket recording was always supplementary.
   - GitCommands.swift:197 — delete the line. Same reasoning; `Clipboard.write(url)` already
     delivers it.
   - ImageCommands.swift:32 — either delete the line (fully consistent with "explicit add only"),
     or, if the parent wants paste-image to keep auto-filing, `ContextBuffer().add(path)` — trivial
     since `path` is already a file path.
   - ImageCommands.swift:76-77 — `$0.text == path` → `$0.path == path`; `buf.record(current,
     label: ...)` → `buf.add(current)` (or delete both lines for the same "explicit only"
     consistency argument as above).

   The actual compiler output (`swift build -c release`, unabridged) is reproduced under
   "Verification" below. **Update:** resolved externally before this session ended — see
   "Verification" for the final green run — with fixes matching the ones recommended above.

## What the spec didn't anticipate — a live conflict with a different concurrent move

Partway through this session, `git status` showed `Sources/ChuteCore/MarkdownUnpack.swift`
deleted and `Sources/chute/main.swift` / `Sources/chute/Commands/FileCommands.swift` modified —
a **different** concurrent agent (not the one named in the dispatch, which was working on
FinderActions/FinderActionsSuite/site/marketing/docs) is running a `move-5-delete-unpack.md`
spec that removes `chute unpack` entirely.

This matters here because this spec's own rationale for keeping the XML bundle format says: "The
XML bundle stays as the SECOND option, for the chat-UI persona the owner has chosen to keep
serving **with `unpack`**." If `unpack` (turning a chat UI's markdown answer back into files) is
gone, half of that persona's round-trip is gone too — "Copy Basket as Context" still works as a
context-out mechanism on its own, but the stated justification for keeping two output formats is
weaker than the spec assumed. Worth the parent reconciling the two moves before both land; I did
not change my implementation for this since move-5 wasn't finished/confirmed while I worked.

Separately, and not caused by me: `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift:213`
force-unwraps `ChuteActions.find("copy-paths")` (or similar — see backtrace below), which returns
`nil` in the FinderActions.swift/FinderActionsSuite.swift state the other agent had mid-edit at
verification time. This crashes the whole `chutetests` binary (SIGTRAP) before it reaches
`contextBufferSuite()` or `statusMenuSuite()`, which run later in
`Sources/chutetests/main.swift`'s fixed call order. Confirmed via `lldb`:

```
* thread #1 stop reason = Swift runtime failure: Unexpectedly found nil while unwrapping an Optional value
    frame #1: chutetests`closure #1 in finderActionsSuite() at FinderActionsSuite.swift:213:64
```

Not one of my seven files; I did not touch it. Retried the full build+run four times over ~2
minutes as their edit continued landing (`git status` showed `FinderActions.swift`,
`FinderActionsSuite.swift`, `chute/main.swift`, `chutetests/CoreSuites.swift` all changing) —
still crashing at last check. See "Verification" for the numbers this leaves me able to report.

## Decisions (and why)

- **Copying the basket no longer empties it.** The old `bufferFlush`/`cmdBuf all` cleared after
  copying (unless `--keep`). The spec adds a *second* copy format (@mentions vs Context) reading
  the *same* basket; auto-clearing on either one would make the other unusable ("copy as
  @mentions" would destroy the option to also "copy as Context"). `Empty Basket` / `chute basket
  clear` is now the only way to empty it — an explicit, separate decision, matching "only an
  explicit add files anything" applied symmetrically to the exit side. This also let the `--keep`
  flag be deleted outright rather than kept as a wart.
- **`chute basket` subcommands are exactly `add|list|copy|clear`**, no `all`/`flush` aliases for
  `copy` — the spec enumerates exactly these four and the action itself changed shape (format
  selection via `--format`), so there was no old behaviour worth aliasing.
- **Basket stayed a `.submenu`**, not converted to a flat `.header` section. The spec's own
  wording — "a section... whose **children** are the file rows" — maps to the existing
  `Kind.submenu([MenuNode])` case; `.header` in this file never carries children of its own, its
  siblings are appended separately by the caller. "The count must be visible without hovering"
  reads as already true of a submenu's own title (it was true of "Recent Copies (n)" before too);
  what actually needed to change was its position, so that's what moved.

## Finder row the parent should add (not owned here)

`ChuteAction(id: "add-to-basket", ..., template: ["basket", "add", "{files}"], ...)` — i.e. the
exact CLI invocation is:

```
chute basket add {files}
```

where `{files}` expands to the Finder selection as separate arguments (same expansion
`ChuteActions.argv` already does for every other `{files}` template in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift`).
`scope: .selection`, `kind: .copy` (it only ever adds bookkeeping, never touches the selected
files themselves).

## `helpText` line the parent should change (not owned here)

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:12`, currently
(confirmed unchanged by the concurrent edit as of this writing):

```
  buf add|list|all|clear                                  Every recent copy, together
```

Replace with:

```
  basket add|list|copy|clear                              Files from anywhere, as @mentions or one bundle  --format context
```

And add `case "basket": cmdBasket(args)` beside the existing `case "buf": cmdBuf(args)` at
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:83` — `cmdBasket` is
already defined and exported from `ContextCommands.swift:110`; `cmdBuf` is kept as its one-line
alias so the existing line does not need to change at all if the parent wants to touch as little
of `main.swift` as possible.

## Verification

```
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run -c release chutetests
```

**`swift build -c release`** — the four ChuteCore/ChuteApp/chutetests-only builds
(`swift build -c release --target ChuteCore --target chutetests --target ChuteApp`) are green.
The full build (including the `chute` executable target) currently fails with exactly these five
errors, all in the two unowned files described above:

```
Sources/chute/Commands/GitCommands.swift:130:25: error: value of type 'ContextBuffer' has no member 'record'
Sources/chute/Commands/GitCommands.swift:197:21: error: value of type 'ContextBuffer' has no member 'record'
Sources/chute/Commands/ImageCommands.swift:32:21: error: value of type 'ContextBuffer' has no member 'record'
Sources/chute/Commands/ImageCommands.swift:76:34: error: trailing closure passed to parameter of type 'Predicate<ContextBuffer.Entry>' that does not accept a closure
Sources/chute/Commands/ImageCommands.swift:77:17: error: value of type 'ContextBuffer' has no member 'record'
```

(At the same moment, `Sources/chute/Commands/FileCommands.swift` also errors on `MarkdownUnpack`
— that one is the *other* concurrent agent's move-5 work, already broken before I touched
anything, unrelated to this diff.)

The spec's verify command is `swift build -c release && swift run -c release chutetests` — the
`&&` means that as long as the *whole package* fails to build (the five errors above, in two
files I don't own), the test run never even starts. Run standalone (`swift run -c release
chutetests`, or the equivalent `--target ChuteCore --target chutetests --target ChuteApp` build)
it works fine, since `chutetests` only depends on `ChuteCore`, never on the broken `chute` target.
Real numbers, in the order obtained, over the course of this session (the other agent kept
editing `FinderActions.swift` / `FinderActionsSuite.swift` / `chute/main.swift` throughout):

- **Baseline given at dispatch: 986 assertions, 0 failed.** Reproduced myself before making any
  change: **986 assertions passed, 0 failed.**
- **After the full rewrite:** 953 assertions passed, 0 failed. The −33 delta is entirely inside
  the two suites I rewrote — fewer, more targeted path-based assertions replacing the old
  text-blob dedupe/label assertions that no longer apply to a path-only store. No failures at any
  point in my own work.
- **A while later, transiently:** the full `chutetests` binary exited via SIGTRAP inside
  `FinderActionsSuite.swift:213` before reaching either suite I own — the other agent's edit was
  mid-flight through a state where `ChuteActions.find(...)` returned `nil` against an
  already-force-unwrapped test. Confirmed via `lldb` (backtrace above), confirmed not caused by
  any of my seven files (`git diff` on all seven was unaffected; only their files' mtimes were
  moving). Rebuilt and reran four times over ~2 minutes; still crashing each time in that window.
- **Most recent check, this state now resolved:** rebuilt clean, ran
  `/Users/sxope/Documents/2026/Development/37.chute/.build/release/chutetests` directly —
  **907 assertions passed, 0 failed.** The further drop from 953 is the other agent's own test
  and menu changes (their `FinderActionsSuite.swift` / `CoreSuites.swift` edits, and the
  `move-5-delete-unpack` deletions), not mine — my two suites' own pass/fail contribution is
  unchanged from what the perturbations below prove.
- **Resolved before I finished writing this file.** `Sources/chute/Commands/GitCommands.swift`
  and `Sources/chute/Commands/ImageCommands.swift` (both outside my seven, per `git diff` — I
  never touched either) were fixed externally, matching almost exactly the one-line fixes
  recommended above (both `record(...)` lines in GitCommands.swift deleted; ImageCommands.swift's
  three call sites deleted rather than converted to `add`). **Final run of the literal verify
  command, `swift build -c release && swift run -c release chutetests`: build green, 907
  assertions passed, 0 failed.**

**Perturbations (both run against the isolated `ChuteCore`+`chutetests` build, which is
unaffected by the `chute`/FinderActionsSuite issues above):**

1. Restored the old silent-drop behaviour — added `fm.fileExists(atPath: p)` back into the
   `entries()` guard, simulating the pre-move bug where a vanished thing just disappears from the
   list instead of being shown as missing. Result: **7 assertions failed, 915 passed** — cleanly,
   no crash (had to harden `buf.entries()[0]` → `buf.entries().first` in my own test first; the
   unguarded subscript trapped instead of failing the assertion the first time through). Reverted;
   confirmed back to the file's current (correct) state.
2. Made `bundleText()` emit its own joined format (`--- context N ---`) instead of calling
   `ContextBundle.assemble`. Result: **1 assertion failed, 952 passed** — exactly the
   byte-identical DRY assertion, nothing else. Reverted.

## Net lines, the seven owned files

```
 Sources/ChuteApp/main.swift                  |  96 +++++++++-----
 Sources/ChuteCore/ContextBuffer.swift        | 167 +++++++++++-------------
 Sources/ChuteCore/StatusMenu.swift           |  46 +++++--
 Sources/chute/Args.swift                     |  29 +++--
 Sources/chute/Commands/ContextCommands.swift |  80 ++++++------
 Sources/chutetests/ContextBufferSuite.swift  | 187 +++++++++++++--------------
 Sources/chutetests/StatusMenuSuite.swift     |  75 ++++++-----
 7 files changed, 363 insertions(+), 317 deletions(-), net +46 lines
```

`ContextBuffer.swift` itself, the one file the spec explicitly asked to net smaller: **155 → 135
lines** (my first pass came out at 157 — larger — because of over-written doc comments; trimmed
before finishing). The three test/menu-wiring files (`ChuteApp/main.swift`,
`ContextCommands.swift`, both test suites) are net larger because they gained a second output
format (@mentions vs Context) and better failure messages where the spec explicitly asked for
them (item 4's "say something instead") — both real feature surface, not padding.

## Things the spec got wrong or left ambiguous

1. Section 3's second bullet lists the basket's children as "the file rows, then a separator,
   then `Copy Basket as Context` and `Empty Basket`" — omitting `Copy Basket as @mentions`
   entirely. The very next bullet clarifies the real order (@mentions first, Context second,
   Empty last); implemented the clarified order. Worth tightening the spec text itself if it's
   reused.
2. "The count must be visible without hovering" reads, on first pass, like an instruction to stop
   using a submenu (`.header`-style, like Waiting/Working/Idle). It isn't — a submenu parent's
   title (with its count) was already visible without hovering before this move; "children" in
   the same paragraph only maps onto the existing `.submenu` case. The actual, actionable
   instruction is the position change (above Local Servers). See "Decisions" above.
3. The "restore the 2MB silent return" perturbation instruction assumes `maxEntryBytes` is still
   present to restore. It's deleted outright per item 5 ("delete the constant") — there's nothing
   to restore. Perturbed the nearest real analogue instead (the missing-path guard) — see
   Verification.
4. Four call sites outside the seven owned files call the old text-based `ContextBuffer` API
   directly (not through `Out.deliver`), so "`Out.deliver`'s automatic recording... goes" doesn't
   fully cover the surface area that breaks. See "The ownership conflict I hit" above.
