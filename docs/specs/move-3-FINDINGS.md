# FINDINGS — Move 3: unpack accepts the format agents actually emit, and tokens stops lying

Spec: `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-3-unpack-and-tokens.md`
Files owned and touched (exactly these three, nothing else):
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ContextCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift`

Tree left dirty. No commit, no add, no stash, no checkout was run.

## Part A — `pathFromBody`

`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift:39`
changed the decision chain to:
```swift
if let path = pathFrom(info: info) ?? pathFromContext(lines, before: i) ?? pathFromBody(body) {
```
New function at `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift:112-123`
(12 lines including the doc comment, ~10 lines of logic as the spec estimated). Reads
`body.first` only, strips ONE leading marker from `["//", "#", "--", ";", "/* */", "<!-- -->"]`,
trims, then calls the existing `looksLikePath` (:73) — no new predicate, no new type. Both
`validate` (:49) and `staysInside` (:63) are untouched and still run on every `pathFromBody`
result exactly as they do on fence-info and heading-sourced paths — no bypass was added.

**Decision on the comment marker** (spec asked me to pin one): the marker is **KEPT** in the
written content. `pathFromBody` only inspects `body` to extract a path string; the `UnpackedFile`
content at `MarkdownUnpack.swift:40` is still `body.joined(separator: "\n")`, unmodified. Pinned
by the assertion at `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift:130-131`:
`// src/c.ts\nexport const c = 1` is the full written content, comment line included.

### RED perturbation (Part A)
Reverted line 39 to `pathFrom(info: info) ?? pathFromContext(lines, before: i)` (dropped the
`?? pathFromBody(body)` call), rebuilt, ran `swift run -c release chutetests`:
```
❌ 6 failed, 966 passed
```
Failures: all 4 new "path from … comment on body[0]" assertions, the "marker is KEPT" content
assertion, and the "traversal path from a body comment is still rejected" assertion. The 7th new
assertion ("ordinary code on body[0] yields no file") stayed green, correctly — removing
`pathFromBody` cannot produce a false positive. Restored the call, rebuilt clean.

## Part B — `tokens` TOTAL

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ContextCommands.swift:35-59`.
Per-file breakdown loop (lines 39-45) is untouched. TOTAL (lines 47-58) now reuses
`FileScan.bundleFiles`, `ProjectRoot.of`, `ContextBundle.xml`/`.markdown`, and
`TokenEstimate.tokens` — the exact same four calls `cmdBundle` (:18-31) makes, including honoring
`--format md`. No reimplementation.

### A real gap found and closed
`chutetests` (Sources/chutetests/*.swift) only ever imports `ChuteCore`, never the `chute`
executable target — `cmdTokens`/`cmdBundle` live in `chute`, which is not importable from there.
My first draft of the "same number" test called the four ChuteCore functions twice in-process to
"prove" parity — RED-perturbing it (reverting `cmdTokens` to the old per-file sum) left it fully
green, because it never touches `cmdTokens` at all. That is a false guard, exactly what the spec's
perturbation instruction exists to catch. Replaced it with
`T.suite("CLI.tokensMatchesBundle")` at
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift:78-107`,
which shells out to the real compiled binary (`Shell.run`, already used elsewhere in this file at
:214) at `.build/release/chute` — the same binary path `Scripts/smoke.sh` uses — runs
`chute tokens <dir>`, parses the exact integer from the `%8d` TOTAL line, and compares it to a
locally-computed expected value using the same ChuteCore call chain `cmdBundle` uses. This
actually exercises the shipped command.

### RED perturbation (Part B)
Reverted `cmdTokens`'s TOTAL to the old `Out.line(String(format: "%8d  TOTAL (%@)", total, ...))`,
rebuilt (`chute` binary only — the buggy version was what got exercised), ran the suite:
```
❌ 1 failed, 969 passed
  • CLI.tokensMatchesBundle › the real `chute tokens` TOTAL matches the bundle-equivalent count …
      got:      18
      expected: 32
```
18 = naive per-file sum for the 2-file fixture, 32 = bundle-equivalent count — reproduces the
under-report the spec describes. Restored the fix, rebuilt both targets clean.

## Final verified numbers (real, from the commands in the spec)
```
cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release && swift run -c release chutetests
→ ✅ 970 assertions passed        (baseline 962 + 8 new: 7 in MarkdownUnpack, 1 in CLI.tokensMatchesBundle)

cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
→ smoke: 156 passed, 2 failed     (baseline 158 passed, 0 failed)
```

### The 2 smoke failures are NOT in Part A or Part B
Both are `FAIL uninstall removes chute` / `FAIL uninstall leaves no husk` in smoke.sh section 14
("sessions, doctor, hooks"). Verified directly against the built binary: `chute hooks uninstall
--settings <file>` (no `--force`) now prints "dry run — would remove Chute's hook(s) …" and writes
nothing, where smoke.sh's fixture calls it without `--force` and expects an immediate write. This
is `hooks uninstall` behavior — implemented outside my three files, in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/AgentCommands.swift`,
which `git status` shows as modified by the other agent working in this repo concurrently (along
with `DoctorCommand.swift`, `GitCommands.swift`, `SessionCommands.swift`, `main.swift` — none of
which I touched). All Part A/B-relevant smoke sections — "2. bundle", "4. tokens", "6. unpack —
dry run is the default", "7. unpack refuses path traversal", "7b. unpack refuses to follow a
symlink" — pass in full (every `ok` line present, none skipped).

## Where the spec was right / where I had to make a judgment call
- The spec's line numbers, function names, and the ~10-line estimate for `pathFromBody` were all
  accurate.
- The spec's Part B test instruction ("Add a test asserting the two paths produce the SAME number
  for the same file set") doesn't account for `chutetests` being unable to import `cmdTokens`/
  `cmdBundle` directly (different SPM executable target, ChuteCore-only test convention already
  established by every other file in `Sources/chutetests/`). I judged the intent — a guard that
  actually fails if `cmdTokens` regresses — over the literal shape, and shelled out to the real
  binary instead of writing an in-process test that (as proven above) cannot fail when the bug it
  is meant to catch comes back.
