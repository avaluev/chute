# Fact sheet — every claim, and the command that proves it

**Measured 2026-09-08. Re-measure before quoting; never copy a number forward.**

> This file went stale within four hours of being written: it said `0.1.0` while the build said
> `0.2.0`. That is not an argument against the file, it is the argument for it — the version was
> wrong in one place that names the command to check, instead of wrong in eleven that do not.
>
> The FALSE table at the bottom is **enforced**: `site/scripts/check-claims.mjs` parses it and
> fails the deploy if any of those strings appears on a rendered page. Strike a row through with
> `~~…~~` when it stops being false and enforcement drops it on the next run.

This file exists because three false claims reached the live site: "328 KB" (the app is 3.0 MB),
"28 commands" (there are 25), and unit-test counts that disagreed between the README and the
handoff. A number in marketing copy with no command beside it is a number that will be wrong
within a fortnight.

Rule: **if a claim is not in this table, do not publish it.** If a claim here is stale, re-run its
command and update this file first, then the copy.

---

## Product

| Claim | Value | Prove it |
|---|---|---|
| App bundle size | **3.1 MB** | `du -sh dist/Chute.app`. Was 2.9 MB until 2026-09-08's menu-bar redesign: `SessionDot`, `ProjectName`, `PathAbbrev` and `InlineCode` all moved into (or were newly written in) `Sources/ChuteCore/`, which every one of the three binaries links — code that shipped once now ships three times, and making an untestable thing testable has been worth those bytes every time so far. |
| CLI commands | **26** | `chute help \| grep -cE '^  [a-z]'` |
| Finder actions | **9**, drawn as **5 rows** | `chute finder-actions --menu` |
| External dependencies | **0** | `grep -c '.package(' Package.swift` → 0 |
| Lines of Swift | **14,438** | `find Sources -name '*.swift' \| xargs wc -l \| tail -1` — up from 12,542 on 2026-09-01: the menu-bar redesign added `SessionDot.swift`, `ProjectName.swift`, `PathAbbrev.swift` and `InlineCode.swift`, plus their suites, and work landing in `Sources/` after this pass adds more. **This number moves under you while `Sources/` has an active session in it — re-run the command, do not trust this digit alone.** |
| Minimum macOS | **13 Ventura** | `grep -o 'macOS(.v[0-9]*)' Package.swift` |
| Architecture | **arm64 only** | `lipo -info dist/Chute.app/Contents/MacOS/ChuteApp` → `Non-fat file: … architecture: arm64`. `Scripts/build-app.sh` runs a plain `swift build -c release` with no `--arch` flags, so it only ever produces the host machine's architecture — there is no universal-binary step anywhere in this repo. Do not claim Intel support until one exists. |
| Version | **0.2.1** | `chute --version` |
| Homebrew | `brew install avaluev/tap/chute` | `brew test avaluev/tap/chute` |

## Privacy — the strongest claim, and the most precise

| Claim | Value | Prove it |
|---|---|---|
| Network code in Chute | **None** | `grep -rn 'URLSession\|NSURLConnection' Sources/` → 0 results |
| Telemetry / analytics | **None** | `grep -rniE 'analytic\|telemetry\|track' Sources/` → 0 results |
| Account required | **No** | there is no sign-in surface anywhere in the app |
| Licence check | **None — deleted 2026-09-08** | `find Sources -iname 'License.swift' -o -iname 'TrialState.swift'` → nothing. Chute was $19 with an offline Ed25519 signature check for eleven days; the check, the trial clock and the Worker that minted keys were removed, not disabled, when Chute went free and MIT |
| Launch daemon / background service | **None** | `ls ~/Library/LaunchAgents \| grep -i chute` → empty |

**The precise phrasing, and it is better than "offline":**

> Chute contains no network code at all. One command, `chute gist`, uploads — and it does that by
> shelling out to your own `gh`, using your own GitHub credentials, on the files you name, after
> redacting keys and tokens. Chute itself never opens a socket.

Do **not** say "nothing is uploaded, ever" — `gist` uploads, on request. The precise version is
more credible than the absolute one, and it survives someone reading the source.

## Verification

| Gate | Result | Command |
|---|---|---|
| Unit assertions | **1,281 passed** | `swift run -c release chutetests` |
| Untested decision points | **138** (baseline 138, across 11 files) — never allowed to grow | `./Scripts/check-untested-logic.sh` |
| End-to-end, headless | **178 passed, 0 failed** | `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` |
| End-to-end, full | needs Chute.app actually running, else the app-liveness check fails on its own — not a number to quote from a machine with no GUI session | `./Scripts/smoke.sh` |
| Menu-item acceptance | **81 checks** — every Finder action against a hostile tree | `./Scripts/acceptance.sh` |
| Metrics plausibility | **4 checks** — magnitude, not shape | `./Scripts/check-metrics.sh` |
| Terminal tapes | **16** (12 hand-written, 4 generated from cases.ts) | `ls demo/tapes/*.tape \| wc -l` |
| GUI tapes | **5** hand-written | `ls demo/gui/tapes/*.sh \| wc -l` |
| Demo delivery pipeline | **12 checks** | `./demo/gui/selftest.sh` |
| Case data | not re-derived this pass — `site/` is owned by a concurrent session | `cd site && npm run check:cases` |
| Site routes | not re-derived this pass — `site/` is owned by a concurrent session | `cd site && npx next build` |
| CI | macOS 13, 14, 15 | `.github/workflows/macos-matrix.yml` |

## Distribution and Gatekeeper — measured 2026-09-02

| Claim | Value | Prove it |
|---|---|---|
| Gatekeeper verdict on the app | **`rejected`** | `spctl -a -vv dist/Chute.app` → `rejected`, `origin=Chute Local Dev` |
| Signing identity | **self-signed, local only** | `security find-identity -v -p codesigning` → one identity, `"Chute Local Dev"` |
| Apple Developer Program | **not enrolled** | no `Developer ID Application:` line in the output above |
| Apple Developer Program cost | **$99/yr** | developer.apple.com/programs |
| Break-even math | **retired 2026-09-08** — there is no price left to divide $99 by; Chute is free and MIT | n/a |
| Steps for a stranger to open the unsigned app on macOS 26 | **6, plus a password** | walked and recorded; see `docs/APPLE-AND-DISTRIBUTION.md` |
| Homebrew ends support for casks failing Gatekeeper | **2026-09-01** | `Homebrew/brew` issue #20755 |
| The free CLI installs with no Apple involvement | **True** | `brew install avaluev/tap/chute` — a formula, built from source, never quarantined |

**The precise phrasing.** Say *"the CLI installs from source through Homebrew and never meets
Gatekeeper"*. Do **not** say the app is notarised, signed by Apple, or that it opens without a
warning — `spctl` says otherwise, and `site/scripts/check-claims.mjs` asks `spctl` directly rather
than matching a word, so this row retires itself the moment the verdict changes.

## Commercial

**There is no Commercial section any more.** Chute was $19 with a 14-day trial for eleven days;
that product was withdrawn 2026-09-08 — `Sources/ChuteCore/License.swift` and `TrialState.swift`
were deleted, not disabled, and `Scripts/smoke.sh` now fails the build if `isUnlocked`, `Trial.` or
`License.` reappears anywhere in `Sources/`. There is no price, no trial and no refund to state a
value for. See the row directly below this one for the exact banned phrasing.

| Claim | Value | Prove it |
|---|---|---|
| Price | **None. Free and MIT, all of it.** | `LICENSE` — plain MIT text, no scope preamble |
| CLI | **Free forever, MIT** — `brew install avaluev/tap/chute` | `brew test avaluev/tap/chute` |

## Time saved — use these, never round them up

From `docs/03-JTBD-LEDGER.md`. Every figure is `frequency × (manual seconds − Chute seconds)`.

| Job | Times a day | Saves |
|---|---|---|
| Files + contents into a prompt | 17 | **41.1 min/day** |
| Break work into 15-minute tasks | 8 | 15.6 min/day |
| Keys from Keychain into `.env` | 7 | 13.4 min/day |
| Clipboard straight into a file | 25 | 12.9 min/day |
| Seed agent rule files | 7 | 9.9 min/day |
| File paths into a prompt | **32** | 9.1 min/day |

`unpack` (JTBD 9, "an answer back into real files", 28.5 min/day) is gone as of 2026-08-31 — see
`docs/specs/move-5-delete-unpack.md` — so it no longer appears above or in either total below.
Retired, not merely undersold: neither the CLI nor the Finder menu can do this job any more.

**Headline: ~80 minutes a day.** That is the app surface total — Finder 75.8 + menu bar 4.9 =
80.7 min, derived from `site/src/lib/cases.ts` — rounded down per this section's own rule. The
ledger supports ~156.0 min/day across all 19 jobs, but 75.3 of that is the free MIT CLI, and a
paid page must not quote a number two thirds of which the buyer already has for nothing.

The app-surface figure moved twice on 2026-08-31 and both moves were downward-honest: four Finder
rows were deleted (they solved problems a Claude Code user does not have), and JTBD 22 moved from
the free CLI column to the paid Finder one when `Add to Context Basket` became a row. It is now
the only number here that a buyer experiences as one person.

Two figures need care:
- **"Which agent is waiting" has no minutes figure and must not be given one.** Its cost is
  attention, not seconds. Say so.
- **Checkpoint** carries "+~20 min/day risk-adjusted" in the ledger. Publish the mechanism, not
  the adjusted number: *"it snapshots before the agent runs without touching your worktree."*

## Words that are banned in copy

*seamless · powerful · revolutionary · supercharge · effortlessly · unlock · elevate · game-changing
· blazing fast · 10x*

And the structural rule that matters more than any word list: **pain before product.** No section,
post or page opens with a command name.

## Claims that are currently FALSE and must not be used

| Never say | Why | Say instead |
|---|---|---|
| "turn agent output back into files" | The `unpack` command was deleted 2026-08-31 — a Claude Code user's agent writes its own files. This exact sentence survived in the site's `<meta name="description">` and OpenGraph description until 2026-09-01, because `check-claims.mjs` stripped tags before reading. It reads metadata now. | Nothing — the job no longer exists |
| "Paste an answer back" | Same deleted command, the hero's half-sentence version of it. | "Select the folders. Right-click once." |
| "$19" | Chute is free and MIT. It was $19 with a 14-day trial for eleven days, and that product was withdrawn on 2026-09-08 — the Worker, the licence check and the trial clock were deleted, not disabled. A rendered page may only say this as dated history, never as a price. | "Free and MIT" |
| "14-day trial" | There is no trial. Nothing locks, so nothing has to be unlocked. | "Free and MIT — no trial, no key, no account" |
| "30-day refund" | Nothing is sold, so nothing can be refunded. | omit entirely |
| "328 KB" | The app is 2.9 MB. This was live on the site until 2026-08-28. | "2.9 MB, no dependencies, no launch daemon" |
| "2.5 MB" | Was true, then was not: the bundle reached **3.3 MB** unnoticed because eight files carried a hand-typed copy of this number and nothing checked any of them. `strip -x` before signing brought it to **2.4 MB** on 2026-09-01, and `Scripts/build-app.sh` now FAILS if this row and `du -sh dist/Chute.app` disagree. It went to **2.8 MB** on 2026-09-03: the redesigned icon is 755 KB against the old one's 359 KB, which is what ten natively-drawn slices with real gradients cost. It went to **2.9 MB** on 2026-09-04, when the ratchet moved `SessionCommand`, the hex parse and the Finder dispatch rule out of the two untestable targets and into ChuteCore — which is linked into all three binaries, so code that shipped once now ships three times. 112 KB is what that coverage costs, and it was a deliberate trade. It touched **3.0 MB** for an hour on 2026-09-04 — `AboutText` and the rewritten Settings copy, linked into all three binaries as everything in ChuteCore is — and came back to **2.9 MB** the same afternoon when the session status was removed and its dead code deleted. It went to **3.1 MB** on 2026-09-08: `SessionDot`, `ProjectName`, `PathAbbrev` and `InlineCode` all landed in ChuteCore the same day, for the same reason as every move above — a bug that shipped invisible (the traffic-light dot) or silently inconsistent (the project name) had to become testable, and testable lives in the target every binary links. NOTE the pattern: this row moves whenever a rounded `du -sh` crosses a boundary, three times in one day at one point, and each move is a sweep of nine files. That is the price of the number being true, and it is worth paying — but if the churn ever outweighs it, do NOT reach for a KB band — that is what the deleted CLI-binary row did, and it kept CI red for days because this Mac and the GitHub runner build the same commit 3% apart. A byte count is a property of the toolchain, not of the source. `du -sh`'s 0.1 MB rounding is what makes THIS row gateable across machines. NOTE: "2.4 MB" and "2.9 MB" are deliberately NOT added to this forbidden list — both are still true of a specific date and a changelog page renders them as history, so this list would fail the deploy on a truthful sentence. | "3.1 MB" — and re-derive it, never retype it |
| "28 commands" | There are 26. | "26 commands" |
| "Nothing is uploaded, ever" | `gist` uploads on request. | "No network code at all; `gist` shells out to your own `gh`" |
| "signed by Apple" | Not yet true. `spctl -a dist/Chute.app` says `rejected`. The *word* "notarised" is deliberately NOT on this list: a word list cannot tell a claim from a denial, and forbidding it blocked the site from discussing the wall at all. `check-claims.mjs` asks `spctl` and forbids the affirmative forms instead — a derived check that retires itself. | Nothing — omit until the Developer ID exists |
| ~~"Available on Homebrew"~~ | **NOW TRUE as of 2026-08-28.** `brew install avaluev/tap/chute` installs 0.2.0 from source in ~46s with no warnings, and `brew test` passes. | Say it. |
