# FINDINGS — Move 5: remove `unpack` entirely

**Date: 2026-08-31**

This deletes the product's second-largest documented job (JTBD 9, "an answer back into real
files", 28.5 min/day) on the owner's explicit decision, not as a cleanup. `unpack` existed for a
person whose model cannot write to disk; Claude Code / Cursor agents already write files, so that
moment never occurs for the ICP. Sunk cost — `pathFromBody`, the shebang guard, the `staysInside`
symmetry fix, all landed the same week — is not a reason to keep it, and none of it was kept.

## Files deleted

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/MarkdownUnpack.swift` — whole
  file. **Grepped first**, repo-wide, for `MarkdownUnpack`, `.validate(`, `.staysInside(` before
  deleting: every call site of `parse`/`validate`/`staysInside` was inside this file's own tests
  (`CoreSuites.swift`) or inside `cmdUnpack` (`Sources/chute/Commands/FileCommands.swift`) — nothing
  else in the repo imports it. Nothing was kept back.
- `/Users/sxope/Documents/2026/Development/37.chute/demo/tapes/unpack.tape`
- `/Users/sxope/Documents/2026/Development/37.chute/demo/gui/tapes/turn-an-answer-back-into-files.sh`
  (the paid Finder-menu recording for the same retired case)

## Files changed

- `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/FinderActions.swift` — removed
  the `unpack-here` `ChuteAction` (rows 6→5, actions 11→10); left a dated comment where it stood,
  matching the sandbox-here/clean-junk/terminal convention already in the file. Also fixed the
  `confirmButton` doc comment, which cited `unpack` as a still-existing CLI command.
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/FileCommands.swift` —
  deleted `cmdUnpack` whole (FR-06 section), left a one-line pointer to this spec.
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift` — deleted the `unpack`
  line from `helpText` and `case "unpack": cmdUnpack(args)`.
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/CoreSuites.swift` — deleted
  the `MarkdownUnpack` suite (20 assertions) and `MarkdownUnpack.staysInside` suite (8 assertions),
  28 total.
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift` —
  every `unpack`/`unpack-here` reference reworked (rows count+list, the "safety class represented"
  check, the paid-surface loop, the one-click loop, the argv check). **The destructive-action
  invariant (constraint 5) is kept, not deleted**: `T.eq(Set(destructive.map(\.id)), [], ...)` now
  asserts emptiness, with a comment explaining an empty set is legitimate and the assertion must
  keep standing for the next action that changes files. A second, closely related assertion — "every
  safety class actually represented... `.destructive`" — also had to drop `.destructive` from its
  check for the same reason (it was a real, not cosmetic, test failure caught by running the suite;
  see Verification).
- `/Users/sxope/Documents/2026/Development/37.chute/Scripts/smoke.sh` — removed sections "6. unpack —
  dry run is the default", "7. unpack refuses path traversal", "7b. unpack refuses to follow a
  symlink...", the `unpack-here)` case in the section-15 sweep, and the section-15 effect-check block
  ("NFR-05 ACROSS THE MENU BOUNDARY... unpack-here previews..."). Left two comments unpack-adjacent
  but not unpack-specific: the "14 = the 9 original actions..." comment (word "unpack" struck from
  its list) and the section-23 NFR-05 framing comment, both flagged as already-stale from earlier,
  unrelated removals (see "Pre-existing staleness" below) rather than silently re-numbered.
- `/Users/sxope/Documents/2026/Development/37.chute/demo/verify.sh` — removed the two `demo "unpack
  ..."` lines and their `clip` calls; kept the `new` demo and its shared fixture line.
- `/Users/sxope/Documents/2026/Development/37.chute/demo/gen-shorts.mjs` — removed `"unpack"` from
  the `HAND_WRITTEN` set (its tape no longer exists).
- `/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/cases.ts` — removed the
  `turn-an-answer-back-into-files` case entirely (same convention as move-1/move-1b: no
  "retired" marker in this file, just gone). Left `site/public/media/turn-an-answer-back-into-files.*`
  in place, unreferenced — `check-cases.mjs` treats orphaned media as a non-failing `note`, and
  move-1b already left `a-clean-room-for-a-risky-agent.*` the same way.
- `/Users/sxope/Documents/2026/Development/37.chute/marketing/06-FACT-SHEET.md` — re-measured date,
  CLI commands (26), Finder actions (10/5 rows), unit assertions (907), terminal/GUI tape counts,
  case count (21), and the "28 commands" false-claim row. Also updated the **Time saved** section
  (removed the JTBD-9 row, fixed the headline and ledger totals) — technically outside the literal
  "§Verification" pointer in the spec, but it restates the exact figure this move retires, and
  leaving a table titled "use these" with a dead 28.5 min/day job would ship the kind of false claim
  this file exists to prevent.
- `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md` — removed `unpack-here`
  from the menu diagram, the row table, the "what each one does" prose list, and the CLI-capability
  table (section B); updated the "Total surfaced through Finder" line and "27 commands" → "26
  commands"; updated the JTBD-4 aside paragraph, which asserted a test guard (`unpack` stays one
  click) that no longer exists.
- `/Users/sxope/Documents/2026/Development/37.chute/docs/03-JTBD-LEDGER.md` — JTBD 9's row struck
  through and marked `**RETIRED 2026-08-31**`, per the spec's instruction to retire rather than
  silently drop the row. Freq/manual/chute columns left as historical record; name, saved/day and
  tier struck. `check-cases.mjs` still parses this row fine (cell[1] is still the integer `9`); no
  case references it any more, so it is simply unused.

## Grep for other callers of `validate`/`staysInside` (constraint 4)

```
grep -rn "MarkdownUnpack\|\.validate(\|staysInside" --include="*.swift" .
```
Every hit was inside `MarkdownUnpack.swift` itself, `CoreSuites.swift`'s two now-deleted suites, or
`cmdUnpack` in `FileCommands.swift`. **Nothing else in the repo called `validate` or `staysInside`.**
The whole file was safe to delete; nothing was kept back.

## Numbers, derived, not copied

All measured against the actual current source/binary after every edit, not computed by hand from
the spec or an old doc. Commands and outputs below.

**Unit assertions** — `swift build -c release && swift run -c release chutetests`:
```
✅ 907 assertions passed
```
0 failed. Cross-verified: the concurrent move-2 agent (context-basket, editing the other seven
files) independently ran the identical command and got the identical **907 passed, 0 failed**
(`docs/specs/move-2-FINDINGS.md:274-275`) — two independent measurements agree.

Arithmetic for the delta I own: CoreSuites.swift lost 28 assertions (20 in `MarkdownUnpack`, 8 in
`MarkdownUnpack.staysInside`, counted by hand from the deleted source). FinderActionsSuite.swift
lost 6 more, all *runtime* consequences of `unpack-here` no longer existing, not source edits to a
count: the `for a in destructive` loop's body (2 assertions) stopped firing since the set is now
empty; the `["unpack","clean"].contains(...)` template check stopped matching (−1); the paid-surface
loop and the one-click loop each dropped from 2 ids to 1 (−1 each); the dedicated argv check for
`unpack-here` was deleted outright (−1). Total mine: −34. The parent's stated baseline (957) does
not reconcile arithmetically against 907 by that −34 alone (957−34=923≠907); the remaining gap is
the concurrent move-2 agent's own suite rewrites (confirmed in their FINDINGS: their two suites
alone dropped 33, from 986→953, and the *combined* state converged on 907 independently of my
work). **Trust the measured 907, not a hand-derived delta from a baseline that was moving under two
concurrent agents.**

**Cases** — `cd site && npm run check:cases`:
```
ok   the app carries 85.7 min/day, the free CLI 83.5 — the paid surface is the larger half
cases: 21 checked, 0 failed
```
Arithmetic: 22 (parent's stated baseline) − 1 (`turn-an-answer-back-into-files`, JTBD 9, 28.5
min/day) = 21. Matches exactly. Paid surface 85.7 + 28.5 (the case just removed) = 114.2 — the exact
figure FACT-SHEET stated as the app-surface total before this edit, confirming the before/after
figures are internally consistent, not guessed.

**Claims** — `cd site && npm run check:claims`:
```
ok    no forbidden claim appears on any page
ok    no page names a retired Finder action (13 live titles checked)
claims: every claim on the site is one the fact sheet stands behind
```
0 failed. (The "13 live titles" figure comes from a pre-built, not-freshly-rebuilt `.next` HTML
snapshot the script reads — not something this move controls; the important line is 0 failed.)

**Finder menu** — `.build/release/chute finder-actions --json` / `--menu`, run against a fresh
release build:
```
→ 10 actions, 5 rows
```
JSON lists exactly: copy-paths, bundle-xml, tree-2, tree-4, tree-all, new-markdown,
new-markdown-clipboard, paste-image, seed-rules, checkpoint-here — no `unpack-here`, matching
`FinderActions.swift` source exactly. (11→10 actions, 6→5 rows.)

**CLI commands** — `.build/release/chute help | grep -cE '^  [a-z]'`:
```
26
```
Note: FACT-SHEET said **25** before this edit, but that was already wrong — CAPABILITY-MAP said
**27** for the same pre-edit state, and the real count (measured the same way, pre-edit would have
been 27) agrees with CAPABILITY-MAP, not the old FACT-SHEET figure. I did not propagate either
stale number; 26 is measured directly against the live binary post-edit.

**Demo delivery checks** — `demo/verify.sh`: `grep -c '^demo "' demo/verify.sh` → **11** (was 13;
the two `unpack` demos removed, `new` kept). Not run end-to-end (constraint 3 forbids
`./Scripts/smoke.sh`; `demo/verify.sh` itself was not run either since it also shells out to a
release binary in ways not covered by the allowed verification — only its syntax and content were
checked). `bash -n` passes on both `Scripts/smoke.sh` and `demo/verify.sh`.

**Terminal/GUI tapes** — real `ls` counts, not computed: `ls demo/tapes/*.tape | wc -l` → **16**
(was 17; `unpack.tape` gone). `ls demo/gui/tapes/*.sh | wc -l` → **9** (was 10;
`turn-an-answer-back-into-files.sh` gone).

## Constraint 1 — the build WAS transiently broken by the other agent's work, and I stopped

Early on, `swift build -c release` failed with `value of type 'ContextBuffer' has no member
'record'` inside `Sources/chute/Commands/GitCommands.swift` and `ImageCommands.swift` — not my
files, but downstream of `ContextBuffer.swift`'s in-flight API change (one of the seven I do not
own). I did not edit either file. Waited 60s, retried — still broken (expected; theirs was a
multi-file, multi-minute edit, not a race). I isolated verification to `--target ChuteCore` and
`--target chutetests` (chutetests depends only on ChuteCore, never on the broken `chute` target) to
keep working without touching anything unowned. The `chute` executable target resolved itself
later in the session (their `GitCommands.swift`/`ImageCommands.swift` fixes landed externally,
confirmed by `docs/specs/move-2-FINDINGS.md`), at which point I re-ran the literal spec verify
command and got the green, 907-assertion result above.

Separately: I also hit — and fixed, since it was a genuine bug in my own edit, not theirs — a real
runtime crash (SIGTRAP, force-unwrap of nil) caused by `every safety class actually represented`
asserting `.destructive` was still present in the menu after I'd removed the only `.destructive`
action. `lldb`'s optimized-build line attribution pointed at the wrong line (a comment), which cost
real time to track down via a debug build; the actual defect was constraint 5's twin — the same
"empty set is legitimate" fix had to be applied to a second assertion, not just the one the spec
named. (The move-2 agent hit the exact same transient SIGTRAP independently and correctly
attributed it to my in-flight edit rather than theirs — see their FINDINGS, "not caused by me".)

## Cross-move note for the parent

`docs/specs/move-2-FINDINGS.md` (context-basket, concurrent this session) flags that its own spec
justified keeping the XML bundle format partly by "the chat-UI persona the owner has chosen to keep
serving **with `unpack`**." With `unpack` now gone entirely, that justification is weaker than
their spec assumed. Not something I changed — it's their file, their decision — flagging it here
too since both FINDINGS should say it once each.

## What the spec got wrong or left ambiguous

- Constraint 5's destructive-set invariant was correctly identified, but a *second* assertion in
  the same suite (`every safety class actually represented in the menu is used`) shared the same
  failure mode once `.destructive` had zero members, and the spec didn't mention it. Found only by
  actually running the suite (per constraint 7's own lesson) — a static read of the spec would have
  missed it.
- The spec's "Rows go 6 → 5" (item 1) and "Delivery checks will drop from 13" (item 6) were both
  correct as stated and needed no correction.
- Scripts/smoke.sh already contained real, pre-existing staleness unrelated to `unpack` — `clean-junk`,
  `sandbox-here` and `terminal` action ids are referenced in section 15's sweep and effect-check
  blocks, but none of those three exist in `ChuteActions.all` any more (removed by earlier,
  already-completed moves that never updated smoke.sh). The "14 = the 9 original actions..." total
  at line ~360 was already wrong before I touched anything (real total is now 10, and was probably
  ~13 before unpack's removal, not 14). I did not fix this — out of scope for "every unpack
  section," unverifiable without running smoke.sh (forbidden), and a larger job than this move. Left
  a comment flagging it for whoever does that reconciliation. `docs/12-CAPABILITY-MAP.md` has the
  matching disease: a `Move Junk to Trash…` row/diagram entry for the same nonexistent `clean-junk`
  action. Also not touched, also flagged in place.
- FACT-SHEET's "End-to-end" (146/174) and "Site routes" (38) rows were not re-measured — the first
  because constraint 3 forbids running smoke.sh, the second because `next build` was not run this
  session (time/scope). Both are now potentially stale from my `demo/verify.sh` and `cases.ts`
  edits; flagged rather than guessed.

## Tree state

Left dirty, as instructed. No `git add`/`commit`/`stash`/`checkout`/`restore` run. `git status`
shows the files above plus the seven files owned by the concurrent move-2 agent (already modified
before I started) and this repo's two new spec/FINDINGS docs.
