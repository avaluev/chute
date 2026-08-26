import AppKit
import Carbon.HIToolbox
import ChuteCore

/// Every action is the CLI. The app is a surface, never a second implementation.
struct Action {
    let title: String
    let key: String
    let run: () -> Void
}

let chuteBinary: String = {
    let bundled = Bundle.main.bundlePath + "/Contents/MacOS/chute"
    if FileManager.default.isExecutableFile(atPath: bundled) { return bundled }
    return Shell.which("chute") ?? "/usr/local/bin/chute"
}()

@discardableResult
func chute(_ args: [String], cwd: String? = nil) -> ShellResult {
    Shell.run(chuteBinary, args, cwd: cwd)
}

func notify(_ title: String, _ body: String) {
    Shell.launch("osascript", ["-e",
        "display notification \"\(body.replacingOccurrences(of: "\"", with: "'"))\" with title \"\(title)\""])
}

let actions_list: [Action] = [
    Action(title: "Copy Paths for Prompt", key: "1") {
        let sel = FinderBridge.selection()
        guard !sel.isEmpty else { return notify("Chute", "Nothing selected in Finder") }
        chute(["paths"] + sel)
        notify("Chute", "\(sel.count) path(s) copied")
    },
    Action(title: "Bundle Context (XML)", key: "2") {
        let sel = FinderBridge.selection()
        guard !sel.isEmpty else { return notify("Chute", "Nothing selected in Finder") }
        let r = chute(["bundle"] + sel)
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "New File from Clipboard", key: "3") {
        let r = chute(["new", "--dir", FinderBridge.currentFolder(), "--reveal"])
        notify("Chute", r.ok ? "Created \((r.out.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).lastPathComponent)"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "Unpack Markdown Here (preview)", key: "4") {
        let r = chute(["unpack", "--dir", FinderBridge.currentFolder()])
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "Sandbox + Agent (yolo)", key: "5") {
        chute(["sandbox", "--dir", FinderBridge.currentFolder(), "--yolo"])
    },
    Action(title: "Checkpoint Before Agent", key: "6") {
        let r = chute(["checkpoint", FinderBridge.currentFolder()])
        notify("Chute", r.ok ? "Snapshot: \(r.out.trimmingCharacters(in: .whitespacesAndNewlines))"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "Open Terminal Here", key: "7") {
        chute(["open", FinderBridge.currentFolder()])
    },
    Action(title: "Copy Redacted", key: "8") {
        let r = chute(["redact"])
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
]

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    var lastSessions: [Session] = []
    var watcher: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "Chute — drop context into your agent"
        // Placeholder menu, populated by menuWillOpen on click — no AppleScript on the launch path.
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        NSApp.servicesProvider = ServicesProvider()
        NSUpdateDynamicServices()
        registerHotKey()
        FirstRunWindow.showIfNeeded()
        startWatching()
        updateBadgeFromHooks()
    }

    /// Catches discover() failures instead of collapsing them into an unexplained empty menu:
    /// Terminal simply not running is not a problem, but a denied Automation permission is a
    /// fixable one, and the menu should say so.
    func discoverSessionsForMenu() -> (sessions: [Session], problem: String?) {
        do {
            let sessions = try TerminalAppAdapter().discover(hooks: HookState.readAll(), now: Date())
                .sorted { ($0.state, $0.project) < ($1.state, $1.project) }
            return (sessions, nil)
        } catch let e as TerminalError {
            switch e {
            case .notRunning:  return ([], nil)              // not a problem; nothing to show
            default:           return ([], "\(e)")           // a real failure, say so
            }
        } catch {
            return ([], "\(error)")
        }
    }

    func appendStandardItems(to menu: NSMenu) {
        let actionsMenu = NSMenu()
        for (i, a) in actions_list.enumerated() {
            let item = NSMenuItem(title: a.title, action: #selector(fire(_:)), keyEquivalent: "")
            item.target = self; item.tag = i
            actionsMenu.addItem(item)
        }
        let actionsItem = NSMenuItem(title: "Chute Actions", action: nil, keyEquivalent: "")
        menu.addItem(actionsItem)
        menu.setSubmenu(actionsMenu, for: actionsItem)

        let setupItem = NSMenuItem(title: "Setup Check…", action: #selector(openSetup), keyEquivalent: "")
        setupItem.target = self
        menu.addItem(setupItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Quit Chute",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    /// Only for contexts where menuWillOpen does not apply — refresh() and the ⌥⌘N HUD popup —
    /// because there is no live NSMenu already being tracked by AppKit to populate in place.
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        let (sessions, problem) = discoverSessionsForMenu()
        statusItem.button?.title = SessionMenu.badge(for: sessions)
        lastSessions = sessions
        SessionMenu.populate(menu, sessions: sessions, problem: problem,
                             target: self, action: #selector(focusSession(_:)),
                             openSettings: #selector(openAutomationSettings))
        appendStandardItems(to: menu)
        return menu
    }

    @objc func openSetup() { FirstRunWindow.show() }

    @objc func openAutomationSettings() {
        NSWorkspace.shared.open(URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }

    @objc func fire(_ sender: NSMenuItem) {
        let action = actions_list[sender.tag]
        DispatchQueue.global(qos: .userInitiated).async { action.run() }
    }

    @objc func focusSession(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String,
              let s = lastSessions.first(where: { $0.key == key }) else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            try? TerminalAppAdapter().focus(s)
        }
    }

    @objc func refresh() { statusItem.menu = buildMenu() }

    // AppleScript runs ONLY when the menu opens (menuWillOpen) — the user has just clicked,
    // so the cost is hidden by the click. Never called from the launch path.
    //
    // Populates the `menu` AppKit handed us IN PLACE. Do not build a new NSMenu and assign it to
    // statusItem.menu here: the object already being tracked for display is this one, so a swap
    // takes effect on the NEXT open, and the user sees the previous (stale) session list.
    func menuWillOpen(_ menu: NSMenu) {
        let (sessions, problem) = discoverSessionsForMenu()
        statusItem.button?.title = SessionMenu.badge(for: sessions)
        lastSessions = sessions
        SessionMenu.populate(menu, sessions: sessions, problem: problem,
                             target: self, action: #selector(focusSession(_:)),
                             openSettings: #selector(openAutomationSettings))
        appendStandardItems(to: menu)
    }

    /// Badge updates are event-driven off the hook directory — no polling, no AppleScript.
    func startWatching() {
        let dir = HookState.directory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let fd = open(dir, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend], queue: .main)
        src.setEventHandler { [weak self] in self?.updateBadgeFromHooks() }
        src.setCancelHandler { close(fd) }
        src.resume()
        watcher = src
    }

    func updateBadgeFromHooks() {
        let n = HookState.attention(HookState.readAll(),
                                    live: HookState.liveTTYs(),
                                    now: Date()).count
        statusItem.button?.title = n == 0 ? "⤓" : "⤓ \(n)"
    }

    /// FE-02 — ⌥⌘N pops the action list at the pointer, wherever you are.
    func registerHotKey() {
        var hotKeyID = EventHotKeyID(signature: OSType(0x43485554), id: 1)   // 'CHUT'
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            DispatchQueue.main.async { (NSApp.delegate as? AppDelegate)?.showHUD() }
            return noErr
        }, 1, &eventType, nil, nil)
        RegisterEventHotKey(UInt32(kVK_ANSI_N), UInt32(optionKey | cmdKey),
                            hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func showHUD() {
        let menu = buildMenu()
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

/// FE-01 — Finder right-click entries. Declared in Info.plist, handled here.
final class ServicesProvider: NSObject {
    private func paths(_ pboard: NSPasteboard) -> [String] {
        (pboard.readObjects(forClasses: [NSURL.self]) as? [URL])?.map(\.path) ?? []
    }

    @objc func copyPaths(_ pboard: NSPasteboard, userData: String?,
                         error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let p = paths(pboard)
        guard !p.isEmpty else { return notify("Chute", "No files received") }
        chute(["paths"] + p)
        notify("Chute", "\(p.count) path(s) copied")
    }

    @objc func bundleContext(_ pboard: NSPasteboard, userData: String?,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let p = paths(pboard)
        guard !p.isEmpty else { return notify("Chute", "No files received") }
        let r = chute(["bundle"] + p)
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @objc func newFromClipboard(_ pboard: NSPasteboard, userData: String?,
                                error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first.map { FileScan.isDirectory($0) ? $0 : ($0 as NSString).deletingLastPathComponent }
            ?? FinderBridge.currentFolder()
        let r = chute(["new", "--dir", dir, "--reveal"])
        notify("Chute", r.ok ? "Created \((r.out.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).lastPathComponent)"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @objc func unpackHere(_ pboard: NSPasteboard, userData: String?,
                          error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first ?? FinderBridge.currentFolder()
        let r = chute(["unpack", "--dir", FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent])
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @objc func sandboxHere(_ pboard: NSPasteboard, userData: String?,
                           error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first ?? FinderBridge.currentFolder()
        chute(["sandbox", "--dir", FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent, "--yolo"])
    }

    @objc func checkpointHere(_ pboard: NSPasteboard, userData: String?,
                              error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first ?? FinderBridge.currentFolder()
        let r = chute(["checkpoint", FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent])
        notify("Chute", r.ok ? "Snapshot: \(r.out.trimmingCharacters(in: .whitespacesAndNewlines))"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)     // LSUIElement — menu bar only, no Dock icon
app.run()
