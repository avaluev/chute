# HANDOFF — Chute — 2026-08-28

STATE: `main` · tree clean · **not pushed**
       unit **637/637** (`swift run chutetests`) ·
       headless e2e **128/128** (`CHUTE_HEADLESS=1 ./Scripts/smoke.sh`) ·
       full e2e **152/152** (`./Scripts/smoke.sh` — build `-c release` FIRST, it runs the
       release binary and will pass against a stale one) ·
       cases **25/25** (`cd site && npm run check:cases`) ·
       site **38 routes** (`cd site && npx next build`) · Paddle gate passes ·
       extension `14 actions · 8 drawn rows` · signed `Authority=Chute Local Dev` · zero dependencies

> The old header claimed 466 unit / 133 e2e and README.md:197 claimed 519 / 140. Both were stale
> and they disagreed with each other. The numbers above were measured on 2026-08-28. **Re-measure
> before quoting; do not copy a count forward.**

## ONE-LINE GOAL
Your agents should not cost you attention: turn a Finder selection into agent-ready context, and
tell you which agent is waiting.

---

## RUN THIS FIRST (in a real Terminal, not through an agent)

```bash
swift run chutetests && ./Scripts/smoke.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh && ./Scripts/install.sh
cd /Users/sxope/Documents/2026/Development/37.chute && ~/.local/bin/chute doctor
```
Expect: `✅ 466 assertions passed`, `smoke: 133 passed, 0 failed`, `→ all 9 checks passed`.
`build-app.sh` may ask the keychain for the signing key — click **Always Allow** once.

---

## WHAT THE PRODUCT DOES TODAY

**Finder right-click → Chute actions INLINE in the context menu** (8 actions, `chute finder-actions` lists them; no `Chute ▸` hop since 2026-08-27 — each row carries a literal SF Symbol — folder for the tree, photo for the image, square.and.pencil for new files — and the tree shows on FILE clicks too, copying the enclosing folder):
Copy Full Paths (n) · Copy Files as Context (n) · Copy Folder Tree ▸ 2 / 4 / All Levels ·
Save Clipboard as Files… · New File ▸ Empty Markdown File / Markdown File from Clipboard /
Image from Clipboard · Set Up for an Agent ▸ Add Agent Rules / New Scratch Folder ·
Move Junk to Trash… · Open in Terminal.
Renamed and recoloured 2026-08-28 — the full row-by-row map, the naming rules and the
JTBD/CLI coverage tables are in docs/12-CAPABILITY-MAP.md.

**Menu bar** — sessions grouped by what you must do about them, with per-session cost:
```
Waiting for You  (1)
  sntz_mockups   waiting 2 hours for you    0% CPU · 520 MB memory        ⌥1
Agents Working  (3)
  37.chute   ◑ Session switcher completion   3% CPU · 774 MB memory       ⌥2
Idle Terminals  (4)
  37.chute   no agent running
This Mac — using 1.9 of 16 cores · busiest: chrome-headless-shell at 126% CPU · battery at 31 °C
Local Servers  (8)  ▸   Open in Browser · Copy the URL · Stop It (kill 55868)
Report a Problem…
```

**CLI** — 25 commands, all covered by the e2e suite. `chute doctor` diagnoses, `chute doctor
--report` builds a redacted problem report for a public issue.

---

## BUSINESS MODEL — decided 2026-08-27, do not re-litigate

**Open core.** `chute` CLI is MIT, installable by Homebrew; **Chute.app is $19 one-time** through
Paddle. The CLI is rewritable in a weekend; the sandboxed Finder integration is the moat, and three
of its load-bearing facts are documented nowhere but this repo.

- **Buy the $99 Apple Developer ID.** Without notarisation every buyer meets a Gatekeeper wall.
  Six sales pay for it. Everything in the launch plan assumes a clean install.
- **Support has no inbox.** "Report a Problem…" → redacted diagnostics on the clipboard + a
  prefilled public GitHub issue. One answer serves everyone who searches it.
- **Positioning:** *your agents shouldn't cost you attention.*
- **Launch order:** notarised build → Homebrew tap + README GIFs → technical write-up →
  Show HN → Product Hunt two weeks later. Channels and reasoning in
  `/Users/sxope/Documents/2026/Development/37.chute/docs/09-GTM-DECISIONS.md`.

---

## NEXT — in order

Everything below the line is done. **Everything blocking revenue is manual and yours.**

### 1. Phase 0 — nothing ships without these (all manual)
| # | Thing | Why it blocks | Where |
|---|---|---|---|
| 1 | Two CNAMEs for chutedev.com → `chute.pages.dev`, **proxied** | `dig +short chutedev.com` is empty; every launch asset prints that domain | Cloudflare DNS |
| 2 | Apple Developer ID ($99/yr) + notarytool profile | `Scripts/release.sh` dies on it; every stranger meets Gatekeeper | `Scripts/notarize-setup.md` |
| 3 | Production Ed25519 keypair | `Sources/ChuteCore/License.swift:28` is still `REPLACE_ME_BEFORE_RELEASE` — no key can verify | `cd worker && node keygen.mjs` |
| 4 | `hello@` and `keys@chutedev.com` | the only stated support channel, and the licence email's sender | Cloudflare Email Routing + verify in Resend |
| 5 | Paddle account, product, `pri_…` | checkout degrades to trial-download while the env vars are empty | `site/src/lib/config.ts:25` |
| 6 | Worker deploy + 3 secrets | no key is minted without it | `cd worker && npx wrangler deploy` |
| 7 | Homebrew tap | `chute.rb` has a 64-zero sha256; needs a real `v0.1.0` tag first, which needs (2) | `packaging/homebrew/README.md` |

Order matters: **(2) → `release.sh` → tag → sha256 → (7).** (1), (4) and (6) can run in parallel.

### 2. Record the demos — needs you at the machine
19 of 25 cases have no recording. `demo/gui/` is built and dry-runs clean:

```bash
make -C demo/gui plan   # safe anywhere
cd /Users/sxope/Documents/2026/Development/37.chute && make -C demo/gui all    # real screen
```
Grant Screen Recording **and** Accessibility to your TERMINAL, not to Chute, and relaunch the
terminal afterwards — macOS only re-reads that permission on launch. One tape exists as the
worked example; 24 to write, and each one is ~30 lines of verbs.

### 3. Hand-verify the one thing no test covers
The menu-bar gate wiring. ChuteApp is AppKit and outside the test target, so `trial.isUnlocked`
is tested but "both menu builders call it" is not:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && python3 - <<'EOF'
import json, time, os
p = os.path.expanduser("~/Library/Application Support/Chute/trial.json")
os.makedirs(os.path.dirname(p), exist_ok=True)
long_ago = time.time() - 400 * 86400 - 978307200
json.dump({"firstRun": long_ago, "lastSeen": time.time() - 978307200}, open(p, "w"))
EOF
```
Then open the menu bar. Expect **two rows** — "Trial ended — Buy Chute, $19 once" and the free-CLI
line — and **no session list, no server list, no count on the badge**. Delete `trial.json` after.

### 4. Look at the eight-row Finder menu
```bash
cd /Users/sxope/Documents/2026/Development/37.chute && .build/release/chute finder-actions --menu
```
That prints it without a right-click. Then right-click for real and judge it. The grouping was
reasoned, not seen — the one part of this that has not met a human eye.

## DECISIONS (do not re-litigate)

- **Open core, $19, MIT CLI, buy the $99 ID.** See above.
- **The extension never does the work.** It writes a request to `~/.chute/requests`; ChuteApp
  carries it out. Measured: `git` refuses to run in a sandbox at all, launching an app is denied
  (`-54`), AppleScript to Terminal is denied (`-10004`).
- **Sign with a stable identity** (`Scripts/sign-identity.sh`). An ad-hoc signature is a new code
  identity every build, which invalidates the extension's sandbox container — the menu then
  vanishes with no error anywhere.
- **Never route around a user's setting.** Notifications denied means silence plus an offer to fix
  it, not an `osascript` banner wearing Script Editor's icon.
- **One action table** (`ChuteCore/FinderActions.swift`) feeds the Finder menu, the app and the
  tests. Two copies had already drifted into naming different actions.
- **No XCTest** (ships with Xcode) · **no third-party dependencies** · **no telemetry**.
- **Chute NEVER writes to another tool's configuration** — decided 2026-08-27 by the founder:
  a broken agent setup costs the user more than any badge is worth. `chute hooks install` is
  gone; `chute hooks snippet` PRINTS the JSON for the user's own hand, `status` is read-only,
  `uninstall` only ever subtracts chute-marked blocks (legacy installs). The doctor "hooks"
  check was removed with it — doctor must not nudge people toward editing `~/.claude`.
  The founder's own machine still has the legacy hooks wired (their choice, they power the
  badge); `chute hooks uninstall` removes them whenever wanted.
- **Price $19**, revisit at v1.0 once signed and auto-updating.
- **Temperature is the battery sensor, and says so.** CPU die sensors need root; `powermetrics`
  needs sudo. `ProcessInfo.thermalState` speaks only when ELEVATED — ".nominal" printed as
  "running cool" beside a 171% session row on a hot chassis is how the line lost trust. The
  This-Mac line is measurements only (`SystemVitals.machineLine`), built from the SAME ps
  snapshot as the rows, and the open menu re-samples everything every 2 s (timer in .common
  run-loop modes, sampling off-main).

---

### Decided 2026-08-28

- **The app is the product; the CLI is the sample.** One launch wave, app-first. The two-wave
  plan spent eight days teaching the audience to want the free thing before asking for $19. See
  `docs/09-GTM-DECISIONS.md` §7 and `marketing/05-CONTENT-CALENDAR.md` §1.
- **Four Finder actions added** — unpack, seed, sandbox, clean. The paid surface demonstrated
  ~73 min/day against the free CLI's ~125; a buyer's own arithmetic said not to buy. It is now
  **130.7 vs 86.8**, asserted by `site/scripts/check-cases.mjs` so it cannot invert again.
- **Destructive Finder actions confirm before writing.** `confirmButton` on `ChuteAction`; the
  app runs the harmless form, shows the list, and only re-runs with `--force` on a yes. Cancel is
  the default button. A right-click that silently writes into a repo is the one thing that would
  destroy the trust the whole page is sold on.
- **The menu bar is gated.** It was not, and `/buy` sold it — three of the four things that page
  lists kept working forever. A lapsed trial now gets two rows and a plain statement that the
  free CLI still does all of it.
- **The menu is 8 drawn rows, not 13.** Grouped, not trimmed. The rule for what stays one click
  is the ledger: above ~10 min/day is inline, below may sit one level down.
- **Every figure on the site is re-derived from the ledger at build time**, including the
  ledger's own arithmetic. A number that cannot be traced cannot be published.
- **A recorded stopwatch beats an estimate.** Where `demo/out/gui/<slug>.json` exists, the deploy
  fails if the page claims a saving the recording did not reproduce.
- **No placeholder art, and no hole where art would go.** A case without a recording renders as
  one column, deliberately — not a two-column row with an empty half.

## TRAPS (each cost real time)

- **`representedObject` does not survive the trip to Finder.** A FinderSync menu is drawn by
  Finder and only plain properties cross that boundary — `tag` does. Dispatching on
  `representedObject` made every menu item a silent no-op.
- **A sandboxed appex's container ACL pins the code identity that created it.** After a rebuild
  macOS refuses to start it: `(AppSandbox) code identity <cdhash …> not in ACL for container`.
  `pluginkit` still reports it registered and enabled. `Scripts/install.sh` repairs it —
  delete container → `pluginkit -r` → relaunch the app → `pluginkit -a` → `-e use` → restart Finder,
  in that order. Clearing the container alone is not enough.
- **`git` cannot run inside an App Sandbox** — "xcrun: error: cannot be used within an App Sandbox".
- **An appex registers when its HOST APP IS LAUNCHED**, not on `pluginkit -a`.
- **`NSExtensionMain` is not callable from Swift** — link with `-Xlinker -e -Xlinker
  _NSExtensionMain` and no `main.swift`.
- **`NSHomeDirectory()` in the extension is the container**, not `/Users/<you>`. A `~`-relative
  write lands in the container and still exits 0. Absolute paths only.
- **The app bootstrap must stay LAST in `Sources/ChuteApp/main.swift`** — top-level code runs in
  order. Deleting a class above it once took `app.run()` with it.
- **A skipped check is not a passing check.** That same regression showed up as a green run because
  "Chute.app is not running" was reported as SKIP. It is a failure now.
- **AppleScript over a live window list breaks mid-scan** — "Can't get item 13 of every window.
  Invalid index" — when a terminal closes. Each window and tab is wrapped in `try` for that reason.
- **`lsof -ti tcp:<port>` returns the LEAF and the CLIENTS.** Killing the leaf lets the npm
  supervisor respawn the port; killing everything returned kills the browser tab watching it.
- **`brew services` daemons cannot be killed, only booted out.** postgres/redis/ollama are
  launchd agents with `KeepAlive=true`: TERM *and* KILL are respawned before the port check
  even runs, so "Stop It" read as a no-op. The only stop launchd respects is
  `launchctl bootout gui/$UID/<label>`; `LocalServers.killPlan` routes any kill tree containing
  a launchd job pid (from `launchctl list`) to bootout. Restore with
  `launchctl bootstrap gui/$UID ~/Library/LaunchAgents/homebrew.mxcl.<name>.plist` or
  `brew services start <name>`.
- **`Shell.run` used to read stdout then stderr sequentially.** A child that fills the ~64 KB
  stderr pipe while stdout is still open deadlocks both processes — in the menu bar app that is
  a dead menu with no error anywhere. stderr is now drained concurrently; the Shell suite floods
  200 KB to prove it.
- **`pgrep -x Terminal` never matches Terminal.app**; use `ps -Ao comm` and a path fragment.
- **`ps -o tty=` prints `??`**, not empty, when there is no controlling terminal.
- **An agent's real work runs DETACHED from its tty.** claude (ttys004) → zsh (??) → npm (??) →
  chrome-headless-shell (??) at 120% CPU: summing tty-attached processes showed "0% CPU" on the
  session cooking the chassis. `SystemVitals.attribute` walks every detached process up its
  parent chain to the terminal it descends from; the menu also names the machine's busiest
  process when it exceeds 80% of a core.
- **APFS is case-insensitive**: the app executable is `ChuteApp` so it cannot collide with `chute`.
- **`git log origin/<branch>..HEAD` returns 0 when the branch was never pushed** — the error is
  suppressed and silence reads as success. Verify with `git ls-remote --heads origin <branch>`.
- **The installed CLI is a COPY inside the app bundle.** After any Swift change:
  `./Scripts/build-app.sh && ./Scripts/install.sh`.
- **`sudo` and interactive password prompts do not work through an agent shell.** Finder can move a
  protected container to the Trash without a password; `osascript -e 'tell application "Finder" to
  delete POSIX file "…"'`.
- **Another agent may be working in this tree.** A session here switched branches mid-flight and a
  commit landed on `fix/kill-the-tree-not-the-leaf`. Check `git branch --show-current` before
  committing.

---

### From 2026-08-28

- **`FileScan.expand` filtered junk out before `clean` could see it.** Right for `bundle`, exactly
  backwards for the one command whose job is to find junk — every `.log`, `.tmp`, `.bak`, `.swp`,
  `.orig` and `.rej` was invisible and only the scratch PREFIXES were ever listed. Fixed with
  `includingJunk:`; `isAgentScratch` still decides what is actually trashed. → If a command seems
  to under-report, check what the shared scan dropped before blaming the command.
- **A dry run wrote a timing file the deploy gate believed.** `emit_timing` read 0.0s off a
  stopwatch that was never started. → Any mode that fakes execution must be enforced in the
  library, never left to each caller to remember; `make -C demo/gui lint` exists for this.
- **PLAN mode leaked within ten minutes of existing**, because a tape called `osascript` directly
  and started driving the real cursor. → A tape may only speak in verbs.
- **The site's nav did not link to the two new pages**, and five sections reserved an empty slot
  for demos that do not exist. Both survived a green build, 38 generated routes and zero failed
  network requests. → **Open it in a browser and look at it.** Nothing else catches this class.
- **The copy said "eight files"; the demo selects three folders holding six.** → The page quotes
  the demo. Never bend the recording to match a sentence.
- **`git commit` in this repo needs an explicit pathspec** and the working directory does NOT
  persist as expected between agent shell calls — `cd` to the repo root in every command.

## REVIEW FINDINGS STILL OPEN

**Apple platform design**
- The status item draws a text glyph (`⤓ 3`). Apple's own menu-bar items use a template `NSImage`,
  so Chute will not tint correctly in every menu-bar appearance.
- The first-run window is a hand-built `NSWindow` of stacked rows; `NSAlert` is the HIG-correct
  shape for "one thing needs your permission".
- No Settings window and no About panel. A paid app needs both before launch.

**Code**
- `/Users/sxope/Documents/2026/Development/37.chute/Sources/chute/Commands/AgentCommands.swift`
  is four features in one file (ports, sandbox, env, terminal launching). Split it when the next
  one arrives.
- The assert harness has no test isolation: suites share the process and the real clipboard, and
  the e2e suite drives the REAL app — which is why running it posts real notifications.

**Security — fixed, recorded for the next reviewer**
Inbox hardened to `0700` with per-file ownership checks; `unpack` blocked from escaping through a
symlink; redaction extended to private key blocks and URL credentials; AppleScript escaping fixed
to handle backslashes. Full detail in the commit `security: harden the request inbox…`.

**2026-08-27 deep review — fixed the same day**
- CRITICAL `chute gist` uploaded raw files while help claimed "nothing is ever uploaded" —
  now redacts every text file before upload and the help names gist as the one exception.
- HIGH `chute unpack --force` could mkdir OUTSIDE `--dir` through a pre-existing symlink before
  the escape check ran — `staysInside` now runs before AND after `createDirectory`.
- HIGH `seed`/`note`/`buf add` swallowed write errors (`try?`) then reported success — a failed
  `chute note` claiming "anchored" was the worst lie in the product. All three now fail loudly.
- HIGH `NameDerive.uniquePath` was probe-then-write (TOCTOU): two simultaneous pastes could both
  resolve `Shot-2.png` and the second silently clobbered the first. `writeUniquely` makes the
  write itself the probe (`.withoutOverwriting` = O_EXCL).
- MEDIUM `Notify.deniedAtLastCheck` was written from UNUserNotificationCenter's queue and read on
  main — now hops to main for every write.
- Dead code removed: `FirstRunWindow.failuresOnly`, `SessionPhrasing.runningFor`.
- LOW, known and accepted: `Out.fail` exits without unwinding `defer`, so a failed
  `chute checkpoint`/`gist` can leave a stray temp file in `/tmp` (periodically purged by macOS).

---

## TESTING OTHER macOS VERSIONS WITH ONE LAPTOP

1. **CI is the version matrix.**
   `/Users/sxope/Documents/2026/Development/37.chute/.github/workflows/macos-matrix.yml` runs build,
   447 unit assertions and the headless e2e suite on **macOS 13, 14, 15**. Free for public repos —
   which open core makes you anyway. Catches API removals, `lsof`/`ps`/`osascript` output changes,
   Swift drift, SDK breakage. Cannot catch: the extension loading, TCC prompts, notification delivery.
2. **A VM for the desktop half.** Apple Silicon virtualises macOS 12+ via Virtualization.framework —
   VirtualBuddy (free) or UTM; the licence allows two VMs per host. Finder extensions do load in a
   VM and TCC prompts behave normally.
3. **The floor is honest.** `Package.swift` declares `.macOS(.v13)` and there are **no `@available`
   guards anywhere**, because every API used exists at 13 — audited. Adding a newer API without a
   guard is the failure mode; the matrix catches it.
4. **The risk is behaviour, not API.** macOS 15.0–15.1 removed the Extensions settings pane; 14+
   tightened App Management provenance. Recorded in
   `/Users/sxope/Documents/2026/Development/37.chute/docs/08-MACOS-COMPATIBILITY.md`.

---

## OPEN QUESTIONS FOR THE HUMAN
1. **Domain** — none of the 56 in `docs/CloudflareDomainsPrice.md` spell the product's name.
2. **Real CPU temperature** — worth a privileged helper, or is the battery sensor plus thermal
   pressure enough?
3. **Your own machine still has the legacy hooks wired** (they power the badge and were left
   untouched on purpose). Keep them, or `chute hooks uninstall` to run hook-free?
