# HANDOFF — Chute — 2026-08-27

STATE: `main` @ `cea476c` · build green · unit 392/392 (`swift run chutetests`) · e2e 88/88
       (`./Scripts/smoke.sh`) · `chute doctor` 10/10 · app running · extension loaded
       (`~/.chute/extension-loaded.txt` → `loaded · 7 actions`) · signed `Authority=Chute Local Dev`

## ONE-LINE GOAL
Your agents should not cost you attention: turn a Finder selection into agent-ready context, and
tell you which agent is waiting.

---

## BUSINESS MODEL — decided 2026-08-27, do not re-litigate

**Open core.** The `chute` CLI is MIT and installable by Homebrew; **Chute.app is $19 one-time**
through Paddle. The CLI is 2,000 lines anyone could rewrite; the sandboxed Finder integration is
the moat, and three of its four load-bearing facts are documented nowhere but this repo.

- **Buy the $99 Apple Developer ID.** Without notarisation every buyer meets a Gatekeeper wall,
  so you would be charging for a worse install than the free alternative. Six sales pay for it.
- **Support has no inbox.** "Report a Problem…" builds a redacted diagnostic report, copies it and
  opens a prefilled public GitHub issue. One answer then serves everyone who searches it.
- **Positioning line:** *your agents shouldn't cost you attention* — not "drop context into your
  agent", which describes the mechanism rather than the pain.
- Launch order: notarised build → Homebrew tap + README GIFs → technical write-up → Show HN →
  Product Hunt two weeks later. Details in `docs/09-GTM-DECISIONS.md`.

---

## DONE THIS SESSION (each proved by a command that was RUN)

- **The Finder menu works.** Every click used to be a silent no-op: a FinderSync menu is drawn by
  Finder and only plain properties survive that boundary — `tag` does, `representedObject` comes
  back nil. Dispatch is by tag now.
- **The menu is the five MVP actions**, in Apple's wording, with tree depths in a submenu:
  Copy Full Paths (n) · Copy Folder Tree ▸ 2/4/Everything · New Markdown File ·
  New Markdown File from Clipboard · Open in Terminal.
- **Thousands of files.** `--files-from` puts the selection in a file rather than in ARG_MAX
  arguments. Proved with 3000 through the CLI and 1200 through the extension → app handoff.
- **Killing a server works.** `lsof` returns the LEAF of a runner tree, so killing it let the npm
  supervisor respawn the port — "I click Stop It and nothing happens". Now it climbs to the runner
  root and signals the subtree. Verified against a plain and a supervised server.
- **Native notifications** through `UNUserNotificationCenter`, posted by Chute with Chute's icon —
  they used to arrive as *Script Editor* with a pen icon and a Show button that opened Script Editor.
- **New icon**, with per-size artwork: below 64pt the cards turn to mush and two converging strokes
  read as a checkmark, so small sizes draw a simplified hopper.
- **Menu bar stopped duplicating Finder.** The file actions needed a Finder selection they never
  had there. ⌥⌘N now pops the session switcher.
- **Setup check went silent.** It no longer appears to say everything is fine; it repairs what it
  can, then shows only what needs a human.
- **`Open in Terminal` stopped echoing `cd '/path'`** as the first line of every new shell.
- **Security pass** — four findings, all fixed (see below).
- **Dead code removed**: `ServicesProvider` was registered at launch and unreachable, because the
  app has declared no `NSServices` since Quick Actions was withdrawn. `main.swift` 402 → 187 lines,
  split into Notify / RequestInbox / ServersMenu.
- **CI on macOS 13, 14 and 15** (`.github/workflows/macos-matrix.yml`) with `CHUTE_HEADLESS=1`.

## IN FLIGHT
- Nothing. Tree clean.

## NEXT
1. **Buy the Developer ID**, then notarise: `xcrun notarytool submit --keychain-profile … dist/Chute.zip`
   followed by `xcrun stapler staple`. Everything in the GTM plan assumes a clean install.
2. **Terminal vitals** — CPU, memory and temperature per session, agreed as sub-project 4.
3. **The website.** `docs/CloudflareDomainsPrice.md` is 56 variations of the wrong word (`chut`,
   plus `.plumbing`, `.surgery`). Check `usechute.com`, `chute.tools`, `getchute.app`, `chute.sh`.
4. **Uninstall parity** — `Scripts/uninstall.sh` removes the app, CLI, `~/.chute` and the appex
   registration, but leaves `~/.claude/settings.json` hooks in place. Decide: prompt, or leave.

---

## DEEP REVIEW — code

**Shape.** 5,080 lines of Swift across 26 core files, no file over 260 lines, zero third-party
dependencies. Engine (`ChuteCore`) holds no AppKit; every surface — CLI, app, extension — is a thin
adapter over it. That separation is why the same action table can drive the Finder menu and the
tests without a second copy.

**What was wrong and is now fixed**
- Two hand-written copies of the action list had already drifted into naming different actions.
  One table (`ChuteActions.all`) now feeds the Finder menu, the app and `chute finder-actions --json`,
  which is what the end-to-end suite executes — so a menu item that cannot work fails in CI, not in
  a user's hands.
- `main.swift` was doing five jobs at 402 lines.
- ~100 lines of unreachable Services code.

**What to watch**
- `Sources/chute/Commands/AgentCommands.swift:203` mixes ports, sandbox, env and terminal launching
  in one file. It is four features, and the next one added should split it.
- `Shell.run` resolves tools through `/usr/bin/env`, so a poisoned `PATH` substitutes `git`.
  Accepted: same-user compromise already, and pinning paths breaks `claude`/`gh` discovery.
- The assert harness has no test isolation — suites share the process and the real clipboard.
  It has caught real bugs; the risk is a future test that leaves state behind.

## DEEP REVIEW — security

| Sev | Finding | Fix |
|---|---|---|
| HIGH | The request inbox was unauthenticated local IPC: a SANDBOXED extension writes it and an UNSANDBOXED app executes it, so anything able to write the directory got the sandbox lifted for free. It was `drwxr-xr-x`. | `0700`, tightened in place on upgrade; a request is refused unless it is a regular file owned by this uid with no group/other write bit; `dir` must be an absolute existing directory; relative file paths dropped. |
| MEDIUM | `unpack` could be walked out of its folder through an existing symlink: with `src -> /etc`, `src/passwd` passes the `..` check and still escapes. | `MarkdownUnpack.staysInside` resolves both sides and compares, per file, at write time. |
| MEDIUM | Redaction missed private key blocks and credentials inside a URL. | Both masked. |
| LOW | The osascript notification fallback escaped quotes but not backslashes, so a trailing backslash escaped its own closing quote and the rest parsed as AppleScript. | Backslash escaped first; the selection list file is `0600` and deleted after use. |

**Reviewed and sound:** `shellQuote` then AppleScript-escape ordering in `launchTerminal`; the
static hook command written into `settings.json`; `env inject` (0600, refuses an untracked `.env`,
prints key names never values); `LocalServers.kill`; `unpack`'s absolute/`..` rejection.

## DEEP REVIEW — Apple platform design

**Good**: `LSUIElement` menu-bar app with no Dock icon; native notifications with the app's own
identity; per-size icon artwork; menu items are verb-first title case with no jargon; destructive
items name their target ("Stop It (kill 55868)"); actions that cannot work in context are hidden
rather than offered and failed.

**Still off-guideline**
- The status item shows a text glyph (`⤓ 3`). Apple's own menu-bar items use a template image, so
  Chute will not tint correctly in every menu-bar appearance. Move to an `NSImage` marked
  `isTemplate` with a badge.
- `Refresh ⌘R` and `Quit Chute ⌘Q` are declared with key equivalents in a status menu, where they
  only work while the menu is open. Harmless, but it implies a global shortcut that does not exist.
- The first-run window is a bare `NSWindow` of stacked rows; an `NSAlert` is the HIG-correct shape
  for "one thing needs your permission".
- No Settings window and no About panel. A paid app needs both before launch.

## HOW TO TEST OTHER macOS VERSIONS WITH ONE LAPTOP

1. **CI is your version matrix.** `.github/workflows/macos-matrix.yml` runs the build, 392 unit
   assertions and the headless e2e suite on macOS 13, 14 and 15. Free for public repos, which
   open-core makes you anyway. Catches API removals, `lsof`/`ps`/`osascript` output changes, Swift
   drift, SDK breakage. Cannot catch: the extension loading, TCC prompts, notification delivery.
2. **A VM for the desktop half.** Apple Silicon virtualises macOS 12+ through
   Virtualization.framework — VirtualBuddy (free) or UTM. The licence allows two VMs per host.
   Finder extensions DO load in a VM and TCC prompts behave normally, so this is where you verify
   the right-click menu on a version you cannot boot natively.
3. **Keep the floor honest.** `Package.swift` declares `.macOS(.v13)`. There are currently NO
   `@available` guards in the codebase because every API used exists at 13 — verified by audit.
   Adding a newer API without a guard is the failure mode to watch, and the matrix catches it.
4. **The risk is behaviour, not API.** macOS 15.0–15.1 removed the Extensions settings pane;
   14+ tightened App Management provenance (the "differs from previously opened versions" prompt).
   Both are recorded in `docs/08-MACOS-COMPATIBILITY.md`.

---

## DECISIONS (do not re-litigate)
- **Open core, $19 app, MIT CLI, buy the $99 Developer ID.** See above.
- **The extension never does the work.** It writes a request; ChuteApp carries it out. Measured:
  `git` refuses to run in a sandbox at all, launching an app is denied (-54), AppleScript to
  Terminal is denied (-10004).
- **Sign with a stable identity.** `Scripts/sign-identity.sh`. Ad-hoc signatures change identity
  every build, which invalidates the extension's sandbox container and the menu silently vanishes.
- **No XCTest** (ships with Xcode). **No third-party dependencies.** **No telemetry.**
- **Price $19**, revisit at v1.0 once signed and auto-updating.

## TRAPS (each cost real time)
- **`representedObject` does not survive the trip to Finder.** Use `tag`. Silent no-op otherwise.
- **A sandboxed appex's container ACL pins the code identity that created it.** An ad-hoc rebuild
  is a new identity, so the extension stops starting and the menu disappears with no error
  anywhere. `Scripts/install.sh` repairs it; a stable identity prevents it.
- **`git` cannot run inside an App Sandbox** — it is an `xcrun` shim: "cannot be used within an App
  Sandbox".
- **An appex registers when its HOST APP IS LAUNCHED**, not on `pluginkit -a`.
- **`NSExtensionMain` is not callable from Swift** — link with `-Xlinker -e -Xlinker _NSExtensionMain`
  and no `main.swift`.
- **`NSHomeDirectory()` in the extension is the container**, not `/Users/<you>`. Absolute paths only.
- **The app bootstrap must stay LAST in `main.swift`** — top-level code runs in order. Deleting a
  class above it once took `app.run()` with it, and the suite reported the missing app as a SKIP.
- **`pgrep -x Terminal` never matches Terminal.app**; use `ps -Ao comm` and a path fragment.
- **`ps -o tty=` prints `??`**, not empty. Whitelist alphanumerics.
- **APFS is case-insensitive**: the app executable is `ChuteApp` so it cannot collide with `chute`.
- **`git log origin/<branch>..HEAD` returns 0 when the branch was never pushed** — verify with
  `git ls-remote --heads origin <branch>`.
- **The installed CLI is a COPY inside the app bundle.** After any Swift change:
  `./Scripts/build-app.sh && ./Scripts/install.sh`.
- **Another agent may be working in this tree.** A session here switched branches mid-flight and a
  commit landed on `fix/kill-the-tree-not-the-leaf` instead of `main`. Check `git branch --show-current`
  before committing.

## OPEN QUESTIONS FOR THE HUMAN
1. **Domain** — none of the 56 in `docs/CloudflareDomainsPrice.md` spell the product's name.
2. **Uninstall and the hooks** — should `uninstall.sh` remove the Claude Code hooks it installed?
