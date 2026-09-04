# Fact sheet — every claim, and the command that proves it

**Measured 2026-09-01. Re-measure before quoting; never copy a number forward.**

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
| App bundle size | **3.0 MB** | `du -sh dist/Chute.app` |
| CLI binary size | **805 KB** | `ls -lh dist/Chute.app/Contents/MacOS/chute` — the SHIPPED copy. `.build/release/chute` is 1.0 MB because it has not been stripped yet; only `build-app.sh` strips. |
| CLI commands | **26** | `chute help \| grep -cE '^  [a-z]'` |
| Finder actions | **9**, drawn as **5 rows** | `chute finder-actions --menu` |
| External dependencies | **0** | `grep -c '.package(' Package.swift` → 0 |
| Lines of Swift | **12,630** | `find Sources -name '*.swift' \| xargs wc -l \| tail -1` |
| Minimum macOS | **13 Ventura** | `grep -o 'macOS(.v[0-9]*)' Package.swift` |
| Architectures | Apple Silicon and Intel | `lipo -info dist/Chute.app/Contents/MacOS/ChuteApp` |
| Version | **0.2.1** | `chute --version` |
| Homebrew | `brew install avaluev/tap/chute` | `brew test avaluev/tap/chute` |

## Privacy — the strongest claim, and the most precise

| Claim | Value | Prove it |
|---|---|---|
| Network code in Chute | **None** | `grep -rn 'URLSession\|NSURLConnection' Sources/` → 0 results |
| Telemetry / analytics | **None** | `grep -rniE 'analytic\|telemetry\|track' Sources/` → 0 results |
| Account required | **No** | there is no sign-in surface anywhere in the app |
| Licence check | **Offline signature** | `Sources/ChuteCore/License.swift` — Ed25519, no network |
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
| Unit assertions | **1,078 passed** | `swift run -c release chutetests` |
| End-to-end | **150 passed** headless, **178** full | `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` |
| Menu-item acceptance | **81 checks** — every Finder action against a hostile tree | `./Scripts/acceptance.sh` |
| Metrics plausibility | **4 checks** — magnitude, not shape | `./Scripts/check-metrics.sh` |
| Terminal tapes | **16** (12 hand-written, 4 generated from cases.ts) | `ls demo/tapes/*.tape \| wc -l` |
| GUI tapes | **5** hand-written | `ls demo/gui/tapes/*.sh \| wc -l` |
| Demo delivery pipeline | **11 checks** | `./demo/gui/selftest.sh` |
| Case data | **19 cases** | `cd site && npm run check:cases` |
| Site routes | **38** | `cd site && npx next build` |
| CI | macOS 13, 14, 15 | `.github/workflows/macos-matrix.yml` |

## Distribution and Gatekeeper — measured 2026-09-02

| Claim | Value | Prove it |
|---|---|---|
| Gatekeeper verdict on the app | **`rejected`** | `spctl -a -vv dist/Chute.app` → `rejected`, `origin=Chute Local Dev` |
| Signing identity | **self-signed, local only** | `security find-identity -v -p codesigning` → one identity, `"Chute Local Dev"` |
| Apple Developer Program | **not enrolled** | no `Developer ID Application:` line in the output above |
| Apple Developer Program cost | **$99/yr** | developer.apple.com/programs |
| Break-even at $19 | **6 units/yr** | 99 ÷ 19 |
| Steps for a stranger to open the unsigned app on macOS 26 | **6, plus a password** | walked and recorded; see `marketing/09-APPLE-AND-DISTRIBUTION.md` |
| Homebrew ends support for casks failing Gatekeeper | **2026-09-01** | `Homebrew/brew` issue #20755 |
| The free CLI installs with no Apple involvement | **True** | `brew install avaluev/tap/chute` — a formula, built from source, never quarantined |

**The precise phrasing.** Say *"the CLI installs from source through Homebrew and never meets
Gatekeeper"*. Do **not** say the app is notarised, signed by Apple, or that it opens without a
warning — `spctl` says otherwise, and `site/scripts/check-claims.mjs` asks `spctl` directly rather
than matching a word, so this row retires itself the moment the verdict changes.

## Commercial

| Claim | Value |
|---|---|
| Price | **$19**, one payment |
| Trial | **14 days**, every feature, no card |
| Refund | **30 days**, no questions asked |
| CLI | **Free forever, MIT** — `brew install avaluev/tap/chute` |
| Merchant of record | Paddle.com Market Ltd |
| Seller | IE Valuev Aleksandr Aleksandrovich, Bishkek, Kyrgyz Republic |

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
| "328 KB" | The app is 3.0 MB. This was live on the site until 2026-08-28. | "3.0 MB, no dependencies, no launch daemon" |
| "2.5 MB" | Was true, then was not: the bundle reached **3.3 MB** unnoticed because eight files carried a hand-typed copy of this number and nothing checked any of them. `strip -x` before signing brought it to **2.4 MB** on 2026-09-01, and `Scripts/build-app.sh` now FAILS if this row and `du -sh dist/Chute.app` disagree. It went to **2.8 MB** on 2026-09-03: the redesigned icon is 755 KB against the old one's 359 KB, which is what ten natively-drawn slices with real gradients cost. It went to **2.9 MB** on 2026-09-04, when the ratchet moved `SessionCommand`, the hex parse and the Finder dispatch rule out of the two untestable targets and into ChuteCore — which is linked into all three binaries, so code that shipped once now ships three times. 112 KB is what that coverage costs, and it was a deliberate trade. It reached **3.0 MB** later the same day — `AboutText` and the rewritten Settings copy, again linked into all three binaries. NOTE the pattern: this row moves whenever a rounded `du -sh` crosses a boundary, and each move is a sweep of nine files. That is the price of the number being true. NOTE: "2.4 MB" is deliberately NOT added to this forbidden list — it is still true of the strip change and the changelog page renders it as history, so this list would fail the deploy on a truthful sentence. | "3.0 MB" — and re-derive it, never retype it |
| "28 commands" | There are 26. | "26 commands" |
| "Nothing is uploaded, ever" | `gist` uploads on request. | "No network code at all; `gist` shells out to your own `gh`" |
| "signed by Apple" | Not yet true. `spctl -a dist/Chute.app` says `rejected`. The *word* "notarised" is deliberately NOT on this list: a word list cannot tell a claim from a denial, and forbidding it blocked the site from discussing the wall at all. `check-claims.mjs` asks `spctl` and forbids the affirmative forms instead — a derived check that retires itself. | Nothing — omit until the Developer ID exists |
| ~~"Available on Homebrew"~~ | **NOW TRUE as of 2026-08-28.** `brew install avaluev/tap/chute` installs 0.2.0 from source in ~46s with no warnings, and `brew test` passes. | Say it. |
