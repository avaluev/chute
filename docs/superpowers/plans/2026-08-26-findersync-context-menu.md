# Finder Context Menu (FinderSync) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A top-level `Chute ▸` item in the Finder context menu — on files, folders and empty window background — replacing three failed attempts at Services and Automator Quick Actions.

**Architecture:** A `FIFinderSync` app extension (`ChuteFinder.appex`) embedded in `Chute.app/Contents/PlugIns/`. It observes the root volume, builds an `NSMenu`, and shells out to the existing `chute` binary. The engine is untouched.

**Tech Stack:** Swift 5.10, SwiftPM, FinderSync.framework (present in the Command Line Tools SDK — verified), `codesign`, `pluginkit`. **No Xcode.**

**Spec:** `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/specs/2026-08-26-findersync-context-menu-design.md`

## Global Constraints

- **Zero third-party dependencies.**
- Swift tools version **5.10**, platform floor **macOS 13**.
- **Sign inner-to-outer.** `codesign` the `.appex` *before* the `.app`. Signing the outer bundle first and then modifying the inner one invalidates the outer signature and the extension silently refuses to load.
- **The extension must observe a directory or it shows no menu, silently.** `FIFinderSyncController.default().directoryURLs` must be set in `init()`, before anything else.
- The extension must locate `chute` relative to its own bundle, never via `PATH` — an appex does not reliably inherit the user's `PATH`.
- Never modify anything under `Sources/ChuteCore` — this subsystem adds a surface, not engine behaviour. All 55 unit and 39 smoke checks must stay green.

## Parallel Dispatch Map

| Wave | Tasks | Model | Why |
|---|---|---|---|
| **GATE** | Task 1 | **Sonnet** | Feasibility gate. If ad-hoc registration fails, everything after it is void. Nothing else may start until this is green. |
| A | Task 2 | **Sonnet** | The menu logic and selection handling. |
| B | Tasks 3, 4 | **Haiku** ×2 | Disjoint, mechanical: build/sign scripts, and deleting the dead Quick Actions code. |

**Task 1 is a hard gate, not a suggestion.** If `pluginkit` will not register an ad-hoc-signed appex after Step 6, **stop the whole plan**, report it, and tell the founder to install Xcode. Do not spend a second hour guessing at Apple's packaging rules — that failure mode is precisely what produced this plan.

**Dispatch brief for every subagent (paste verbatim):**
> Spec: `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/specs/2026-08-26-findersync-context-menu-design.md`
> Plan: `/Users/sxope/Documents/2026/Development/37.chute/docs/superpowers/plans/2026-08-26-findersync-context-menu.md`
> Do ONLY your task. Touch ONLY the files it lists. Verify with the exact commands given and report the real output, not a summary.

---

### Task 1: Feasibility gate — a registering appex  ·  **Model: Sonnet**

Prove an ad-hoc-signed FinderSync extension registers before writing any menu code.

**Files:**
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Package.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteFinder/main.swift`
- Create: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteFinder/ChuteFinderSync.swift`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/build-app.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: a registered extension with bundle id `dev.valuev.chute.finder` and the class `ChuteFinderSync`, which Task 2 fills with real menu items.

- [ ] **Step 1: Add the extension target**

In `Package.swift`, add to `targets:` after the `ChuteApp` line:

```swift
        .executableTarget(name: "ChuteFinder"),
```

`ChuteFinder` has no dependency on `ChuteCore`: an appex should load as little as possible, and it only needs to spawn a process.

- [ ] **Step 2: Write the extension entry point**

`Sources/ChuteFinder/main.swift`:

```swift
import Foundation

// An app extension's executable hands control to the extension host, which instantiates
// NSExtensionPrincipalClass from Info.plist. There is no app run loop here.
NSExtensionMain()
```

- [ ] **Step 3: Write the minimal principal class**

`Sources/ChuteFinder/ChuteFinderSync.swift`:

```swift
import Cocoa
import FinderSync

@objc(ChuteFinderSync)
class ChuteFinderSync: FIFinderSync {
    override init() {
        super.init()
        // An extension observing nothing shows no menu, silently. This is THE
        // FinderSync mistake. Observing the root volume is what Google Drive does.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "Chute")
        let probe = NSMenuItem(title: "Chute is alive", action: #selector(probe(_:)), keyEquivalent: "")
        probe.target = self
        menu.addItem(probe)
        return menu
    }

    @objc func probe(_ sender: AnyObject?) {
        NSLog("Chute: menu action fired")
    }
}
```

- [ ] **Step 4: Teach build-app.sh to assemble the appex**

In `Scripts/build-app.sh`, insert after the two `cp` lines that copy `ChuteApp` and `chute`:

```bash
# ---- Finder extension -------------------------------------------------------
APPEX="$APP/Contents/PlugIns/ChuteFinder.appex"
mkdir -p "$APPEX/Contents/MacOS"
cp "$ROOT/.build/release/ChuteFinder" "$APPEX/Contents/MacOS/ChuteFinder"

cat > "$APPEX/Contents/Info.plist" <<APPEXPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>ChuteFinder</string>
  <key>CFBundleDisplayName</key><string>Chute</string>
  <key>CFBundleIdentifier</key><string>dev.valuev.chute.finder</string>
  <key>CFBundleExecutable</key><string>ChuteFinder</string>
  <key>CFBundlePackageType</key><string>XPC!</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$VERSION</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionPointIdentifier</key><string>com.apple.FinderSync</string>
    <key>NSExtensionPrincipalClass</key><string>ChuteFinderSync</string>
  </dict>
</dict>
</plist>
APPEXPLIST
plutil -lint "$APPEX/Contents/Info.plist" >/dev/null
```

Then replace the existing single `codesign` line with inner-to-outer signing:

```bash
# Order matters: signing the app first, then touching the appex, invalidates the app.
codesign --force --sign - "$APPEX" 2>/dev/null || echo "note: appex ad-hoc signing unavailable"
codesign --force --sign - "$APP"   2>/dev/null || echo "note: app ad-hoc signing unavailable"
```

- [ ] **Step 5: Build**

Run: `./Scripts/build-app.sh`
Expected: `built …/dist/Chute.app`, and `ls dist/Chute.app/Contents/PlugIns/` shows `ChuteFinder.appex`.

- [ ] **Step 6: THE GATE — does macOS register it?**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
./Scripts/install.sh
pluginkit -a "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>&1
pluginkit -m -p com.apple.FinderSync
codesign -vvv "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>&1 | tail -3
```

Expected: `pluginkit -m -p com.apple.FinderSync` lists `dev.valuev.chute.finder` alongside Google Drive's entry.

**If it does not appear:** STOP. Do not continue to Task 2. Report the exact `pluginkit` and `codesign` output and recommend installing Xcode. This is the planned failure path, not a defeat.

- [ ] **Step 7: Enable and confirm visually**

Open System Settings → Privacy & Security → Extensions → Finder, tick **Chute**, then `killall Finder`.
Right-click any folder. Expected: a top-level `Chute is alive` item.

Deep link: `open "x-apple.systempreferences:com.apple.ExtensionsPreferences"`

- [ ] **Step 8: Confirm the engine is untouched**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests && ./Scripts/smoke.sh`
Expected: 55 assertions, 39 checks, zero failures.

- [ ] **Step 9: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Package.swift Sources/ChuteFinder/ Scripts/build-app.sh
git commit -m "feat: FinderSync extension skeleton, registering with an ad-hoc signature"
```

---

### Task 2: The real menu  ·  **Model: Sonnet**  ·  Wave A

**Files:**
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteFinder/ChuteFinderSync.swift`

**Interfaces:**
- Consumes: the registered extension from Task 1.
- Produces: a `Chute ▸` submenu whose items invoke the `chute` CLI.

- [ ] **Step 1: Replace the probe with the real menu**

Overwrite `Sources/ChuteFinder/ChuteFinderSync.swift`:

```swift
import Cocoa
import FinderSync

@objc(ChuteFinderSync)
class ChuteFinderSync: FIFinderSync {

    /// (title, chute subcommand, needs a selection)
    static let actions: [(String, [String], Bool)] = [
        ("Copy Paths for Prompt",     ["paths"],                 true),
        ("Bundle Context (XML)",      ["bundle"],                true),
        ("Copy Redacted",             ["redact"],                true),
        ("New File from Clipboard",   ["new", "--reveal"],       false),
        ("Unpack Markdown Here",      ["unpack"],                false),
        ("Checkpoint Before Agent",   ["checkpoint"],            false),
        ("Sandbox + Agent (yolo)",    ["sandbox", "--yolo"],     false),
        ("Open Terminal Here",        ["open"],                  false),
    ]

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    /// An appex does not reliably inherit PATH, so resolve the binary from our own bundle:
    /// …/Chute.app/Contents/PlugIns/ChuteFinder.appex → up 3 → Contents/MacOS/chute
    private var chuteBinary: String {
        Bundle.main.bundleURL
            .deletingLastPathComponent()   // PlugIns
            .deletingLastPathComponent()   // Contents
            .appendingPathComponent("MacOS/chute")
            .path
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let root = NSMenu(title: "Chute")
        let parent = NSMenuItem(title: "Chute", action: nil, keyEquivalent: "")
        let sub = NSMenu(title: "Chute")

        let hasSelection = !(FIFinderSyncController.default().selectedItemURLs()?.isEmpty ?? true)

        for (index, action) in Self.actions.enumerated() {
            if action.2 && !hasSelection { continue }
            let item = NSMenuItem(title: action.0, action: #selector(run(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            sub.addItem(item)
        }

        root.addItem(parent)
        root.setSubmenu(sub, for: parent)
        return root
    }

    @objc func run(_ sender: NSMenuItem) {
        let (_, argv, needsSelection) = Self.actions[sender.tag]
        let controller = FIFinderSyncController.default()

        var args = argv
        if needsSelection {
            let urls = controller.selectedItemURLs() ?? []
            guard !urls.isEmpty else { return }
            args += urls.map(\.path)
        } else {
            let target = controller.selectedItemURLs()?.first ?? controller.targetedURL()
            guard let target else { return }
            var dir = target.path
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: dir, isDirectory: &isDir), !isDir.boolValue {
                dir = (dir as NSString).deletingLastPathComponent
            }
            // `unpack`, `new` and `sandbox` take --dir; `checkpoint` and `open` take a positional.
            args += (argv[0] == "checkpoint" || argv[0] == "open") ? [dir] : ["--dir", dir]
        }
        launch(args)
    }

    private func launch(_ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: chuteBinary)
        p.arguments = args
        let err = Pipe()
        p.standardError = err
        p.standardOutput = Pipe()
        do { try p.run() } catch {
            NSLog("Chute: cannot run %@: %@", chuteBinary, error.localizedDescription)
            return
        }
        // Notify from the extension so a silent action does not read as "nothing happened".
        DispatchQueue.global(qos: .utility).async {
            let data = err.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            let message = String(decoding: data, as: UTF8.self)
                .split(separator: "\n").last.map(String.init) ?? "done"
            let safe = message.replacingOccurrences(of: "\"", with: "'")
            let script = "display notification \"\(safe)\" with title \"Chute\""
            let osa = Process()
            osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osa.arguments = ["-e", script]
            try? osa.run()
        }
    }
}
```

- [ ] **Step 2: Rebuild and reinstall**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
./Scripts/build-app.sh && ./Scripts/install.sh && killall Finder
```

- [ ] **Step 3: Verify the extension is still registered after the change**

Run: `pluginkit -m -p com.apple.FinderSync`
Expected: `dev.valuev.chute.finder` still listed. If it vanished, the signing order in `build-app.sh` regressed — the appex must be signed before the app.

- [ ] **Step 4: Verify with a real right-click**

1. Select 3 files in `/Users/sxope/Desktop/Chute Test` → right-click → `Chute ▸ Copy Paths for Prompt` → paste. Expect 3 absolute paths and a notification.
2. Right-click the folder itself → `Chute ▸ New File from Clipboard` (copy some markdown first). Expect a correctly named file, revealed.
3. Right-click **empty background** inside the folder → `Chute ▸` appears with only the no-selection actions.

- [ ] **Step 5: Check the log if an action does nothing**

Run: `log stream --predicate 'process == "ChuteFinder"' --level debug`
Then click a menu item. Expect no `cannot run` lines.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Sources/ChuteFinder/ChuteFinderSync.swift
git commit -m "feat: Chute submenu in the Finder context menu, on items and on empty background"
```

---

### Task 3: Install, uninstall and docs  ·  **Model: Haiku**  ·  Wave B

**Files:**
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/uninstall.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/README.md`

**Interfaces:**
- Consumes: the appex built by Tasks 1–2.
- Produces: nothing other tasks depend on.

- [ ] **Step 1: Register the extension on install**

In `Scripts/install.sh`, after the `lsregister -f` line, add:

```bash
pluginkit -a "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
```

And replace the closing help text's Finder line with:

```
Finder right-click → Chute ▸ …

Enable it once: System Settings → Privacy & Security → Extensions → Finder → ☑ Chute
  open "x-apple.systempreferences:com.apple.ExtensionsPreferences"
```

- [ ] **Step 2: Remove the extension on uninstall**

In `Scripts/uninstall.sh`, before the `rm -rf "$HOME/Applications/Chute.app"` line:

```bash
pluginkit -r "$HOME/Applications/Chute.app/Contents/PlugIns/ChuteFinder.appex" 2>/dev/null || true
```

- [ ] **Step 3: Update the README install section**

Replace the sentence beginning "**Three ways to use it:**" with:

```markdown
**Three ways to use it:** right-click in Finder → **Chute ▸**, the `⌥⌘N` hotkey anywhere, or the
`chute` CLI.

The Finder menu needs one tick the first time: System Settings → Privacy & Security → Extensions
→ Finder → ☑ Chute.
```

- [ ] **Step 4: Verify install and uninstall are clean**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
./Scripts/uninstall.sh && pluginkit -m -p com.apple.FinderSync | grep -c chute
./Scripts/install.sh   && pluginkit -m -p com.apple.FinderSync | grep -c chute
```
Expected: `0` then `1`.

- [ ] **Step 5: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add Scripts/install.sh Scripts/uninstall.sh README.md
git commit -m "chore: register and deregister the Finder extension on install and uninstall"
```

---

### Task 4: Delete the dead Quick Actions code  ·  **Model: Haiku**  ·  Wave B

Roughly 180 lines of a mechanism proven not to work. Keeping a broken fallback is worse than having none.

**Files:**
- Delete: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/install-quickactions.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh`
- Modify: `/Users/sxope/Documents/2026/Development/37.chute/docs/02-FUNCTIONAL-REQUIREMENTS.md`

**Interfaces:**
- Consumes: nothing. Runs only after Task 2 proves the replacement works.
- Produces: nothing.

- [ ] **Step 1: Remove the installed workflows from this Mac**

```bash
rm -rf "$HOME/Library/Services/Chute"*.workflow
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
killall Finder 2>/dev/null || true
ls "$HOME/Library/Services/" | grep -c Chute
```
Expected: `0`.

- [ ] **Step 2: Delete the generator and its call site**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git rm Scripts/install-quickactions.sh
```

In `Scripts/install.sh`, delete the line `"$ROOT/Scripts/install-quickactions.sh"`.

- [ ] **Step 3: Keep uninstall cleaning old installs for one release**

Confirm `Scripts/uninstall.sh` still contains the `find "$HOME/Library/Services" -maxdepth 1 -name "Chute*"` line. Leave it — people who installed the previous version need it. Add above it:

```bash
# Legacy: v0.1 installed Automator Quick Actions. Removed here so old installs clean up.
```

- [ ] **Step 4: Fix the FE table**

In `docs/02-FUNCTIONAL-REQUIREMENTS.md`, `FE-01` already describes the FinderSync extension. Confirm no row still references `install-quickactions.sh`:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
grep -rn "install-quickactions" docs/ README.md Scripts/ || echo "clean"
```
Expected: `clean`.

- [ ] **Step 5: Verify nothing broke**

Run: `cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/install.sh && swift run chutetests && ./Scripts/smoke.sh`
Expected: install completes without the deleted script, 55 assertions, 39 checks.

- [ ] **Step 6: Commit**

```bash
cd /Users/sxope/Documents/2026/Development/37.chute
git add -A
git commit -m "chore: delete the Automator Quick Actions generator, superseded by the FinderSync extension"
```

---

## Self-Review

**Spec coverage:** appex architecture → Task 1. `directoryURLs` trap → Tasks 1 and 2, both in `init()`. Menu shape and selection handling → Task 2. Binary resolution relative to the bundle → Task 2. Inner-to-outer signing → Task 1 Step 4, re-verified in Task 2 Step 3. Registration check → Task 1 Step 6 and Task 3 Step 4. Deleting the Quick Actions code → Task 4. Hard stop on registration failure → Task 1 Step 6. Deferred Developer ID and DMG → out of scope by decision, recorded in the spec and `docs/06-BACKLOG.md`.

**Placeholder scan:** none. Every step carries the actual command or the actual code.

**Type consistency:** `ChuteFinderSync` is the `NSExtensionPrincipalClass` string in the Info.plist (Task 1 Step 4) and the `@objc(ChuteFinderSync)` class name in both Task 1 Step 3 and Task 2 Step 1 — they must stay identical or the extension loads and does nothing. `dev.valuev.chute.finder` is used identically in Task 1 Steps 4 and 6, and Task 3 Step 4.
