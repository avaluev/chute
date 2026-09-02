# Audit 2026-09-03 — five reviewers, every finding and what happened to it

Five read-only reviewers ran in parallel over disjoint files (ChuteCore fs/process, ChuteCore
agent/licence, CLI+app+extension, scripts+site+worker, over-engineering). Every finding below was
verified by reading the code path or reproducing it against the built binary. Fixes are in the
four commits after `92fd7ee`; each carries a test that was perturbed to red before it was believed.

Severity is the reviewer's. **Fixed** means committed with a guard. **Not done** carries the reason.

## The one that was already red

| | Finding | Disposition |
|---|---|---|
| — | `swift run chutetests` was red on this machine before the audit started: a Claude Code session that had auto-updated underneath itself was named **"2.1.250"**. `proc_pidpath` fails with ENOENT for a process whose executable was unlinked, and the row fell back to `p_comm`, which for those processes IS the version. | **Fixed** — `KERN_PROCARGS2` keeps the exec path in the process's own argument block. `ProcessMetrics.execPath(pid:)`, proved on a live pid. A fixture could not reproduce it: on this macOS a copied binary — Apple-signed or ad-hoc, however copied or deleted — is SIGKILLed within ~100 ms of its file being unlinked; only the Developer-ID hardened-runtime claude binary survives. Measured over 400 spawns, recorded in `ProcessMetricsSuite`. |

## CRITICAL

| | Finding | Disposition |
|---|---|---|
| C1 | `Args` had no notion of a switch: `chute clean --force ./other` ate `./other`, fell back to the cwd and, preview skipped, trashed files the user never named. `paths --no-copy a.txt` printed the folder. | **Fixed** — `ChuteCore/ArgParse.swift`, the 15 value-taking flags written down once, `ArgParseSuite`, and a smoke case. |

## HIGH

| | Finding | Disposition |
|---|---|---|
| H1 | Worker: a Resend failure still answered Paddle `200 issued` — money taken, key minted into the void, no retry, and by design no address in any log. | **Fixed** — `email_` returns `res.ok`; a failure is a 500, Paddle retries, the retry re-mints the identical key. |
| H2 | Worker: the only live email source was `event.data.customer.email`; a Paddle Billing `transaction.completed` carries `customer_id` and is not promised to embed it. No email → permanent silent 200. | **Fixed** — looks the customer up by id when `PADDLE_API_KEY` is set (optional secret, README + wrangler.toml), otherwise 500 so it is visible and retried. |
| H3 | `Redact` walked past every quoted secret (`export TOKEN="ghs_…"`) and every prefixed key (`-e MYSQL_ROOT_PASSWORD=…`); `chute gist` uploaded the result. | **Fixed** — value class no longer stops at a quote; the key may carry a prefix; the key name is kept. 3 assertions. |
| H4 | `FileScan.readText` read a file of any size; "Copy Files as Context" on a folder with a 1 GB dump hung with no message. | **Fixed** — `maxFileBytes` (8 MiB) into `skipped`; message says "binary or oversized". |
| H5 | `chute diff --copy` on a clean tree emptied the clipboard and said "full patch copied"; `chute diff` printed "(no tracked changes)" over a git failure. | **Fixed** — both guards. |
| H6 | `chute basket add` past the 10-file cap reported the evicted files as "already there". | **Fixed** — outcomes counted from facts; "5 dropped — the basket keeps 10". Smoke case. |
| H7 | `--files-from` that could not be read silently became "the current directory" — the >200-file Finder path. | **Fixed** — an error naming the file. Smoke case. |

## MEDIUM

| | Finding | Disposition |
|---|---|---|
| M1 | `Trial.activate` discarded `save`'s Bool: pane said "Licensed to …", next launch was expired. | **Fixed** — nil on a failed save; `Trial.activationFailure` gives the pane the right sentence. |
| M2 | `ResumeCommand`: the session id was the one hook-file field reaching the clipboard unquoted, inside tmux's literal single quotes. | **Fixed** — refused unless a plain token, as `AgentTranscript.find` already does. |
| M3 | `Diagnostics.endToEndProbe` ran on every app launch and its "restore" wrote `""` over any image or file the user had copied. | **Fixed** — opt-in; `chute doctor` runs it, launch does not; "not run" is reported, not "failed". |
| M4 | `Shell.run(input:)` died of SIGPIPE (exit 141) when the child did not read stdin — pbcopy with no pasteboard server. | **Fixed** — `SIG_IGN` + throwing write. Proved with a 300 KB write to `true`. |
| M5 | `ProcessIdentity.argvCache` keyed on pid forever; a recycled pid named a new browser after a dead one's profile. | **Fixed** — keyed on the kernel's start time. |
| M6 | `LocalServers` climbed through `turbo`/`concurrently`, so "Stop It" on one app killed every sibling. | **Fixed** — multiplexers removed from the climb set; two-listener fixture. |
| M7 | `Junk` called `Untitled.md` scratch — the file New File ▸ Empty Markdown just created. | **Fixed**. |
| M8 | `sessions --json` printed nothing over zero sessions; `resume`/`focus` blamed the hook snippet when Automation was denied. | **Fixed**. |
| M9 | `@mentions` joined with spaces; a path with a space became four tokens. | **Fixed** — one per line whenever any path has a space. |
| M10 | `ports --kill --force` verified nothing after `kill -9`; EPERM on a root-owned Postgres printed "killed 1 process". | **Fixed** — `KillOutcome`, message decided once for CLI and menu. |
| M11 | ⌥⌘N registration status discarded. | **Fixed** — `HotKeyStatus.problem`, logged. Not surfaced in `doctor` (would be a new file to keep). |
| M12 | `smoke.sh` clobbered `SAVED` — the variable holding the user's clipboard for the EXIT trap. | **Fixed** — renamed. |
| M13 | `check-metrics.sh` exited 0 over zero sessions; smoke printed `ok … (0 checks)`. | **Fixed** — exit 2, smoke reads it as a skip. |
| M14 | Two sweeps in `check-untested-logic.sh` passed vacuously over zero files. | **Fixed**. |
| M15 | `cloudflare-setup.sh` put the DNS token on the curl command line; a failed DNS write exited 0. | **Fixed** — `--config -` on stdin; `RC`. |
| M16 | `sign-identity.sh` imported the signing key with `-A` (any application may use it). | **Fixed**. |
| M17 | Nothing ran `worker/contract.test.mjs` before a release or in CI. | **Fixed** — in `release.sh`'s gate and the workflow. The seed↔public-key pairing check is **not done**: it needs the production seed at release time; the placeholder gate stands. |
| M18 | Worker: any `transaction.completed` mints a licence (a second product, a 100%-off code). | **Not done** — one product, one price; a $0 completed transaction for Chute is still a Chute sale. Revisit with a second product. |
| M19 | `--files-from` newline-split and whitespace-trimmed; a name with an edge space round-tripped wrong. | **Half** — trimming removed. A newline in a file name still splits; marked `ponytail:` in `ArgParse.pathList`. |

## LOW

| | Finding | Disposition |
|---|---|---|
| L1 | `AppleScript.escape` did not escape `\n`/`\r` — a legal file name, an AppleScript parse error. | **Fixed**. |
| L2 | `TreeRender` drew an unreadable directory as an empty one. | **Fixed** — `(unreadable)`. |
| L3 | `FileScan.absolute` left `/./` for adjacent dots. | **Fixed**. |
| L4 | Worker: only the last `h1` in a rotating signature header was checked. | **Fixed** — any match; 5 contract cases. |
| L5 | Worker: no usable timestamp fell back to the clock — the second-different-key bug one fall-through away. | **Fixed** — 500. |
| L6 | `release.sh`: predictable `/tmp` logs; under `pipefail` the Gatekeeper `die` was unreachable. | **Fixed** — `mktemp`, `\|\| true`. |
| L7 | Site: `npm run lint` was red (setState in effect) and no gate ran it. | **Fixed** — after a tick; `deploy-site.sh` runs lint. |
| L8 | Site: JSON-LD `<script>` had no `<` escape. | **Fixed** — `jsonLd()`. |
| L9 | `check-paddle` could not see `.mp4`/`.webm`, which every hero case points at. | **Fixed**. |
| L10 | `config.ts` claimed a gate on `seller.country`/`entity` that did not exist; a second, emptier seller beside `SELLER`. | **Fixed** — deleted; three call sites use `SELLER`. |
| L11 | `REFUND` restated `CONFIG`'s two numbers. | **Fixed** — derives. |
| L12 | `ActionInbox` comment names a directory-mode check `drain` does not do; `License.swift` comment names a test that does not pin the production key. | **Not done** — comment-only; the placeholder is already gated by `release.sh`. |
| L13 | `chute latest` answers from the first 5000 files walked, silently; Finder "Image from Clipboard" HUD silent for 90 s without a rename. | **Not done** — reporting gaps, no data loss; noted here. |
| L14 | The ⌥⌘N HUD menu body was built twice per keypress. | **Fixed**. |

## Over-engineering (ponytail), biggest cut first

| | Finding | Disposition |
|---|---|---|
| P1 | `Scripts/build-inventory-xlsx.py` (316 lines, the repo's only Python dep, zero callers, already rotted) and its `docs/14-PRODUCT-INVENTORY.xlsx`. | **Deleted**. |
| P2 | `site/src/components/ui/card.tsx` + `separator.tsx` — shadcn scaffolding no page imports. | **Deleted**. |
| P3 | `CONFIG.seller` — see L10. | **Deleted**. |
| P4 | `TerminalAdapter` protocol (one conformer) + `TerminalError.timedOut` (nothing throws it). | **Deleted**. `TerminalKind` stays — it is in the `Session` data model. |
| P5 | `Out.deliver(label:)` — a parameter the body never read, at 11 call sites, plus `contextLabel` that existed to feed it. | **Deleted**. |
| P6 | `NameDerive.uniquePath` — test-only; `writeUniquely` (O_EXCL) replaced it. | **Deleted** with its tests. |
| P7 | `ResumeCommand.shellQuote` ≡ `PathFormat.shellQuote`; `ContextBundle.rel` ≡ `PathFormat.relativize`; two `pad` helpers in the CLI, only one truncating. | **Collapsed**. |
| P8 | `FileScanAbsolute` — a free function that only delegated. | **Deleted**. |
| P9 | "Fourteen actions" in two comments, against nine declared. | **Fixed**. |
| P10 | `--naming slug\|underscore` — undocumented; no product surface takes the default. | **Not done** — lower confidence; `slug` is still the bare-CLI default for `chute new`. Decide, then cut. |
| P11 | Three `SettingsWindow` wrappers that only forward to `UI.*`. | **Not done** — ChuteApp, no test can reach it, no behaviour at stake. |

Checked and lean, do not re-audit: every npm dependency is imported; no zero-caller public
function in ChuteCore; no hand-rolled stdlib; the `rm -rf` guards in install/uninstall/fixtures;
worker signature verification; checkout parameters; internal links; `check-claims` denominators.
