# HANDOFF — Chute: switcher shipped, Finder menu live — 2026-08-26

STATE: `main` @ `826220a` · pushed (`git ls-remote --heads origin main` == local) · build green
       (`./Scripts/build-app.sh` → `Build complete!`, 1.1M) · unit 214/214 (`swift run chutetests`)
       · e2e 53/53 (`./Scripts/smoke.sh`) · app running · hooks INSTALLED · Finder extension
       registered and enabled (`+ dev.valuev.chute.finder`)

## ONE-LINE GOAL
A macOS utility that turns a Finder selection into agent-ready context and tells you which of your
running AI agents is waiting for you.

---

## DONE (verified — each proved by a command that was RUN)

- **All 12 engine/onboarding tasks merged to `main`** — `git ls-remote --heads origin main` → `826220a`
- **Phantom badge FIXED** — `HookState.attention()` intersects hook records with the live tty set
  and applies the 6-hour staleness window. Perturbation: deleting the `live.contains` guard →
  `❌ 2 failed, 208 passed`; restored → `✅ 214 assertions passed`.
- **Hooks installed in `~/.claude/settings.json`** — `chute hooks status` → `✓` on all four events.
  Backup: `/Users/sxope/.claude/settings.json.chute-backup-20260826-170136`. All 12 pre-existing
  hook events and all 15 top-level keys survived (checked by parsing the file afterwards).
- **The badge now has something to say** — `chute sessions` → `→ 8 session(s), 1 need you`,
  from a real `waiting` hook record written by a live session on `ttys001`.
- **`hooks uninstall` is a true reversal** — an event left empty is deleted, not left as `[]`.
  Perturbed → `❌ 1 failed`; restored → green.
- **Finder context menu WORKS** — `Chute ▸` submenu via a sandboxed `FIFinderSync` appex,
  ad-hoc signed, no Xcode. `pluginkit -m -p com.apple.FinderSync` → `+ dev.valuev.chute.finder(0.1.0)`.
- **Uninstall/install cycle is clean** — `./Scripts/uninstall.sh` → `0` chute plugins;
  `./Scripts/install.sh` → `1`, already flagged `+`. No System Settings visit needed.
- **Smoke covers the switcher** — section 14: `sessions --json` shape, `focus` exit code,
  `doctor --json` shape, and hooks install/status/uninstall against a temp fixture.

## IN FLIGHT
- Nothing. Tree clean, `main` pushed.

## NEXT
1. **Right-click any file in Finder → `Chute ▸`.** The only step no command can verify. If the
   submenu is missing: `killall Finder`, then `pluginkit -m -p com.apple.FinderSync`.
2. **$99 Apple Developer ID** — needed before anyone ELSE can install without a Gatekeeper
   warning (`spctl` rejects the ad-hoc signature, as expected). Not needed locally.
3. **Stale spike container, leave it.** `~/Library/Containers/dev.valuev.chuteprobe.finder` is
   left over from the throwaway FinderSync probe. `rm -rf` on it returns `Operation not permitted`
   — containermanagerd owns it. Harmless, empty, and it costs nothing to ignore.

---

## DECISIONS (do not re-litigate)

- **FinderSync extension, not Services or Automator Quick Actions.** Both were built, both
  registered, neither ever appeared. The Quick Actions generator is now DELETED.
  Evidence: `/Users/sxope/Documents/2026/Development/37.chute/docs/08-MACOS-COMPATIBILITY.md`.
- **No Xcode, no $99 yet.** Proved sufficient: the extension registers, loads and runs ad-hoc signed.
- **No XCTest.** `swift run chutetests`, an executable with an assert harness. `swift test` needs Xcode.
- **Zero third-party dependencies.** Never add `.package(` to Package.swift.
- **Zero telemetry.** Positioning asset with this audience. `docs/09-GTM-DECISIONS.md` #8.
- **`.sortedKeys` in HookInstaller is deliberate.** Without it the file reshuffles every run —
  Swift dictionaries are unordered and hash seeds randomised. Verified 5/5 red without it.
- **The appex spawns `chute` directly.** The feared appex → IPC → host-app redesign is NOT needed:
  measured inside the loaded extension, the spawn is permitted, its writes reach the real
  filesystem, and it writes the real pasteboard.
- **Price is $9 one-time, decided 2026-08-26.** Below PopClip, not a subscription, less than one
  hour of the time it returns. $19 was rejected until the app is signed and auto-updating; the
  trigger to raise it is 20 sales with no price objection. `docs/09-GTM-DECISIONS.md` §5.
- **Onboarding detects and verifies; it never instructs.** macOS 15.0–15.1 removed the Extensions
  pane, so "tick the box in System Settings" pointed at a screen that did not exist.

---

## TRAPS (each cost real time)

- **A FinderSync appex needs THREE Info.plist keys the obvious ones don't include**: `LSUIElement`,
  `NSPrincipalClass` = `NSApplication`, and an empty `NSExtensionAttributes`. Without them
  `pluginkit` silently never lists it — no error, anywhere. Found by reading Google Drive's plist.
- **The appex must be signed WITH sandbox entitlements**, from
  `/Users/sxope/Documents/2026/Development/37.chute/Resources/ChuteFinder.entitlements`, and signed
  BEFORE the outer app. Signing the app first and then touching the appex invalidates the app.
- **`NSHomeDirectory()` inside the appex is the CONTAINER**, not `/Users/<you>`. Every path handed
  to `chute` must be absolute and come from Finder. A `~`-relative write lands in the container and
  the command still exits 0 — a silent wrong-place success, the worst failure shape there is.
- **An appex registers when its HOST APP IS LAUNCHED**, not on `pluginkit -a` or `lsregister -f`.
- **`NSExtensionMain()` is not callable from Swift.** Build with `-Xlinker -e -Xlinker
  _NSExtensionMain` and NO `main.swift`.
- **`pgrep -x Terminal` NEVER matches Terminal.app.** Use `ps -Ao comm` + path fragment.
  `isAppRunning` at `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/TerminalAppAdapter.swift:103`.
- **`ps -o tty=` prints `??`, not empty**, when there is no controlling terminal. Whitelist
  `[a-zA-Z0-9]` instead — `HookState.liveTTYs()` at
  `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/HookState.swift:72`.
- **APFS is case-INSENSITIVE.** `Contents/MacOS/Chute` and `.../chute` are the same file. The app
  executable is named `ChuteApp` for this reason.
- **`git stash create` EXCLUDES untracked files.** `checkpoint` uses a private `GIT_INDEX_FILE`.
- **`git log origin/<branch>..HEAD` returns 0 when the branch was never pushed** — the error is
  suppressed and silence reads as success. Verify with `git ls-remote --heads origin <branch>`.
- **The installed CLI is a COPY inside the app bundle.** After any Swift change run
  `./Scripts/build-app.sh && ./Scripts/install.sh`, or `~/.local/bin/chute` stays stale.
- **`./Scripts/uninstall.sh` deletes `~/.chute`** — hook state included. Harmless (hooks recreate
  it), but a `sessions` run straight afterwards reports everything as `working`.
- **`log show --predicate '…'` breaks under zsh** in this harness. Put it in a `.sh` file and
  `bash` it.

---

## OPEN QUESTIONS FOR THE HUMAN
1. **Buy the $99 Developer ID?** Only gates other people installing without a Gatekeeper warning.
   Nothing in the code waits on it.

---

## SCOREBOARD
21 defects caught across the session; 19 originated in the plan or the controller's instructions,
0 were agent implementation errors, 2 were introduced BY fixes to earlier defects, 2 planned tests
were placebos. What found them: adversarial review questions, agents refusing to fake a red run,
reading a working competitor off disk, and RUNNING commands instead of reasoning about them.
The three Finder-extension blockers were all found by the last of those.
