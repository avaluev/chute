import AppKit
import Carbon.HIToolbox
import ChuteCore
import UserNotifications

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

/// Native notifications, posted by this app under its own name and icon.
///
/// The previous implementation shelled out to `osascript`, so every banner arrived attributed to
/// **Script Editor** — wrong name, wrong icon, and a "Show" button that opened Script Editor.
/// `UNUserNotificationCenter` posts as Chute. If the user has denied notifications, or the API is
/// unavailable, it falls back to the old path rather than going silent.
enum Notify {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { NSLog("ChuteApp: notification authorization failed: %@", error.localizedDescription) }
        }
    }

    /// Authorization is read fresh every time, never cached: the user may grant it in System
    /// Settings long after launch, and a cached "denied" would pin every banner to the ugly
    /// osascript fallback for the rest of the session.
    static func post(title: String, subtitle: String?, body: String) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized ||
                  settings.authorizationStatus == .provisional else {
                return fallback(title: title, body: body)
            }
            deliver(title: title, subtitle: subtitle, body: body)
        }
    }

    private static func deliver(title: String, subtitle: String?, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle { content.subtitle = subtitle }
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("ChuteApp: native notification refused: %@", error.localizedDescription)
                fallback(title: title, body: body)
            }
        }
    }

    /// The body is whatever the command said, and a command's output can contain a file name the
    /// user did not choose. Backslash FIRST: escaping quotes alone leaves a trailing backslash to
    /// escape the closing quote, and everything after it is then read as AppleScript, not text.
    private static func fallback(title: String, body: String) {
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "'")
        }
        Shell.launch("osascript", ["-e",
            "display notification \"\(escape(body))\" with title \"\(escape(title))\""])
    }
}

func notify(_ title: String, _ body: String) {
    Notify.post(title: "Chute", subtitle: title == "Chute" ? nil : title, body: body)
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    var lastSessions: [Session] = []
    var watcher: DispatchSourceFileSystemObject?
    var requestWatcher: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "Chute — drop context into your agent"
        // Placeholder menu, populated by menuWillOpen on click — no AppleScript on the launch path.
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        Notify.requestAuthorization()
        NSApp.servicesProvider = ServicesProvider()
        NSUpdateDynamicServices()
        registerHotKey()
        FirstRunWindow.showIfNeeded()
        startWatching()
        startWatchingRequests()
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

    /// FR-25 — what is running locally right now. Two `lsof` calls, made only when the menu opens.
    func appendLocalServers(to menu: NSMenu) {
        let servers = LocalServers.discover()
        let title = servers.isEmpty ? "No local servers running" : "Local servers (\(servers.count))"
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menu.addItem(parent)
        guard !servers.isEmpty else { return }

        let sub = NSMenu()
        for server in servers {
            let item = NSMenuItem(title: server.label, action: nil, keyEquivalent: "")
            item.toolTip = server.loopbackOnly
                ? "Reachable from this Mac only — pid \(server.pid)"
                : "Reachable from your whole network — pid \(server.pid)"
            let actions = NSMenu()
            for (label, selector) in [("Open in Browser", #selector(openServer(_:))),
                                      ("Copy \(server.url)", #selector(copyServerURL(_:))),
                                      ("Stop It (kill \(server.pid))", #selector(killServer(_:)))] {
                let action = NSMenuItem(title: label, action: selector, keyEquivalent: "")
                action.target = self
                action.representedObject = server.port
                actions.addItem(action)
            }
            sub.addItem(item)
            sub.setSubmenu(actions, for: item)
        }
        menu.setSubmenu(sub, for: parent)
    }

    @objc func openServer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }
        NSWorkspace.shared.open(URL(string: "http://localhost:\(port)")!)
    }

    @objc func copyServerURL(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }
        Clipboard.write("http://localhost:\(port)")
        notify("Local servers", "Copied http://localhost:\(port)")
    }

    @objc func killServer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let pids = LocalServers.kill(port: port)
            notify("Local servers", pids.isEmpty
                   ? "Nothing was listening on \(port) any more."
                   : "Stopped \(pids.count) process(es) on port \(port).")
        }
    }

    func appendStandardItems(to menu: NSMenu) {
        appendLocalServers(to: menu)
        menu.addItem(.separator())
        // No file actions here on purpose. They act on a Finder selection, so they live in the
        // Finder right-click menu where the files are; in the menu bar they had nothing to act on.
        let reportItem = NSMenuItem(title: "Report a Problem…", action: #selector(reportProblem),
                                    keyEquivalent: "")
        reportItem.target = self
        menu.addItem(reportItem)

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

    /// Support, without an inbox: the diagnostics go to the clipboard and a prefilled issue opens
    /// in the browser. One public answer then serves everyone who searches for the same thing.
    @objc func reportProblem() {
        DispatchQueue.global(qos: .userInitiated).async {
            let report = chute(["doctor", "--report"]).out
            Clipboard.write(report)
            NSWorkspace.shared.open(SupportReport.issueURL(summary: report))
            notify("Report a Problem",
                   "Diagnostics copied. Paste them into the issue that just opened.")
        }
    }

    @objc func openAutomationSettings() {
        NSWorkspace.shared.open(URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
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

    /// The Finder extension is sandboxed and cannot run git, launch Terminal or drive AppleScript.
    /// It writes a request instead; this is the end that carries it out. See `ActionRequest`.
    func startWatchingRequests() {
        let dir = ActionInbox.directory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let fd = open(dir, O_EVTONLY)
        guard fd >= 0 else { return }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend], queue: .main)
        src.setEventHandler { [weak self] in self?.runPendingRequests() }
        src.setCancelHandler { close(fd) }
        src.resume()
        requestWatcher = src
        runPendingRequests()   // anything queued while the app was not running
    }

    func runPendingRequests() {
        for (request, path) in ActionInbox.drain() {
            // Delete FIRST: a request that crashes the run must not be retried on every write
            // event for the next minute.
            try? FileManager.default.removeItem(atPath: path)
            guard let action = ChuteActions.find(request.id) else { continue }
            DispatchQueue.global(qos: .userInitiated).async {
                let command = Self.commandLine(for: action, request: request)
                let r = chute(command)
                // The selection list is scratch, not a record: remove it once it has been read.
                if let i = command.firstIndex(of: "--files-from"), i + 1 < command.count {
                    try? FileManager.default.removeItem(atPath: command[i + 1])
                }
                notify(action.plainTitle,
                       ChuteActions.message(stderr: r.err, exitCode: r.code,
                                            fallback: action.doneMessage))
            }
        }
    }

    /// Selecting a few thousand files in Finder produces a command line past ARG_MAX, and the
    /// action fails with "argument list too long". Above a modest threshold the paths go into a
    /// file instead — `--files-from` reads one path per line, and a file has no such limit.
    static let inlineFileLimit = 200

    static func commandLine(for action: ChuteAction, request: ActionRequest) -> [String] {
        guard request.files.count > inlineFileLimit else {
            return ChuteActions.argv(action, dir: request.dir, files: request.files)
        }
        let listFile = NSTemporaryDirectory() + "chute-selection-\(UUID().uuidString).txt"
        guard (try? request.files.joined(separator: "\n")
                .write(toFile: listFile, atomically: true, encoding: .utf8)) != nil else {
            return ChuteActions.argv(action, dir: request.dir, files: request.files)
        }
        // Owner-only: it lists everything the user had selected, which is nobody else's business.
        try? FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o600)],
                                               ofItemAtPath: listFile)
        return ChuteActions.argv(action, dir: request.dir, files: []) + ["--files-from", listFile]
    }

    func updateBadgeFromHooks() {
        let n = HookState.attention(HookState.readAll(),
                                    live: HookState.liveTTYs(),
                                    now: Date()).count
        statusItem.button?.title = n == 0 ? "⤓" : "⤓ \(n)"
    }

    /// FE-02 — ⌥⌘N pops the session switcher at the pointer, wherever you are. It used to pop
    /// file actions, which needed a Finder selection the keyboard user did not have.
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
