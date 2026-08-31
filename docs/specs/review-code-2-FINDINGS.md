# Code review — 258f7ab..HEAD (six commits: Finder deletions, MarkdownUnpack removal, Context Basket rewrite)

Reviewed by running, not just reading. Both gates pass exactly as specified:
- `swift build -c release && swift run -c release chutetests` → **919 assertions passed, 0 failed**
- `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` → **smoke: 140 passed, 0 failed**

The ContextBuffer rewrite, the CHUTE_BUFFER_DIR override, the two hand-over formats, and the
`Out.deliver` auto-record removal (focus items 2–6) are all correct — verified by code trace,
by the passing test suites, and by one live check against the owner's real `~/.chute/buffer`
(see PASS notes at the bottom). The real findings are documentation orphans: two files that
still promise a `chute unpack` / a Finder row that this session deleted.

---

## [HIGH] docs/12-CAPABILITY-MAP.md — the Finder menu diagram is wrong in both directions

File: `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md:27-61`

This file *was* edited in this session (the commit that deleted `clean-junk` even left a comment
at line 55 admitting "pre-existing drift... that reconciliation is a separate piece of work"),
but the edit did not fix the actual drawing. Ground truth, run live:

```
$ .build/release/chute finder-actions --menu
→ 11 actions, 6 rows
  Copy Full Paths
  Copy Files as Context
  Copy Folder Tree  ▸ (2/4/All Levels)
  Add to Context Basket
  New File  ▸ (Empty Markdown / Markdown from Clipboard / Image from Clipboard)
  Set Up for an Agent  ▸ (Add Agent Rules / Save a Checkpoint)
```

The doc's ASCII diagram and row table (lines 27-61) instead show:
- **"Move Junk to Trash…" / `clean-junk`** as a live red row with its own JTBD-13/6.6-min-a-day
  entry — this action does not exist in `ChuteActions.all` (deleted commit 117cfcf) and does not
  print in the real menu.
- **No row at all for "Add to Context Basket"** — the headline feature of this session
  (`basket-add`, added in f317fc8) is entirely absent from the diagram and the row table.

Net effect: a reader who trusts this page (which literally says "Reproduce it any time without
building or clicking: `swift run chute finder-actions --menu`") gets a menu shape that never
existed at any commit — old row present, new row missing — and the "6 of 22 ledger JTBDs" count
directly under it is arithmetic over that wrong list.

Secondary, same file: line 8 says "**`chute` CLI** | 27 commands" while line 98 of the *same
file* says "26 commands." Ground truth: `.build/release/chute help | grep -cE '^  [a-z]'` → 26.
Line 8 is the stale one.

Fix: replace the ASCII block and row table (lines 27-61) with the live `finder-actions --menu`
output above (drop the `clean-junk` row, add `Add to Context Basket` with its JTBD-22 entry and
`basket-add`/`chute basket add`), and correct line 8 to 26.

## [HIGH] README.md — still documents `chute unpack` as a live command

File: `/Users/sxope/Documents/2026/Development/37.chute/README.md:64,78,92,182-183`

Not touched by this diff at all (`git log -1 -- README.md` predates 258f7ab), so this is exactly
the "surviving reference the deletion missed" the task asked to hunt for. `chute unpack` is gone:

```
$ .build/release/chute unpack
chute: unknown command 'unpack' — run `chute help`
exit=1
```

README still shows it in four places a real user reads before anything else: the "loop" GIF
caption + embed (`marketing/media/unpack.gif`, line 64), the copy-pasteable command block (line
78, `chute unpack  # a multi-file answer on the clipboard → real files`), the command reference
table (line 92), and two of the four safety-guarantee bullets (182-183, "`unpack` refuses to
escape its target directory" — describing a symlink-escape guard, `MarkdownUnpack.staysInside`,
that no longer exists anywhere in the binary).

Failure scenario: a new user copies line 78 verbatim into their shell → `unknown command 'unpack'`
on the very first command from the README that isn't `paths`/`bundle`/`tokens`.

## [MEDIUM] site/ — the marketing site inherits the same stale claim

Files:
- `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/commands.json:22-24` — `"cmd":
  "chute unpack"` row, served on the public `/docs` command reference.
- `/Users/sxope/Documents/2026/Development/37.chute/site/src/app/docs/page.tsx:32` — hardcodes
  `chute unpack` in the copy-pasteable "loop" block, under a comment claiming "Generated from
  README.md ... so this page cannot drift" — it drifted together with README.md, disproving the
  comment's premise the moment one source goes stale.
- `/Users/sxope/Documents/2026/Development/37.chute/site/src/app/terms/page.tsx:88` — lists
  `unpack` among "destructive-looking operations" in the liability disclaimer; lower stakes (legal
  boilerplate, not a copy-pasteable command) but same root cause.

Same root cause as the README finding, not a separate bug — fixing README.md and re-running
whatever generates `commands.json` (or hand-editing it, since the generator (`brand/gen-commands.mjs`)
was not run this session) resolves all three.

Not flagged: `site/src/app/changelog/page.tsx:20` mentions "Save Clipboard as Files" and other
now-renamed/removed rows — that entry is a dated (2026-08-28) historical release note, correctly
describing what shipped in 0.2.0 at the time. Changelogs are allowed to describe the past.

---

## PASS — verified, not just read

- **ContextBuffer rewrite** (`Sources/ChuteCore/ContextBuffer.swift`): dedupe is on `path`
  (`add()` returns the existing entry rather than writing a duplicate); a missing file shows
  `"<name> — missing"` via `preview` rather than being filtered out of `entries()`; `keep` (10)
  still evicts oldest-first after `add()`; 0700/0600 are set on every `add()`, including a repair
  of the directory's existing mode (unconditional `setAttributes` call, not just
  `createDirectory`'s create-time attributes). Old-format JSON (`{ts,label,text}`, no `"path"`
  key) is skipped by `entries()`'s `guard let p = o["path"] as? String` rather than crashing —
  confirmed **live**, not just by unit test: the owner's real `~/.chute/buffer` currently holds
  10 old-format files (written by his still-running, pre-session build of ChuteApp.app, PID 79552,
  up since Saturday — unrelated to this review), and `.build/release/chute basket list` against
  that real directory (no override) returns `"basket is empty"`, no crash.
- **CHUTE_BUFFER_DIR**: safe as scoped. It only supplies a *default* inside `ContextBuffer.init`
  (the existing `directory:` constructor parameter still takes precedence for any caller that
  passes one explicitly — no production call site does), follows the same
  `ProcessInfo.processInfo.environment[...]` pattern already established by `CHUTE_HEADLESS`
  (`FinderReveal.isHeadless`, `ResultHUD`), and is undocumented in `chute help` by design. Nothing
  else in the codebase needs the same treatment: `HookState` already takes a constructor-injected
  `root` for the same purpose, which is sufficient for Swift-level tests; `CHUTE_BUFFER_DIR`
  exists only because `smoke.sh` drives a compiled subprocess, where constructor injection isn't
  reachable.
- **Two hand-over formats**: both `assembledBundle` (`Sources/chute/Commands/ContextCommands.swift`)
  and `ContextBuffer.bundleText()` call the single `ContextBundle.assemble` defined once in
  `Sources/ChuteCore/ContextBuffer.swift` — no second formatter to drift. Confirmed by the smoke
  assertion `"the bundle format is the bundle"` (passed) comparing `basket copy --format context`
  against `chute bundle` over the same two files.
- **`Out.deliver` losing `record:`**: build succeeds with zero remaining references to `record:` or
  `ContextBuffer().record(...)` anywhere in `Sources/`; every prior call site (`cmdDiff`, `cmdGist`,
  `cmdPasteImage`, `AppDelegate.deliver`) had its `record`/`label`-for-recording call removed in the
  same commit, not left dangling.
- **Orphan grep** (items 1/6): no surviving references to `MarkdownUnpack`, `UnpackedFile`,
  `UnpackError`, `staysInside`, `cmdUnpack`, `unpack-here`, `sandbox-here`, `clean-junk` (as an
  action id in Swift), or `terminal` (as an action id) anywhere under `Sources/`, `Scripts/`,
  `demo/`, other than in historical comments/specs that correctly say "removed 2026-08-31."
  `bufferReveal`/`bufferMentions`/`recentTokens` (`Sources/ChuteApp/main.swift`,
  `Sources/ChuteCore/StatusMenu.swift`) are correctly wired and covered by
  `Sources/chutetests/StatusMenuSuite.swift`.
