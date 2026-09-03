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

Green 2026-09-04: **1,032 unit · 150 headless smoke · 81 acceptance · ratchet 172/172 ·
19 cases · claims · paddle · next build · lint 0 errors · tsc.** All of it, no exceptions.
`ProcessMetrics`' 5 ms budget goes red under load and green alone — the code is untouched, do
not widen it. See TRAPS.
Full smoke MEASURED 2026-09-04: **177/178** — the one failure is `check-metrics`' 500 MB
magnitude check, which the TRAPS below already document as red under load; run alone seconds
later it measured 506 MB against a 500 MB allocation, 4/4. 178 is now a counted number, not a
derived one.

Also in the gate now: `node worker/contract.test.mjs` (release.sh and CI) and `npm run lint`
(deploy-site.sh). `swift run chutetests` was RED on 2026-09-03 before anything was touched —
see DONE 2026-09-03, first row.

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

> Finished work from 2026-09-01/02 moved to `handoff/HANDOFF-2026-09-02-shipping-and-gtm.md`.

## DONE 2026-09-03/04 (verified) — the icon, the menu bar, and the hooks handover

**The app icon is a parachute.** `Scripts/make-icon.swift` redrawn; `Resources/Chute.icns`,
`site/src/app/favicon.ico` and `brand/cards.py:draw_mark()` all regenerated from it. One command
does all three now — a mark kept in three hand-regenerated places is how a launch ships three
logos:

```bash
swift Scripts/make-icon.swift
```

**The finding, and it is the reusable one.** A design panel scoring craft, legibility and brand
ranked four candidates and put a lit-slot mark FIRST and the parachute LAST. A blind recognition
test — four unprimed viewers per image, neutral filenames, no product context, "what object is
this" — inverted it: every "document into a horizontal slot" mark read as a **paper shredder**
(4/4 at 128px for one, 4/4 at 32px for the other). The parachute read 4/4 · 5/5 · 4/4 · 4/5 at
128 · 64 · 32 · 16. A craft panel cannot catch a semantic misread, because a judge who has been
told what the product is can no longer un-know it. Full ledger in
`docs/specs/audit-2026-09-03-FINDINGS.md` §Icon redesign.

**Old icon:** 880px body on a 1024 canvas (Apple's grid is 824), no cast shadow, circular
corners. **New:** 14/28/54/104/206/412/824 at 16→1024, exact against Notes.app, shadow within 3
alpha levels at every size.

**`--naming` stays (audit P10).** Kebab for the bare CLI, underscore for the Finder menu: two
surfaces, two conventions, one binary. The defect was that it was in no help text. Fixed at
`Sources/chute/main.swift:16`; reason recorded at
`Sources/chute/Commands/FileCommands.swift:22`.

**`Scripts/build-app.sh` linked a stale object.** It globbed
`.build/release/ChuteCore.build/*.o`; SwiftPM never deletes the object of a renamed source, so
`TerminalAdapter.swift.o` sat beside `TerminalAppAdapter.swift.o` and the appex died on
`ld: 7 duplicate symbols`. Only reproduces with a warm `.build` across that rename, which is why
it survived — a cold clone builds fine. Now one object per source that still exists.

**The bundle is 2.8 MB, not 2.4.** The icns is 755 KB against 359 KB: ten natively-drawn slices
with real gradients. `build-app.sh` fails if `marketing/06-FACT-SHEET.md` disagrees, and it no
longer does. Every present-tense claim of 2.4 MB was updated; the historical ones (the changelog,
the LinkedIn `strip -x` posts) were deliberately left, and "2.4 MB" was deliberately NOT added to
the forbidden-claims table — the changelog renders it truthfully and the gate would fail on it.

**The menu bar carries the mark.** It was the SF Symbol `arrow.down.to.line` — the generic
download arrow `brand/tokens.json` says the mark must not be. `Sources/ChuteApp/MenuBarMark.swift`
draws it as a template image (alpha only; macOS tints it). Apple ships no parachute symbol —
checked. The first four drafts read as a HOT AIR BALLOON, because a balloon is a dome over a box
with short ropes; a parachute is a wide canopy, a small load, and a long steep drop. Blind test:
4/4 parachute, 0/4 balloon.

**`chute hooks merged` — one command instead of JSON you merge by hand.** The menu row used to
copy the raw `"hooks"` object. The founder pasted it back twice asking what it was, which is the
right reaction to a wall of shell with no destination, aimed at a 33 KB settings file that already
had 11 hooks from another tool in it. Chute still never writes `~/.claude/settings.json` — the
2026-08-27 rule stands. It computes the merged file and PRINTS it; the command it hands you does
the write, staged through `mktemp`, backup first, `&&` between every step.

**THREE FALSE PASSES, all found by perturbing:**
1. The first merge test was vacuous — the fixture already carried Chute's blocks, so the append
   path never ran and `blocks = [...]` (the exact bug) left the suite green.
2. `Scripts/smoke.sh`'s `HOME="$T"` isolation did NOTHING. `NSHomeDirectory()` reads the password
   database and ignores `$HOME`. All three isolated cases were reading the real
   `~/.chute/sessions`; "resume with no live session" passed only because the machine had no hook
   records, and failed the hour they were wired. `Sources/ChuteCore/Home.swift` now resolves
   `.chute` state where `$HOME` wins.
3. `nm -u … | grep -q` under `pipefail` reported the appex entry point missing from a binary that
   has it — `grep -q` exits on match, `nm` dies on the closed pipe. Same shape backed `has`/`hasnt`
   in smoke.sh and acceptance.sh: ~230 assertions that could flip at random. All here-strings now.

**Install and build now tell the truth.** `install.sh` installs over whatever copy exists rather
than always `~/Applications` (the founder's was in `/Applications`, so a "successful" install left
the old app running — a whole exchange was spent on "I see no change"). `$CHUTE_APP_DIR` overrides
it, because uninstall clears both folders and a reinstall would otherwise relocate the app.
`build-app.sh` names any installed copy whose COMMIT differs from the build's — not the timestamp,
which fired after every rebuild and taught you to ignore it.

**Verified end to end 2026-09-04:** uninstall leaves nothing (both app folders, `~/.chute`, the
CLI symlink, the appex registration, legacy Services) and correctly KEEPS the trial file, the
Homebrew CLI and every foreign hook. Cold clone-equivalent build + install: 39s. `chute doctor`
10/10.

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
| `marketing/09-APPLE-AND-DISTRIBUTION.md` | **the Apple decision, settled.** Selling ≠ delivering; the Gatekeeper wall in clicks; the Homebrew cask deadline; the arithmetic |
| `marketing/10-LINKEDIN-SHIPPING.md` | 6 posts — the shipping-wall arc. Interleave with 08, do not batch |
| `marketing/11-BUILDING-WITH-AGENTS.md` | **the expertise asset.** How this was built: 5 ways a green suite lied, the ratchet, 7 rules. Rendered at `/building-with-agents` from this one file |

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
3. **Apple enrolment — START IT BEFORE SLEEPING.** It is the only blocker with a 24–48 h human
   review queue, so every hour it is not started is an hour added to the launch date.
   <https://developer.apple.com/programs/enroll/>, Individual / Sole Proprietor,
   `docs/11-PHASE-0-RUNBOOK.md` §STEP 1. The reasoning is settled in
   `marketing/09-APPLE-AND-DISTRIBUTION.md` — **do not re-litigate it**, and in particular do not
   re-open "ship a cask instead", which stopped being possible on 2026-09-01.
4. **Phase 0 — the rest of the money.** `Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE`;
   it is not valid base64, so **every buyer's key would fail silently** and `LicenseSuite` cannot
   see it (it verifies against its own keypair). `Scripts/release.sh` now refuses to build past
   it. Then: `dig +short chutedev.com` (empty), Apple enrolment ($99), Paddle. Runbook:
   `docs/11-PHASE-0-RUNBOOK.md`. **The whole campaign is blocked on these** —
   `marketing/05-CONTENT-CALENDAR.md` §1 is the gate list.

---

## NEXT — in order, for one session

1. **The runtime re-test above**, then the three founder items. Then one full (non-headless)
   `./Scripts/smoke.sh` on a quiet machine: the fact sheet says 178 and that number is derived
   (173 + 5 new cases), not measured.
2. ~~One error-handling pass~~ — **done 2026-09-03**, see the findings file. Three LOWs left
   open there (M18, L12, L13) with reasons; P10 (`--naming`) needs a decision, not work.
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
- **A test fixture that unlinks its own binary dies.** The kernel SIGKILLs a copied binary the
  moment its file is gone (measured 2026-09-03, every copy method, every deletion method); a
  test built on it is red 4 runs in 10 and looks like a race. Prove the reader on a live pid.
- **`cd` persists across shell calls, and a script run from the wrong directory prints nothing.**
  `./Scripts/smoke.sh` from `site/` produced zero output and zero error. Absolute paths, always.
- **Running the full smoke blocks the founder** — it owns the clipboard for ~30 s and drives real
  Finder actions. Safe while he works: `swift build`, `swift run chutetests`, the site checks.

- **Judging an icon on craft cannot catch a semantic misread.** Before committing to any mark,
  copy it to neutral filenames in a neutral directory and ask four viewers, cold, "what object is
  this". It takes minutes. Skipping it cost an hour here: two marks were fully polished before the
  test said both read as paper shredders. Any future Chute mark in the "document meets a
  horizontal slot" family is dead on arrival — do not re-derive it.
- **`swift run chutetests | tail` exits 0 with a test failing** — the pipe reports `tail`'s status.
  Read the tally line, never the exit code.
- **`ProcessMetrics › the listing costs N ms` fails under load.** A 5 ms budget, 0.88 ms on a quiet
  machine, 6.4-7.1 ms while node and headless Chrome eat three cores. Not a regression — check
  `git status Sources/ChuteCore/ProcessMetrics.swift` first. Do NOT loosen the threshold; it exists
  to catch the devname-cache regression.

## DECISIONS — do not re-litigate

- **ICP is Claude Code / Cursor users.** Everything follows from it.
- **The CLI is plumbing, not a product.** It competes with free `npx repomix` and earns nothing;
  it stays MIT and stops being marketed as thirteen jobs to learn. It IS the ad — see
  `marketing/05-CONTENT-CALENDAR.md` §4.
- **A basket entry is a PATH**, not a copy of content.
- **Nothing auto-fills the basket.**
- **`Copy Folder Tree` and `New File` stay** despite the ICP logic — a pasted tree orients an agent
  without it burning context on `ls -R`. Do not re-propose deleting these.
- **The mark is the parachute**, decided 2026-09-03 by blind recognition, not by taste. "Chute"
  is the word and an airdrop is the tagline. Do not re-open it without running the same test.
- **`--naming` keeps two different defaults** — kebab in the terminal, underscore from Finder.
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
