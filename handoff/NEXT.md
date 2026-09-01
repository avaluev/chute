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

**Also done 2026-09-01, second pass — performance, size and Apple hardening:**

| Fix | Proof |
|---|---|
| **`ProjectRoot.of` stopped spawning `git`.** It ran `git rev-parse --show-toplevel` per call; what that returns is the nearest ancestor holding `.git`, which is a few `stat`s. **bundle 102.7 → 24.7 ms (4.2×); tokens 184.1 → 23.5 ms (7.8×)** — tokens paid the spawn twice. | `ProjectRootSuite`, perturbed red on the worktree case |
| **`strip -x` before signing: 3.3 MB → 2.4 MB bundle, 1.6 MB DMG.** `-x` keeps globals so the appex's `_NSExtensionMain` survives — asserted in `build-app.sh`, not assumed. | `du -sh dist/Chute.app` |
| **The app signed with `--options runtime` and NO entitlements** — the hardened runtime blocks every Apple Event, so `osascript` would have failed in the NOTARISED build only. `Resources/Chute.entitlements`. | `build-app.sh` fails without it; perturbed |
| **`TokenEstimate` counted grapheme clusters.** UTF-8 bytes are what a BPE tokenizer is billed by, and are not a Unicode walk. | `CoreSuites` |
| **Two unbounded C-string reads** in `ProcessMetrics` — `p_comm` was read off a raw pointer into a 17-byte stack tuple, bounded only by a NUL the kernel is trusted to write. | `chute ports` / `chute sessions` still name processes correctly |
| **`uninstall.sh` never cleaned `/Applications`** — the only path a stranger takes, since that is where the DMG says to drag it. It removed nothing and printed "Chute removed." | exercised in the from-scratch reinstall above |
| **The bundle-size claim was hand-typed into eight files** and had been wrong since the bundle hit 3.3 MB. `build-app.sh` now fails if the fact sheet and `du` disagree. | perturbed to 9.9 MB → red |

**Deliberately NOT done, with the reason:** splitting `AgentCommands.swift` (audit item 9). It is
247 lines — inside this repo's own 200–400 guideline — and its five commands (open, sandbox,
ports, env, prompt) are all agent-adjacent, exactly like `FileCommands.swift` grouping new/seed/
note. Five files of 50 lines removes no complexity. Re-propose only with a concrete cost it caused.

---

## IN FLIGHT — nothing

The narrowed appex entitlement is **proved at runtime**, not just at build time. `uninstall.sh`
deleted `~/.chute` at 12:51 on 2026-09-01; the SANDBOXED extension recreated it and wrote
`~/.chute/extension-loaded.txt` at 12:52, from inside its sandbox, under
`home-relative-path.read-write = /.chute/` and nothing wider. `chute doctor` on the fresh install:
**9 of 10 checks pass**, the tenth being the agent-status hooks, which Chute deliberately never
writes (see below).

**The Mac now runs a from-scratch DMG install.** `~/Applications/Chute.app` and `~/.chute` were
removed, the extension unregistered, the app rebuilt, `dist/Chute-0.2.0.dmg` (1.6 MB) created and
mounted, and `Chute.app` copied to **`/Applications`** — the location the DMG actually tells a
customer to use, and the one `uninstall.sh` could not clean until today. Installed stamp
`84da70d` == HEAD.

**One thing the founder must paste back.** The uninstall removed Chute's hook blocks from
`~/.claude/settings.json` (backup: `~/.claude/settings.json.chute-backup-20260901-065152`). Until
they are back, the menu-bar badge stays dark and every session reads as idle:

```bash
/Applications/Chute.app/Contents/MacOS/chute hooks snippet
# merge the "hooks" object into ~/.claude/settings.json (or via Claude Code's /hooks), then:
/Applications/Chute.app/Contents/MacOS/chute hooks status
```

Chute does not write that file, here or anywhere. That is a standing decision, not an omission.

## THE GTM MATERIAL — where each thing lives

| File | What it is |
|---|---|
| `marketing/01-POSITIONING.md` | ICP, wedge, the motion-vs-judgement line every asset sits on |
| `marketing/02-LANDING-COPY.md` | the words |
| `marketing/03-LAUNCH-POSTS.md` | X, Show HN, PH, Reddit — post-for-post |
| `marketing/04-PRICING-AND-DEMO.md` | price rationale, the 20-second demo shot list |
| `marketing/05-CONTENT-CALENDAR.md` | the 30-day launch spike, with a blocking pre-flight gate |
| `marketing/06-FACT-SHEET.md` | **every number, and the command that proves it.** One place. |
| `marketing/07-WEBSITE.md` | site rebuild, the 10-shot screenshot plan, SEO/GEO/AIO |
| `marketing/08-LINKEDIN.md` | 12 posts, full text — the 90-day compounding asset |

**05 is the spike, 08 is the engine.** They share no copy on purpose: two copies of a claim drift
the moment one is edited.

## RESEARCH — five sourced documents, read before writing any launch copy

Five files, 3,171 lines, every claim tagged `[VERIFIED]` / `[SECONDARY]` / `[UNVERIFIED]`:
`competitors.md`, `gtm-tactics.md`, `solopreneur-ai-utilities.md`, `seo-geo-aio.md`, `linkedin.md`.
The seven findings that change decisions:

1. **Repo Prompt, the closest paid analogue, stopped charging 2026-05-27 and open-sourced
   2026-06-13.** Founder: *"increasingly challenging to convince someone that they should pay me
   $15 a month … when they can just prompt their agent."* He also joined OpenAI, so it is a
   founder exit with a market justification attached. **Repo Prompt sold judgement — which files
   matter. Chute sells motion — bytes to the clipboard. Judgement is what agents ate.** Keep every
   asset on the motion side of that line.
2. **`npx skills add <owner/repo>` reaches 17 agents from one repo**, claude-code and cursor among
   them — Chute's entire ICP, one artifact. This is the highest-leverage distribution move
   available and it is roughly a day's work. See `marketing/05-CONTENT-CALENDAR.md` §4a.
3. **$19 is in an empty price band.** MAS clusters $3–$10, direct-sold clusters $25–$59, and
   $15–$19 is unoccupied. The two closest comparables in kind — native, solo, one-time, AI
   audience — both chose **$29**. Liftable: VoiceInk tiers by **Mac count, not features**
   ($25/1, $39/2, $49/3, identical product). Chute's version: $19 one Mac / $29 three Macs.
   **Founder's call.** Also: 7-day trial rather than 14 (value lands in ten seconds), and the
   field's standard refund wording is "14-day money-back guarantee, no questions asked" — 30 days
   appears only above $79, and the site currently offers 30.
4. **Eight of eight competitor pages use a static screenshot hero. Not one uses a video.** The
   site opens with an autoplaying mp4. The recordings stay — they are stopwatch races, which is
   evidence — but they move below the fold. `marketing/07-WEBSITE.md` Part 1.
5. **`"copy files for llm"` returns zero autocomplete suggestions.** The real demand cluster is
   **"claude code context window full"** — people search the symptom, not the category. Write to
   the symptom.
6. **AlternativeTo has a 7-day account-age gate before you can submit.** Create the account today;
   it is 90 seconds and everything else in SEO can wait behind it.
7. **The $19-over-free answer is Downie** — a $19.99 one-time GUI over free `yt-dlp`, sold for
   years to people who know `yt-dlp` exists. Frequency, not capability. Never market on packing
   quality: repomix (28,148★) wins that outright and is free.

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

## THE RATCHET — read this before deferring a coverage finding again

`Scripts/check-untested-logic.sh`, wired into `smoke.sh` §26 and therefore into CI.

`chutetests` links ChuteCore only. `Sources/ChuteApp` and `Sources/ChuteFinder` have **zero** unit
coverage. Two audits counted the decision points there and both named `ChuteFinderSync.run` as the
highest-value extraction. **Both times it was ranked and deferred, including by me on
2026-09-01.**

On 2026-09-02 the founder selected 34 items in a Python project, chose **Copy Folder Tree ▸ All
Levels**, and got thirteen `.pyc` files. One line:

```swift
controller.selectedItemURLs()?.first ?? controller.targetedURL()
```

It reads correctly. It is wrong for every multi-selection — `__pycache__` sorts first. 917
assertions and 144 end-to-end checks were green, and not one of them could see that line.

The rule that stops it recurring: **a file in those two targets may shrink freely and may never
grow.** Baseline in `Scripts/untested-logic.txt`, currently **171 across 11 files**. A red run is
not fixed by re-recording; it is fixed by moving the decision into ChuteCore as a pure function
and testing it — the move `StatusMenu`, `ActionRequest`, `OnboardingSteps`, `ConfirmPrompt` and
`FinderTarget` have all now made. Perturbing the old one-liner back takes ChuteFinderSync 20 → 22
and goes red.

**Next two extractions, in order**, both already sized by the audit: `SessionMenu.swift` (29 — the
largest remaining) and `main.swift` (43, mostly wiring, but not all).

## TRAPS — paid for, repeatedly. Do not pay again

- **A finding you wrote down and ranked is not a guard.** `ChuteFinderSync.run` was named as
  untested by two audits and deferred by both, and the founder found the bug. If a finding is real
  enough to rank, it is real enough to deserve a gate that makes it impossible to grow — even when
  the fix itself waits.
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
