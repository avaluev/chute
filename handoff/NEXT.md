# HANDOFF — Chute — the canonical entry point

> Overwrite this file; do not add a second one. Dated snapshots of finished work live in
> `handoff/HANDOFF-YYYY-MM-DD-<topic>.md` and are records, not plans.

STATE: `main` · tree clean · **pushed** · counts live in ONE place: `marketing/06-FACT-SHEET.md`
§Verification. Re-derive; never copy forward.

```bash
swift build -c release && swift run -c release chutetests
cd /Users/sxope/Documents/2026/Development/37.chute && CHUTE_HEADLESS=1 ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/check-metrics.sh   # ALONE — see TRAPS
cd /Users/sxope/Documents/2026/Development/37.chute && ./demo/verify.sh && make -C demo/gui lint
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:cases && npm run check:claims
```

Green 2026-09-01: **911 unit · 144 headless · 172 full smoke · 4 metrics · 11 delivery · 19 cases
· claims · demo/gui lint.**

---

## ONE-LINE GOAL

A senior engineer clones this repo, reads for twenty minutes, and can say what it does, prove it
works, and find nothing that embarrasses them.

---

## WHAT THE PRODUCT IS

**ICP: Claude Code / Cursor users** — people whose agent already reads and writes files. Decided
by the founder 2026-08-31; it invalidated ~60% of a ledger costed for someone who copy-pastes
between a browser chat and their disk. Do not re-derive it; see `handoff/HANDOFF-2026-08-31-icp.md`.

**The Finder menu — 5 rows, 9 actions.** Every row survives one test: *does this survive a user
who has git, an OS with terminal shortcuts, and an agent with filesystem access?*

```
Copy Full Paths          9.1 min/day
Copy Files as Context   41.1 min/day    the wedge
Copy Folder Tree ▸       4.5 min/day    2 / 4 / All Levels
Add to Context Basket    8.2 min/day    the only row nothing else on the Mac ships
New File ▸              12.9 min/day    Empty Markdown / From Clipboard / Image
```

**Value, derived from `site/src/lib/cases.ts`:** Finder 75.8 · menu bar 4.9 · **app surface 80.7**
· free MIT CLI 75.3 · all 19 jobs 156.0. **Never quote 156 at a buyer** — two thirds of it is free.

---

## DONE 2026-09-01 (verified) — do not re-spend time here

Every item below was in `docs/specs/readiness-audit-FINDINGS.md`'s ranked ten.

| Fix | Proof |
|---|---|
| **LICENSE scoped to the open-core split.** Root `LICENSE` opens with a scope note; `Sources/ChuteApp/`, `Sources/ChuteFinder/` and `Resources/` carry their own all-rights-reserved `LICENSE`. README §Licence matches. | `smoke.sh` §25 — 7 new checks, perturbed to red by deleting one line from LICENSE |
| **Four hand-kept AppleScript escapes collapsed into one.** `ChuteCore/AppleScript.swift`; `FinderReveal`, `AgentCommands` (twice in one function), `ChuteFinderSync` and `Notify` all call it. **Two had drifted** — they mapped `"` → `'`, silently rewriting the user's text instead of escaping it. | `swift run -c release chutetests` |
| **`chute sessions` no longer exits 0 when Automation is denied.** A script can now tell "no sessions" from "permission denied". | `SessionCommands.swift:27` |
| **`chute seed` no longer exits 0 when every write failed.** | `FileCommands.swift:75` |
| **The appex entitlement narrowed from `/` to `~/.chute`.** Was a read-write exception on the entire filesystem for a process that writes one folder. | `Resources/ChuteFinder.entitlements:18` — **needs one manual re-test, see IN FLIGHT** |
| **`ConfirmPrompt` extracted to ChuteCore** — the destructive-action sheet's text, previously inside an `NSAlert` call no test could reach. 13 new assertions, both new guards perturbed to red. | `Sources/chutetests/ConfirmPromptSuite.swift` |
| **Dead/over-wide public API.** `SessionPhrasing.elide` deleted (zero references anywhere). `ProcessMetrics.allPIDs` and `Diagnostics.endToEndProbe` → internal. `Trial.recordPath` **stays public with a comment saying why** — it is a default-argument expression of public functions and does not compile as internal. The audit was wrong on that one. | build |
| **CI now runs the unit suite against the RELEASE build.** It ran `swift run chutetests` (debug) while every documented gate uses `-c release`; a bug that only appears under `-O` would have passed. | `.github/workflows/macos-matrix.yml:40` |
| **Marketing de-rotted, and gated.** Five assets still sold `unpack`, deleted 2026-08-31, and quoted ~90 min/day against a real 80.7. All rewritten for the ICP. `check-claims.mjs` now scans `marketing/` — it scanned only README and `docs/`, which is exactly why nothing caught it. | `npm run check:claims` |
| **Three phantom demos deleted from `site/public/media/`** — `turn-an-answer-back-into-files`, `a-clean-room-for-a-risky-agent`, `agent-rules-in-one-click` (mp4/webm/jpg) plus an orphan `checkpoint.gif`. They were **live public URLs demonstrating features the product does not have.** `check-cases.mjs` printed a `note` about them and nobody read it; it FAILS now, and posters (`.jpg`) count, which is why three survived the last sweep. | `npm run check:cases` |

**Deliberately NOT done, with the reason:** splitting `AgentCommands.swift` (audit item 9). It is
247 lines — inside this repo's own 200–400 guideline — and its five commands (open, sandbox,
ports, env, prompt) are all agent-adjacent, exactly like `FileCommands.swift` grouping new/seed/
note. Five files of 50 lines removes no complexity. Re-propose only with a concrete cost it caused.

---

## IN FLIGHT — one thing, and it needs a human at a Mac

**The narrowed appex entitlement has not been re-tested at runtime.** `Resources/ChuteFinder.entitlements:18`
went from `absolute-path.read-write = /` to `home-relative-path.read-write = /.chute/`.
`./Scripts/build-app.sh` assembles and signs clean, but only a real click proves the sandbox still
lets the extension write its request file.

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh
# then: right-click any folder in Finder → Copy Files as Context → expect the clipboard to fill
```

If it fails: the extension is registered but writing is denied. Revert that one line to
`<key>com.apple.security.temporary-exception.files.absolute-path.read-write</key>` with
`/Users/<you>/.chute/` — still vastly narrower than `/` — and re-test.

---

## THE THREE THINGS ONLY THE FOUNDER CAN DO

1. **The stopwatch.** `./demo/gui/by-hand.sh`, ~3 minutes. All six `demo/out/gui/*.json` carry
   `manual: null`. Every minute figure in the launch is an ESTIMATE until this runs, and for a
   tool sold on "here is the time you save" that is the most attackable claim in the campaign.
   `marketing/03-LAUNCH-POSTS.md` §Honesty note blocks the first post on it.
2. **The Basket test.** Three files, three folders, `~/Desktop/chute-basket-test/` → Add to
   Context Basket → Copy Basket as @mentions → paste into Claude Code. **If that is not obviously
   faster than typing three `@` paths, delete it** like the other six. Do not polish it before
   answering.
3. **Phase 0 — money.** `Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE`;
   it is not valid base64, so **every buyer's key would fail silently** and `LicenseSuite` cannot
   see it (it verifies against its own keypair). `Scripts/release.sh` now refuses to build past
   it. Then: `dig +short chutedev.com` (empty), Apple enrolment ($99), Paddle. Runbook:
   `docs/11-PHASE-0-RUNBOOK.md`. **The whole campaign is blocked on these** —
   `marketing/05-CONTENT-CALENDAR.md` §1 is the gate list.

---

## NEXT — in order, for one session

1. **The runtime re-test above**, then the three founder items.
2. **One error-handling pass (2 h).** Two silent exit-0s are fixed; sweep the remaining 26-command
   surface for empty `catch`, ignored `try?`, and `guard … else { return }` where a user is
   waiting. *Rule 4 of the measurement doctrine: a refusal is not a zero.*
3. **Continue the coverage extraction.** `ConfirmPrompt` is the proven fourth instance of the
   `StatusMenu` move. Next highest value: `SessionMenu`'s row-retitling rule
   (`SessionMenu.swift:98-162`) and `ChuteFinderSync.run`'s four-way message branch
   (`ChuteFinderSync.swift:179-212`). **Perturb each to red before believing it.**
4. **Then the texts and the JTBDs.** Re-read every user-facing string against the naming law at
   `Sources/ChuteCore/FinderActions.swift:10`. Retire the ledger rows for the six deleted jobs
   properly (struck through + dated, the way FR-06 was).

**Then, and only then, custom user actions.** `ChuteAction` is pure data and `argv()` already
substitutes `{files}`/`{dir}`, so reading `~/.chute/actions.json` is ~40 lines. But it turns an
opinionated 5-row menu into a platform, macOS already ships Automator Quick Actions and Shortcuts
for exactly this, and it means Chute executes commands the user wrote. **Design it before
building it.**

---

## TRAPS — paid for, repeatedly. Do not pay again

- **A note is not a gate.** `check-cases.mjs` printed "9 recordings no case refers to" for days.
  Three of them were videos of deleted features, publicly reachable. Nobody read the note.
- **A hand-kept list is not a gate.** `check:claims` passed for a whole day while four files told
  people to run a deleted command, because it compared against a list of retired names nobody
  updates. It asks the dispatch switch now — and it now scans `marketing/` too, which it did not,
  which is why five launch assets sold `unpack` for a day with everything green.
- **A comment is not a guard.** `CHUTE_BUFFER_DIR` said "tests only" and enforced nothing.
- **Green with zero failures can still be a broken run.** Read the tally, never the exit code.
- **A gate that proves shape passes a deleted feature.** Lint proved grammar, plan proved
  fixtures; neither asked if the thing existed.
- **Patch a total and you will be wrong.** Derive every number from `cases.ts` after the edit.
- **A passing suite says the SOURCE is right, never that the INSTALLED APP is.** `chute doctor`
  prints the build stamp for exactly this reason.
- **`check-metrics` goes red ~1 run in 3 under load, green alone.** Measured again 2026-09-01: red
  while two builds ran, 4/4 green on a quiet machine seconds later. Do NOT widen the bound; that
  is how it would stop catching the 24× error it was built for.
- **Test suites must not touch the user's data.** The basket tests cleared his real basket until
  `CHUTE_BUFFER_DIR` was added.
- **Running the full smoke blocks the founder** — it owns the clipboard for ~30 s and drives real
  Finder actions. Safe while he works: `swift build`, `swift run chutetests`, the site checks.

## DECISIONS — do not re-litigate

- **ICP is Claude Code / Cursor users.** Everything follows from it.
- **The CLI is plumbing, not a product.** It competes with free `npx repomix` and earns nothing;
  it stays MIT and stops being marketed as thirteen jobs to learn. It IS the ad — see
  `marketing/05-CONTENT-CALENDAR.md` §4.
- **A basket entry is a PATH**, not a copy of content.
- **Nothing auto-fills the basket.**
- **`Copy Folder Tree` and `New File` stay** despite the ICP logic — a pasted tree orients an agent
  without it burning context on `ls -R`. Do not re-propose deleting these.
- **The app is the product; the CLI is the proof.** The app number is 80.7; 156.0 never appears
  in front of a buyer.

## OPEN QUESTIONS FOR THE HUMAN

- The Basket: faster than typing three `@` paths, or delete it?
- The two session-switcher numbers, then cost the menu bar's flagship
  (`which-agent-is-waiting-for-you` is still `jtbd: 0`, `savedMinutes: null`, on what is now the
  only ICP-native surface in the product).
- Custom user actions: platform, or stay opinionated?
- **A Claude Code plugin/skill for `chute`** (`05-CONTENT-CALENDAR.md` §4a) — the highest-leverage
  distribution line in the campaign, and the same "is this a platform now?" question.
