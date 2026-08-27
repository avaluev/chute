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


final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    var lastSessions: [Session] = []
    var watcher: DispatchSourceFileSystemObject?
    var requestWatcher: DispatchSourceFileSystemObject?
    var liveVitals: SessionMenu.LiveVitals?
    var vitalsTimer: Timer?
    var vitalsSampling = false

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "Chute — drop context into your agent"
        // Placeholder menu, populated by menuWillOpen on click — no AppleScript on the launch path.
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        Notify.requestAuthorization()
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

    func appendStandardItems(to menu: NSMenu) {
        appendLocalServers(to: menu)
        menu.addItem(.separator())
        // No file actions here on purpose. They act on a Finder selection, so they live in the
        // Finder right-click menu where the files are; in the menu bar they had nothing to act on.
        // If macOS is refusing our banners, say so where it will be read, with the fix one click
        // away. Silently posting through osascript instead is what made every banner arrive as
        // Script Editor.
        if Notify.deniedAtLastCheck {
            let fix = NSMenuItem(title: "Turn On Chute Notifications…",
                                 action: #selector(openNotificationSettings), keyEquivalent: "")
            fix.target = self
            fix.toolTip = "Chute cannot tell you when an action finishes until notifications are on."
            menu.addItem(fix)
        }

        let reportItem = NSMenuItem(title: "Report a Problem…", action: #selector(reportProblem),
                                    keyEquivalent: "")
        reportItem.target = self
        menu.addItem(reportItem)

        menu.addItem(.separator())
        // No key equivalents: in a status menu they only work while the menu is open, so showing
        // ⌘R and ⌘Q promises a global shortcut that does not exist.
        menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refresh), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Chute",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
    }

    /// Only for contexts where menuWillOpen does not apply — refresh() and the ⌥⌘N HUD popup —
    /// because there is no live NSMenu already being tracked by AppKit to populate in place.
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        let (sessions, problem) = discoverSessionsForMenu()
        statusItem.button?.title = SessionMenu.badge(for: sessions)
        lastSessions = sessions
        liveVitals = SessionMenu.populate(menu, sessions: sessions, problem: problem,
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

    @objc func openNotificationSettings() {
        NSWorkspace.shared.open(Notify.settingsURL)
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
        liveVitals = SessionMenu.populate(menu, sessions: sessions, problem: problem,
                                          target: self, action: #selector(focusSession(_:)),
                                          openSettings: #selector(openAutomationSettings))
        appendStandardItems(to: menu)
        startVitalsRefresh()
    }

    /// While the menu is open, every number on it is re-sampled every two seconds — rows and
    /// the This-Mac line from ONE snapshot, so they always describe the same instant. The timer
    /// runs in .common modes because menu tracking blocks the default run loop mode; sampling
    /// happens off the main thread so the open menu never stutters.
    func startVitalsRefresh() {
        vitalsTimer?.invalidate()
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self, !self.vitalsSampling else { return }
            self.vitalsSampling = true
            DispatchQueue.global(qos: .userInteractive).async {
                let samples = SystemVitals.sample()
                let battery = SystemVitals.temperature()
                DispatchQueue.main.async {
                    self.liveVitals?.apply(samples: samples, batteryCelsius: battery)
                    self.vitalsSampling = false
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        vitalsTimer = timer
    }

    func menuDidClose(_ menu: NSMenu) {
        vitalsTimer?.invalidate()
        vitalsTimer = nil
        liveVitals = nil
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

// The app itself. This has to be the LAST thing in main.swift: everything above declares types,
// and top-level code in a main file runs in order.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)     // LSUIElement — menu bar only, no Dock icon
app.run()
