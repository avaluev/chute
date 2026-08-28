# SPEC — Move 3: unpack accepts the format agents actually emit, and tokens stops lying

Repo root: `/Users/sxope/Documents/2026/Development/37.chute`
Owner: one agent. **You own only these files. Do not touch any other file.**

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/ContextCommands.swift`
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift`

Write your findings to `/Users/sxope/Documents/2026/Development/37.chute/docs/specs/move-3-FINDINGS.md`
before you finish — your return value dies with the parent process.

## Part A — `unpack` rejects its own most common input (28.5 min/day, the #2 job)

`MarkdownUnpack.parse` line 39 decides the path like this:

```swift
if let path = pathFrom(info: info) ?? pathFromContext(lines, before: i) {
```

`pathFrom` (:80) reads only the fence info string. `pathFromContext` (:88) looks only BACKWARDS,
up to three non-empty lines. Neither reads `body[0]`. Verified by hand:

| Format | Accepted today |
|---|---|
| ```` ```ts src/a.ts ```` | yes |
| `**src/b.ts**` before the fence | yes |
| ```` ```ts ```` then `// src/c.ts` | **no** |
| ```` ```python ```` then `# app/main.py` | **no** |

The last two are what Claude, GPT and Cursor emit most often.

`body` is a `[String]` fully populated by line 38, before the decision at line 39 — no
restructuring needed. Add a third fallback:

```swift
if let path = pathFrom(info: info) ?? pathFromContext(lines, before: i) ?? pathFromBody(body) {
```

`pathFromBody` must:
- read `body.first` only (never a later line — a path-shaped string on line 40 of a file is not a
  filename, it is code)
- strip ONE leading comment marker: `//`, `#`, `--`, `;`, `/* … */`, `<!-- … -->`
- trim whitespace, then run the EXISTING `looksLikePath` (:73). Do not write a second predicate.
- return nil for anything else

Roughly ten lines, one pure function, no new type, no new file.

### Non-negotiable — this is a trust boundary
A comment-sourced path is untrusted LLM output exactly like a fence-sourced one. It must keep
flowing through the existing `validate` (:49 — rejects leading `/`, `~`, and any `..` component)
and `staysInside` (:63 — the symlink-escape guard applied where the write happens). Do NOT add a
bypass, do NOT relax either guard, and do NOT add a new sanitiser alongside them.

### Tests — append INSIDE the existing `T.suite("MarkdownUnpack")` block
It is at `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift:71-86`.
Match the existing one-liner style exactly (`T.eq` / `T.ok` / `T.throwsError`, plain-English label
last). Add:
1. ```` ```ts ```` + `// src/c.ts` -> path `src/c.ts`
2. ```` ```python ```` + `# app/main.py` -> path `app/main.py`
3. a `<!-- -->` or `/* */` form
4. the comment marker is STRIPPED from the written content? **Decide and state which.** The body
   comment is part of the file the agent wrote, so it should almost certainly be KEPT. Assert
   whichever you choose so the decision is pinned.
5. `// ../../etc/passwd` in a body comment is still REJECTED by `validate`
6. a block whose `body[0]` is ordinary code (`const x = 1`) still yields NO file — the info-string
   and heading paths must not regress

## Part B — `tokens` under-reports by 2.8x against `bundle`

`ContextCommands.swift:27` counts the assembled `ContextBundle.xml` blob.
`ContextCommands.swift:42` sums raw per-file contents. JTBD 24 exists to answer "how big is this
before you send it" and the thing the user pastes is the bundle's text.

Fix `cmdTokens`: keep the per-file breakdown rows exactly as they are — that is the command's
value — but make the **TOTAL** line the assembled-bundle count. Reuse what `cmdBundle` already
calls, do not reimplement:
- `FileScan.bundleFiles(expanded)` (`Sources/ChuteCore/FileScan.swift:82`)
- `ContextBundle.xml(_:root:)` (`Sources/ChuteCore/ContextBundle.swift:17`)
- `TokenEstimate.tokens(in:)` (`Sources/ChuteCore/TokenEstimate.swift:7`)

Honour `--format md` the same way `cmdBundle` does, so the two agree under both formats.
The per-file rows will no longer sum to the total — that is correct and must be visible: label
the total so a reader understands why (the wrapper markup is real tokens they will paste).

Add a test asserting the two paths produce the SAME number for the same file set.

## Verify — run these, read the tally, do not trust an exit code
```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
```
Baseline to beat: **962 unit assertions, 158 smoke, 0 failed.** Report the REAL numbers.

**Perturb every new guard to RED before believing it.** Reintroduce the bug (e.g. delete the
`pathFromBody` call), watch the new assertions fail, record the failing count, restore with a
targeted edit. A guard that stays green when the bug comes back is not a guard — that trap has
already been paid for once in this repo.

Do NOT commit. Leave the tree dirty; the parent commits.
