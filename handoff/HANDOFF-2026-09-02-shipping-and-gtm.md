# HANDOFF — shipping surface and the GTM pack — 2026-09-01/02

> Moved out of `handoff/NEXT.md` on 2026-09-04 to keep the canonical file under 400 lines.
> A record of finished work, not a plan. Nothing here needs re-reading to continue.

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

## DONE 2026-09-02 (verified) — the GTM pack, and four new guards

| Fix | Proof |
|---|---|
| **The Apple question answered and costed.** It was two questions fused into one: taking money needs no Apple ID; the file opening on a stranger's Mac needs $99/yr. Break-even is **6 units**. `marketing/09-APPLE-AND-DISTRIBUTION.md` | `spctl -a -vv dist/Chute.app` → `rejected`, `origin=Chute Local Dev` |
| **The escape hatch that closed.** Homebrew ends support for casks failing Gatekeeper as of **2026-09-01** and is removing `--no-quarantine` (`Homebrew/brew` #20755). Any plan with "worst case, ship a cask" in it is dead. The *formula* path is untouched — locally compiled binaries are never quarantined, which is why the free CLI already reaches strangers with no Apple ID. | `docs/11-PHASE-0-RUNBOOK.md` item 7, already DONE |
| **The site can discuss the wall.** The FALSE table forbade the literal word "notarized", so a word list could not tell a claim from a denial — it would have blocked the only honest thing to publish while unsigned, and it missed the British spelling this repo actually uses. `check-claims.mjs` asks `spctl` and forbids 10 affirmative phrasings instead. **The row retires itself when the verdict changes.** | perturbed: "notarised and stapled" on a page → `FAIL spctl says rejected, but 3 page(s) claim otherwise` |
| **The LinkedIn hook gate scans every `marketing/*LINKEDIN*.md`.** It was hard-coded to `08`, so the six new hooks would have been the campaign's only ungated copy — the identical shape as the bug that let five assets sell a deleted command. | 18 hooks across 2 files; perturbed both ways (wrong count, and >140 chars) → red |
| **The FALSE table now applies to README.md.** Every other check reads the built site and is blind to the repo's own front door, which carried "Nothing is uploaded, ever" — forbidden in bold since 2026-08-28, with the precise replacement written beside it. Fixed to the precise phrasing. | perturbed: appended the string → `FAIL 1 forbidden claim(s) are in README.md` |
| **Fact sheet de-rotted.** `Lines of Swift` said 6,873 against a real 11,680; `Version` said 0.2.0 against a shipping 0.2.1. New §Distribution carries every Gatekeeper claim with its command. | `find Sources -name '*.swift' \| xargs wc -l \| tail -1` |
| **`/building-with-agents` renders from the markdown, not a copy of it.** `marked` reads `marketing/11-BUILDING-WITH-AGENTS.md` at build time. Two copies of an article is the same failure as two copies of a claim. | `npx next build` → 36 routes; sitemap covers all 30 |

**The gate caught this session's own writing.** The article's §Part 4 explains that scoping the
command checker to code spans removed eleven false positives — and put the example phrase inside
backticks, which made it a real ghost-command hit. `FAIL 2 place(s) show a chute command that does
not exist`. The sentence was fixed, not the gate.

## DONE 2026-09-03 (verified) — the audit: 5 reviewers, 55 findings, 45 fixed

Every finding, its severity and its disposition — fixed, half, or not done with the reason — is
in **`docs/specs/audit-2026-09-03-FINDINGS.md`**. Four commits after `92fd7ee`. Read that file
before re-auditing anything; the "checked and lean" list at the bottom is what NOT to re-walk.

The ones a buyer would have hit first:

| Fix | Proof |
|---|---|
| **The suite was red before the audit began.** A Claude Code session that auto-updated under itself read as **"2.1.250"** — `proc_pidpath` fails for an unlinked executable and the row fell back to the bare version. | `ProcessMetrics.execPath(pid:)` via `KERN_PROCARGS2`; the machine-wide assertion at `ProcessMetricsSuite.swift:190` |
| **`chute clean --force ./other` trashed the wrong folder.** No flag was a switch, so `--force` ate `./other` and `clean` ran on the cwd with the preview skipped. | `ChuteCore/ArgParse.swift`, `ArgParseSuite`, smoke "a switch does not swallow the path after it" |
| **A buyer could pay and never get a key.** Resend failure → `200 issued` to Paddle; a notification without an embedded email → silent 200. | `worker/src/index.js`: 500 on both; `PADDLE_API_KEY` (optional) looks the customer up |
| **"Licensed to …" with nothing on disk.** `Trial.activate` ignored a failed save. | `LicenseSuite` "a good key whose record cannot be saved reports failure" |
| **`chute gist` uploaded quoted secrets.** `export TOKEN="…"` and `MYSQL_ROOT_PASSWORD=` both walked past `Redact`. | `CoreSuites` Redact, 3 new assertions |
| **Every launch could destroy an image on the clipboard** — the doctor probe ran at launch and "restored" `""`. | `Diagnostics.liveEnv(endToEnd:)`, opt-in |

**Deleted, net −559 lines, −1 dependency:** the xlsx inventory generator (dead, rotted), two
unused shadcn components, `CONFIG.seller`, the one-conformer `TerminalAdapter` protocol,
`NameDerive.uniquePath`, three byte-identical helpers, a parameter nothing read at 11 sites.

**The fixture that cannot exist.** On this macOS a locally copied binary — Apple-signed or
ad-hoc, however copied or deleted — is SIGKILLed within ~100 ms of its file being unlinked
(0/40 survived, 400 spawns measured); the Developer-ID hardened-runtime claude binary survives.
So the unlinked-binary case is proved by the reader on a live pid plus the machine-wide
assertion, not by a spawned fixture. Written into the suite; do not try again.

