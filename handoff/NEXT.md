# HANDOFF — Chute — the canonical entry point

> Written 2026-09-01 for the session that makes this repo something a professional developer
> would accept. Overwrite this file; do not add a second one. Dated snapshots of finished work
> live in `handoff/HANDOFF-YYYY-MM-DD-<topic>.md` and are records, not plans.

STATE: `main` · `242dd69` · tree clean · **pushed** · installed app stamp == HEAD
Counts live in ONE place: `marketing/06-FACT-SHEET.md` §Verification. Re-derive; never copy forward.

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/verify.sh && make -C demo/gui lint
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```

Green as of this writing: **898 unit · 165 smoke · 137 headless · 11 delivery · 19 cases · 4 metrics.**

---

## ONE-LINE GOAL

A senior engineer clones this repo, reads for twenty minutes, and can say what it does, prove it
works, and find nothing that embarrasses them.

---

## WHAT THE PRODUCT IS, after 2026-08-31

**ICP: Claude Code / Cursor users** — people whose agent already reads and writes files. This was
decided by the founder and it invalidated ~60% of a ledger costed for someone who copy-pastes
between a browser chat and their disk. Do not re-derive it; see
`handoff/HANDOFF-2026-08-31-icp.md`.

**The Finder menu — 5 rows, 9 actions.** Every row survives one test: *does this survive a user
who has git, an OS with terminal shortcuts, and an agent with filesystem access?*

```
Copy Full Paths          9.1 min/day
Copy Files as Context   41.1 min/day    the wedge
Copy Folder Tree ▸       4.5 min/day    2 / 4 / All Levels
Add to Context Basket    8.2 min/day    the only row nothing else on the Mac ships
New File ▸              12.9 min/day    Empty Markdown / From Clipboard / Image
```

**Six rows were deleted on 2026-08-31**, each for failing that test: `Open in Terminal` (macOS
ships it), `New Scratch Folder` (the agent sandboxes itself), `Move Junk to Trash` (`git status`
already lists untracked files), `Save Clipboard as Files` (the agent writes files itself),
`seed-rules` + `checkpoint-here` with their "Set Up for an Agent" parent (a category, not a job).
The CLI keeps every one of those capabilities.

**Value, derived from `site/src/lib/cases.ts`:** Finder 75.8 · menu bar 4.9 · **app surface 80.7**
· free MIT CLI 75.3 · all 19 jobs 156.0.

---

## ALREADY GOOD — do not spend the next session here

- **CI is real.** `.github/workflows/macos-matrix.yml` runs build + unit + smoke on macOS 13, 14
  and 15, assembles the app bundle, and asserts the appex's Mach-O entry point.
- **Zero dependencies.** `grep -c '.package(' Package.swift` → 0. Builds offline with Command Line
  Tools; Xcode not required.
- **The gates check magnitude, not just shape.** `Scripts/check-metrics.sh` compares against the
  real RAM and core count and against a known 500 MB allocation.
- **Guards that name themselves when they fail.** Row counts and order, the destructive-action
  invariant, the orphan-tape check, the ghost-command check, the naming invariant. Six of them
  caught real regressions during the last session, including three of mine.
- **No TODO or FIXME anywhere.** Four `ponytail:` markers, each naming its ceiling and upgrade
  path — that is a deliberate ledger, not rot.
- **LICENSE is MIT** and matches the documented open-core split.

---

## THE GAPS — measured, not guessed

### 1. Ten files have zero unit coverage, and they are the ones a buyer clicks
`Package.swift:18` — `chutetests` depends on **ChuteCore only**. Every file in `Sources/ChuteApp`
(10 of them, 415 lines in `main.swift` alone) and `Sources/ChuteFinder` is untested by the unit
suite. `smoke.sh` reaches some of it through the real binary, but no assertion can see a branch.

The pattern that already works is two files away: `StatusMenu` and `ChuteActions` are **pure data
in ChuteCore**, so a headless test reads the exact menu the app draws. Extend that, or add a
`.testTarget` — decide deliberately and write down which.

### 2. Every number on the site is an estimate
All six `demo/out/gui/*.json` carry `manual: null`. `check:cases` says so honestly, which is why
it passes. **Nothing is backed by a two-sided stopwatch.** For a tool sold on "here is the time
you save", that is the single most attackable claim.
→ `./demo/gui/by-hand.sh`, ~3 minutes, and only the founder can do it.

### 3. The menu bar's flagship has never been costed
`which-agent-is-waiting-for-you` is `jtbd: 0`, `savedMinutes: null`, and the menu bar is now the
**only ICP-native surface in the product** — which agent is waiting, zombie ports, what changed.
It has been ranked lowest all along on a number computed for the wrong buyer.
Needs two figures only the founder has: times/day he checks which agent is waiting, and how long
finding it takes without Chute.

### 4. The Basket has never been used by a human
Built, tested, installed, and unvalidated. The test: right-click three files in three folders →
**Add to Context Basket** → **Copy Basket as @mentions** → paste into Claude Code. Fixture is at
`~/Desktop/chute-basket-test/`. **If that is not obviously faster than typing three paths, delete
it like the other six.** Do not polish it before answering.

### 5. Release blockers, unchanged
`Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE`. `dig +short chutedev.com`
is still empty. Apple enrolment ($99) not done, Paddle not wired. And `Scripts/release.sh` builds
and notarises correctly but **never touches the Homebrew tap** — which is why the installed CLI
once ran 54 commits behind HEAD with no way to tell.

---

## THE TEN THINGS, RANKED — from a full readiness audit, 2026-09-01

`docs/specs/readiness-audit-FINDINGS.md` carries the evidence for each. ~13 hours total; items
1–5 are what a buyer or App Review trips over, 6–10 are what makes solo maintenance cheap.

| # | Fix | Where | Est |
|---|---|---|---|
| 1 | **LICENSE scope.** The root MIT file may grant away the PAID app's source. Add a NOTICE or per-directory LICENSE matching the documented open-core split. | `LICENSE` | 2 h |
| 2 | **`chute sessions` exits 0 when Automation is denied** — a permission failure is indistinguishable from "no sessions" to any script. | `SessionCommands.swift:10-30` | 0.5 h |
| 3 | **`chute seed` exits 0 when every write failed.** | `FileCommands.swift:69-70` | 0.5 h |
| 4 | **Narrow the Finder extension's entitlement.** It holds a read-write exception on `/`; it only ever needs `~/.chute`. Re-test that it still registers after narrowing. | `Resources/ChuteFinder.entitlements:14` | 1 h |
| 5 | **Three AppleScript-escape implementations.** Collapse into the one ChuteCore function all three call. | `FinderReveal`, `AgentCommands:39`, `ChuteFinderSync:217` | 1 h |
| 6 | **Split `AgentCommands.swift`** — five unrelated features (open, sandbox, ports, env, prompt) in one file, against the one-file-per-feature pattern the other command files follow. | `Sources/chute/Commands/` | 2 h |
| 7 | **Extract `RequestInbox`'s confirm/dry-run decision into ChuteCore**, following the proven `StatusMenu` pattern, so a headless test can read it. Highest-value piece of the coverage gap. | `ChuteApp/RequestInbox.swift` | 4 h |
| 8 | **Shrink the public API** to symbols with callers outside their own file. | `Sources/ChuteCore/` | 1 h |
| 9 | **Mint the production licence key** (`node worker/keygen.mjs new`) and verify one real key round-trips by hand. | `License.swift:28` | 1 h |
| 10 | **The two session-switcher numbers**, then cost the menu bar's flagship. | `cases.ts`, `03-JTBD-LEDGER.md` | — |

**Already fixed on 2026-09-01, do not re-spend time:** `chute basket add` now reports what
actually happened rather than what it attempted (it printed "added 3" on failure and "added 1" on
a duplicate); `Scripts/release.sh` now REFUSES to build while `License.swift:28` is the
placeholder — that placeholder is not valid base64, so every buyer's key would have failed
silently, and `LicenseSuite` structurally cannot catch it because it verifies against its own
generated keypair; README's stale `chute buf` row is now `chute basket`.

**The audit also confirmed these are already done** — do not re-audit them: the
`CHUTE_BUFFER_DIR` guard, the hooks check that ended the false "all 9 passed", onboarding's
premature done-flag, the dead `openSetup`, README's `unpack` references, and smoke.sh's `set -e`
footgun.

---

## NEXT — in order, for one session

1. **Close the coverage gap (half a day).** Move the remaining decision logic out of
   `Sources/ChuteApp/main.swift` into ChuteCore as pure functions, following `StatusMenu`. Target
   the branch-carrying ones: menu assembly, the request-inbox dispatch, and the deliver/notify
   paths. Every function moved gets a headless assertion. **Perturb each to red before believing
   it.**
2. **One error-handling pass (2 h).** Find every silent failure — empty `catch`, ignored `try?`, a
   `guard … else { return }` where a user is waiting, and any command exiting 0 on failure. A
   prior audit counted 8 CLI commands failing silently at exit 0; verify and fix. **Rule 4 of the
   measurement doctrine: a refusal is not a zero.**
3. **Shrink the public API to what has callers (1 h).** ChuteCore is a library; every `public`
   symbol with no caller outside its own file is surface a maintainer keeps working for nobody.
4. **Split `AgentCommands.swift` (1 h).** It is four unrelated features in one file — ports,
   sandbox, open, env. Named as a problem in two audits and still true.
5. **Then the texts and the JTBDs**, once the code is settled: re-read every user-facing string
   against the naming law at `Sources/ChuteCore/FinderActions.swift:10` and the invariant test in
   `FinderActionsSuite`. Retire the ledger rows for the six deleted jobs properly (struck through
   + dated, the way FR-06 was), so the docs record decisions rather than absences.

**Then, and only then, the product question:** custom user actions. The founder proposed it and
the model already supports it — `ChuteAction` is pure data and `argv()` already substitutes
`{files}`/`{dir}`, so reading extra actions from `~/.chute/actions.json` is ~40 lines. But it turns
an opinionated 5-row menu into a platform, macOS already ships Automator Quick Actions and
Shortcuts for exactly this, and it means Chute executes commands the user wrote. **Design it
before building it.**

---

## TRAPS — paid for, repeatedly. Do not pay again

- **A hand-kept list is not a gate.** `check:claims` passed for a whole day while four files told
  people to run a deleted command, because it compared against a list of retired names nobody
  updates. It asks the dispatch switch now.
- **A comment is not a guard.** `CHUTE_BUFFER_DIR` said "tests only" and enforced nothing.
- **Green with zero failures can still be a broken run.** A deleted action left `run_action
  clean-junk` in `smoke.sh`; under `set -e` it aborted at line 94 — exit 1, no FAILs, no summary.
  Read the tally, never the exit code.
- **A gate that proves shape passes a deleted feature.** `demo/gui check` planned full recordings
  for three retired rows: lint proved grammar, plan proved fixtures, neither asked if the thing
  existed.
- **Patch a total and you will be wrong.** The capability map claimed 82.1 while its own row table
  summed to 89.0. Derive every number from `cases.ts` after the edit.
- **A passing suite says the SOURCE is right, never that the INSTALLED APP is.** `chute doctor`
  prints the build stamp for exactly this reason. Check it before debugging anything.
- **Test suites must not touch the user's data.** The basket tests cleared his real basket until
  `CHUTE_BUFFER_DIR` was added.
- **Running the full suite blocks the founder** — it owns the clipboard for ~30s and drives real
  Finder actions. Safe while he works: `swift build`, `swift run chutetests`, the site checks.
  Batch the rest and ask.

---

## DECISIONS — do not re-litigate

- **ICP is Claude Code / Cursor users.** Everything follows from it.
- **The CLI is plumbing, not a product.** It competes with free `npx repomix` and earns nothing;
  it stays MIT and stops being marketed as thirteen jobs to learn.
- **A basket entry is a PATH**, not a copy of content — hence no size cap, rows that name the
  file, contents read fresh at hand-over, "— missing" when a file is gone.
- **Nothing auto-fills the basket.** Automatic filing is what made the old Recent Copies read as
  hardcoded.
- **`Copy Folder Tree` and `New File` stay** despite the ICP logic — a pasted tree orients an
  agent without it burning context on `ls -R`. Do not re-propose deleting these.
- **`check-metrics` goes red ~1 run in 3 under heavy load, green alone.** Do NOT widen the bound;
  that is how it would stop catching the 24× error it was built for. Re-run on a quiet machine.

## OPEN QUESTIONS FOR THE HUMAN

- The Basket: faster than typing three `@` paths, or delete it? (Gap 4 above.)
- The two session-switcher numbers. (Gap 3.)
- Custom user actions: platform, or stay opinionated?
