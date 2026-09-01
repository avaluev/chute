# Fact sheet — every claim, and the command that proves it

**Measured 2026-09-01. Re-measure before quoting; never copy a number forward.**

> This file went stale within four hours of being written: it said `0.1.0` while the build said
> `0.2.0`. That is not an argument against the file, it is the argument for it — the version was
> wrong in one place that names the command to check, instead of wrong in eleven that do not.
>
> The FALSE table at the bottom is **enforced**: `site/scripts/check-claims.mjs` parses it and
> fails the deploy if any of those strings appears on a rendered page. Strike a row through with
> `~~…~~` when it stops being false and enforcement drops it on the next run.

This file exists because three false claims reached the live site: "328 KB" (the app is 2.5 MB),
"28 commands" (there are 25), and unit-test counts that disagreed between the README and the
handoff. A number in marketing copy with no command beside it is a number that will be wrong
within a fortnight.

Rule: **if a claim is not in this table, do not publish it.** If a claim here is stale, re-run its
command and update this file first, then the copy.

---

## Product

| Claim | Value | Prove it |
|---|---|---|
| App bundle size | **2.5 MB** | `du -sh dist/Chute.app` |
| CLI binary size | **788 KB** | `ls -lh .build/release/chute` |
| CLI commands | **26** | `chute help \| grep -cE '^  [a-z]'` |
| Finder actions | **9**, drawn as **5 rows** | `chute finder-actions --menu` |
| External dependencies | **0** | `grep -c '.package(' Package.swift` → 0 |
| Lines of Swift | **6,873** | `find Sources -name '*.swift' \| xargs wc -l \| tail -1` |
| Minimum macOS | **13 Ventura** | `grep -o 'macOS(.v[0-9]*)' Package.swift` |
| Architectures | Apple Silicon and Intel | `lipo -info dist/Chute.app/Contents/MacOS/ChuteApp` |
| Version | **0.2.0** | `chute --version` |
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
| Unit assertions | **911 passed** | `swift run -c release chutetests` |
| End-to-end | **144 passed** headless, **172** full | `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` |
| Metrics plausibility | **4 checks** — magnitude, not shape | `./Scripts/check-metrics.sh` |
| Terminal tapes | **16** (12 hand-written, 4 generated from cases.ts) | `ls demo/tapes/*.tape \| wc -l` |
| GUI tapes | **5** hand-written | `ls demo/gui/tapes/*.sh \| wc -l` |
| Demo delivery pipeline | **11 checks** | `./demo/gui/selftest.sh` |
| Case data | **19 cases** | `cd site && npm run check:cases` |
| Site routes | **38** | `cd site && npx next build` |
| CI | macOS 13, 14, 15 | `.github/workflows/macos-matrix.yml` |

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
| "328 KB" | The app is 2.5 MB. This was live on the site until 2026-08-28. | "2.5 MB, no dependencies, no launch daemon" |
| "28 commands" | There are 26. | "26 commands" |
| "Nothing is uploaded, ever" | `gist` uploads on request. | "No network code at all; `gist` shells out to your own `gh`" |
| "Notarized" / "signed by Apple" | Not yet true. `spctl -a dist/Chute.app` says `rejected`. | Nothing — omit until the Developer ID exists |
| ~~"Available on Homebrew"~~ | **NOW TRUE as of 2026-08-28.** `brew install avaluev/tap/chute` installs 0.2.0 from source in ~46s with no warnings, and `brew test` passes. | Say it. |
