# HANDOFF — Chute — 2026-08-27

STATE: `main` @ `04355f6` · pushed (`git ls-remote --heads origin main` == local) · tree clean
       unit **447/447** (`swift run chutetests`) · e2e **132/132** (`./Scripts/smoke.sh`) ·
       headless e2e **108/108** (`CHUTE_HEADLESS=1 ./Scripts/smoke.sh`) ·
       `chute doctor` **10/10** · extension `loaded · 8 actions` · notifications `on` ·
       signed `Authority=Chute Local Dev` · 64 Swift files, 5,630 lines, zero dependencies

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
Expect: `✅ 447 assertions passed`, `smoke: 132 passed, 0 failed`, `→ all 10 checks passed`.
`build-app.sh` may ask the keychain for the signing key — click **Always Allow** once.

---

## WHAT THE PRODUCT DOES TODAY

**Finder right-click → `Chute ▸`** (8 actions, `chute finder-actions` lists them):
Copy Full Paths (n) · Copy Folder Tree ▸ 2 Levels / 4 Levels / Everything ·
Paste Image from Clipboard · New Markdown File · New Markdown File from Clipboard · Open in Terminal.

**Menu bar** — sessions grouped by what you must do about them, with per-session cost:
```
Waiting for You  (1)
  sntz_mockups   waiting 2 hours for you    0% CPU · 520 MB memory        ⌥1
Agents Working  (3)
  37.chute   ◑ Session switcher completion   3% CPU · 774 MB memory       ⌥2
Idle Terminals  (4)
  37.chute   no agent running
This Mac — running cool, battery at 31 °C · 87 °F
Local Servers  (8)  ▸   Open in Browser · Copy the URL · Stop It (kill 55868)
Report a Problem…
```

**CLI** — 28 commands, all covered by the e2e suite. `chute doctor` diagnoses, `chute doctor
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

1. **Buy the Developer ID and notarise.**
   ```bash
   xcrun notarytool store-credentials chute --apple-id <you> --team-id <team>
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/build-app.sh
   ditto -c -k --keepParent dist/Chute.app dist/Chute.zip
   xcrun notarytool submit dist/Chute.zip --keychain-profile chute --wait
   xcrun stapler staple dist/Chute.app
   ```
   expect: `status: Accepted`, then `The staple and validate action worked!`
2. **Website + domain.** `/Users/sxope/Documents/2026/Development/37.chute/docs/CloudflareDomainsPrice.md`
   still lists 56 variations of **`chut`** — the wrong word — on TLDs like `.plumbing`. Check
   `usechute.com`, `chute.tools`, `getchute.app`, `chute.sh` instead.
3. **Paddle**: product, checkout link, licence key generation, and an offline key check in the app.
4. **In-app onboarding** — the first-run window only appears when something needs a human; there is
   no "here is what this does" moment for a stranger.
5. **Uninstall parity** — `/Users/sxope/Documents/2026/Development/37.chute/Scripts/uninstall.sh`
   removes app, CLI, `~/.chute` and the appex registration, but leaves the Claude Code hooks in
   `~/.claude/settings.json`. Decide: prompt, or leave.

---

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
- **Price $19**, revisit at v1.0 once signed and auto-updating.
- **Temperature is the battery sensor, and says so.** CPU die sensors need root; `powermetrics`
  needs sudo. `ProcessInfo.thermalState` carries the honest "is my Mac struggling" signal.

---

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
- **`pgrep -x Terminal` never matches Terminal.app**; use `ps -Ao comm` and a path fragment.
- **`ps -o tty=` prints `??`**, not empty, when there is no controlling terminal.
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
2. **Uninstall and the hooks** — should `uninstall.sh` remove the Claude Code hooks it installed?
3. **Real CPU temperature** — worth a privileged helper, or is the battery sensor plus thermal
   pressure enough?
