# AUDIT — Finder menu / checkpoint / one-surface notify — 2026-08-28

## Verdict: SHIP WITH FIXES

All gates measured green on this tree:
- `cd /Users/sxope/Documents/2026/Development/37.chute && swift build -c release` → `Build complete!`
- `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests` → `✅ 637 assertions passed`
- `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh` → `smoke: 151 passed, 0 failed`

No CRITICAL and no HIGH findings. Four MEDIUM, six LOW. Nothing blocks the merge; the MEDIUMs
deserve a follow-up commit.

Note on the brief: docs/11-PHASE-0-RUNBOOK.md and docs/12-CAPABILITY-MAP.md were described as
untracked new files — both are tracked (`/Users/sxope/Documents/2026/Development/37.chute/docs/11-PHASE-0-RUNBOOK.md`
is committed unchanged; `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md`
is modified in this diff). Likewise `Sources/ChuteApp/Notify.swift` / `ResultHUD.swift` are already
committed (7e375bc, d543854), not in the uncommitted diff. Audited anyway, as asked.

---

## CRITICAL

None.

## HIGH

None. Specifically checked and cleared:

- **A — `write-tree` as the success judge does NOT silently hide the realistic total-failure
  mode.** Reproduced: with `.git/objects` unwritable, `git add -A --ignore-errors` fails AND
  `git write-tree` fails (`fatal: git-write-tree: error building trees`), so the guard at
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:41`
  fails loudly (`chute: could not write a tree object`, exit 1). A single unreadable file
  (chmod 000) is skipped and the summary honestly switches to "some paths could not be indexed
  and were left out" (GitCommands.swift:82). Verified by running the release binary against
  fixture repos. The one gap that survives is MEDIUM-1 below.
- **A — the nested-empty-repo fix works as claimed.** Reproduced: `git add -A --ignore-errors`
  with a commit-less nested repo exits 1 but stages everything else; write-tree emits the correct
  tree. Smoke section 8 regression (`/Users/sxope/Documents/2026/Development/37.chute/Scripts/smoke.sh:100-107`)
  passes.
- **A — the branch-exists comparison is correct in every branch I could construct.**
  `rev-parse --verify -q <branch>^{commit}` (GitCommands.swift:72) prints the full 40-char sha on
  success and nothing on failure; `commit` from `commit-tree` is also full-length, so the
  comparison at GitCommands.swift:73 cannot false-match. A branch ref manually pointing at a
  non-commit object makes `^{commit}` fail → empty output → `git branch` runs → fails loudly
  with git's own "already exists" — correct (fails, never silently succeeds).
- **B — no path fires both surfaces for one event.** Every ChuteApp call site (9 of them:
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/RequestInbox.swift:38,54,72`,
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift:171`,
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/ServersMenu.swift:50,53,65,72`,
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/SettingsWindow.swift:172`)
  goes through `notify()` at `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/Notify.swift:156-159`,
  which returns after `ResultHUD.show` succeeds. Inside `Notify.post`, each `switch` arm posts at
  most once; `deliver`'s completion-handler `fallback` (Notify.swift:117-119) only runs when the
  native `add` errored, so the banner it replaces never appeared. The `.notDetermined` branch
  posts once (deliver XOR fallback). No re-entrancy path posts twice.
- **E — release safety.** This diff touches no version string.
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Version.swift:12` is still
  `"0.2.0"` and `/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:32` refuses
  the existing tag — the trap is real but pre-existing and documented in
  `/Users/sxope/Documents/2026/Development/37.chute/docs/11-PHASE-0-RUNBOOK.md:23-31`. No release
  is triggered by this merge.

## MEDIUM

### M1 — A checkpoint containing ZERO files can exit 0 and hand the user a restore command

- **Where:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:36-41`
  (add judged only by `write-tree` emptiness) and the summary wording at GitCommands.swift:82-84.
- **Scenario (reproduced with the release binary):** a repo in which every file is unindexable
  (fixture: `git init; echo a > only.txt; chmod 000 only.txt`, i.e. a permissions-broken folder
  or external volume). `git add -A --ignore-errors` skips everything, the private index stays
  empty, `git write-tree` happily emits the empty tree `4b825dc642cb6eb9a060e54bf8d69288fbee4904`,
  and chute exits 0, creates the branch, and prints "some paths could not be indexed … restore
  with: git checkout chute/checkpoint-…". The "restore point" holds nothing. Also confirmed:
  `git write-tree` against a MISSING `GIT_INDEX_FILE` exits 0 with the empty tree, so any add
  failure that prevents index creation (e.g. add killed mid-run) mints the same empty checkpoint.
- **Why it matters:** this is a safety-net feature; a net reported as saved-with-caveats while
  holding zero files is discovered only on the day it is needed. "Some paths … were left out"
  understates "every path was left out".
- **Smallest fix:** after computing `tree`, fail when it equals the empty-tree sha while the
  directory has any entries (or while `git ls-files` against the private index is empty and
  `added.ok == false`): one `guard tree != "4b825dc642cb6eb9a060e54bf8d69288fbee4904" || !skippedSomething else { Out.fail(...) }`.

### M2 — `ResultHUD.show` can return true having drawn on no screen, suppressing the fallback

- **Where:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/ResultHUD.swift:126-135`
  (`origin(for:)` returns `.zero` when `screen?.visibleFrame` is nil) and ResultHUD.swift:40
  (the only false-returning guard is `NSApp == nil || isHeadless`).
- **Scenario:** `NSScreen.screens` is empty — clamshell Mac with the external display asleep or
  just unplugged, or a headless Mac mini with a live window server — while a Finder action
  completes. `show` places the panel at (0,0) of no screen, returns `true`, `notify()` returns,
  and NO notification is queued either. The event is reported nowhere, and unlike a notification
  it is not shown later when the display returns. The doc comment at ResultHUD.swift:33-35
  ("Never return true on a path that draws nothing") states the invariant; this path breaks it.
- **Smallest fix:** in `show`, `guard !NSScreen.screens.isEmpty else { return false }` (or make
  `origin` return an optional and return false on nil).

### M3 — The launch-time permission prompt and the "Turn On Chute Notifications…" item now oversell

- **Where:** `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/main.swift:42`
  (`Notify.requestAuthorization()` on every launch) and main.swift:117-120 (menu item; tooltip
  "Chute cannot tell you when an action finishes until notifications are on").
- **Scenario:** in the running app `NSApp != nil`, so the HUD wins on effectively every event and
  `Notify.post` almost never executes. A first-run user is shown a macOS permission dialog for a
  channel the app will use only in the no-screen/headless edge; and the tooltip is now factually
  false — the HUD reports completions regardless of notification permission. Additionally,
  `Notify.deniedAtLastCheck` (`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteApp/Notify.swift:17`)
  is only written inside `Notify.post`, which no longer runs, so the fix-it item will in practice
  never appear and `~/.chute/notifications.txt` (read by
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/DoctorCommand.swift:19`)
  goes stale — `chute doctor --report` will report whatever state the pre-HUD build last wrote.
- **Smallest fix:** drop the launch-time `requestAuthorization()` (the `.notDetermined` branch in
  `Notify.post` already asks at the moment a notification is actually needed), and reword the
  tooltip to what notifications now are (the no-screen fallback) or remove the item.

### M4 — docs/12 self-contradiction: "10 of the 24 ledger JTBDs" vs a row table surfacing 11

- **Where:** `/Users/sxope/Documents/2026/Development/37.chute/docs/12-CAPABILITY-MAP.md:64`
  claims 10; the row table at docs/12-CAPABILITY-MAP.md:56 lists JTBD **4** as surfaced
  ("**3** + **4** Syntax detection"), making the distinct set {1,2,3,4,5,6,7,8,9,12,13} = 11.
- **Detail:** the ≈129 min/day figure is the sum of exactly ten savings (9.1+41.1+4.5+28.5+12.9+
  9.9+7.3+3.3+6.6+5.9 = 129.1) and excludes JTBD 4's 2.0 min, so "10" and "≈129" are internally
  consistent with each other but not with the table one screen above. Every other number checked
  against `/Users/sxope/Documents/2026/Development/37.chute/docs/03-JTBD-LEDGER.md` is correct
  (all 14 per-day savings, all tiers, all JTBD ids, the 27-command CLI list matches the switch at
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/main.swift:69-96`, the drawn
  menu matches `chute finder-actions --menu` byte for byte, and the expected gate outputs
  637/151 are the measured ones).
- **Smallest fix:** either "11 of the 24 … ≈131 min/day" or footnote that JTBD 4 rides along
  with 3 and is not counted.

## LOW

### L1 — handoff/NEXT.md describes the pre-diff product

`/Users/sxope/Documents/2026/Development/37.chute/handoff/NEXT.md:4-8` says `583/583` unit,
`125/125` e2e and `13 actions · 8 drawn rows`; the tree now measures 637, 151, 14 actions. The
file warns "re-measure before quoting", but by the project's own handoff rules it is the canonical
artifact and should be regenerated in the same commit that changes the counts.

### L2 — README gate comment is stale

`/Users/sxope/Documents/2026/Development/37.chute/README.md:198` — `# 583 assertions` → now 637.

### L3 — Runbook line citations drifted

`/Users/sxope/Documents/2026/Development/37.chute/docs/11-PHASE-0-RUNBOOK.md:25` cites
`Scripts/release.sh:36` — actually `/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:32`.
Runbook 4b cites `worker/src/index.js:104` — actually
`/Users/sxope/Documents/2026/Development/37.chute/worker/src/index.js:102`. Step 2.2 cites config
"Lines 23–24" — the fields are at
`/Users/sxope/Documents/2026/Development/37.chute/site/src/lib/config.ts:24-25` (and the runbook
shows them pre-filled with "Estonia"/"Sole trader" while the file has empty strings — the excerpt
reads as current state but is the target state). Cited `License.swift:28` and `Version.swift:12`
are correct. All pasteable commands in the runbook reference files that exist
(`Scripts/deploy-site.sh`, `Scripts/notarize-setup.md`, `worker/keygen.mjs` with `new`/`mint`,
`worker/contract.test.mjs` printing the exact expected line). One nit: step 8.3's
`git clone … /tmp/homebrew-tap` fails if the directory already exists from a previous attempt.

### L4 — Checkpoint branch-create race window (TOCTOU)

`/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:72-78`:
two concurrent checkpoints producing the identical commit can both pass the `existing` check;
the loser's `git branch` then fails and chute exits 1 even though the branch exists at exactly
the right commit. Millisecond window, outcome is a spurious error message, not data loss.
Smallest fix: on `git branch` failure, re-run the `existing` comparison before failing.

### L5 — The extension's 3-second "Chute is not running" probe can mis-report (pre-existing)

`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteFinder/ChuteFinderSync.swift:186-190`:
if ChuteApp's main queue is blocked past ~3s before draining the inbox (e.g. a modal `confirm`
open from a previous destructive action while a second action is clicked), the extension posts
"Chute is not running — open Chute and try again" and the app later ALSO reports the completed
action — two surfaces and one false statement for one click. Not introduced by this diff; the
one-surface guarantee inside ChuteApp itself holds.

### L6 — Idempotence claim is second-boundary sensitive (informational)

The comment at `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/GitCommands.swift:66-70`
says an unchanged worktree checkpointed twice in the same second produces the identical commit;
in practice `commit-tree`'s committer timestamp can cross a second boundary within one stamp,
producing two branches with the same stamp and different sha suffixes (observed:
`…-131014-5257a29` and `…-131014-05dcfcc`). Both clicks succeed, which is the requirement —
only the "byte-identical" rationale is narrower than stated. No fix needed.

## Section C (stale references) — no findings

Searched `demo/gui/`, `Scripts/`, `site/`, `docs/`, `handoff/` for the old titles ("Copy Files
with Contents", "Write Clipboard Files Here", "Clean Room", "New Agent Sandbox Here") and the
removed `tints` dictionary: the only hits are historical comments and
`/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/specs/2026-08-27-landing-redesign-design.md`
(a dated spec, correctly historical). All six tapes in
`/Users/sxope/Documents/2026/Development/37.chute/demo/gui/tapes/` use current titles.
`ChuteActions.rows()` produces exactly 8 rows with unique symbols including submenu holders
(asserted in the 637-passing suite); `plainTitle`/`menuTitle`/`title(count:)` behave correctly
for the two "({n})" actions and append "…" iff `isDestructive`. `checkpoint-here` is declared
last under "Set Up for an Agent", so the holder keeps `seed-rules`' icon — asserted at
`/Users/sxope/Documents/2026/Development/37.chute/Sources/chutetests/FinderActionsSuite.swift:144-151`.

## Section E (build/tests/release) — no findings beyond the above

All three gates green as measured at the top. `bash -n` clean on all changed shell scripts.
