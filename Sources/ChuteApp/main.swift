import AppKit
import Carbon.HIToolbox
import ChuteCore
import UserNotifications

/// Every action is the CLI. The app is a surface, never a second implementation.
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
    /// Model, effort and cost, read from the agent's own transcript. Never read on the main
    /// thread and never read while a menu is drawing — see TranscriptStore.
    let transcripts = TranscriptStore()
    /// The open menu's rows, so their CPU and memory figures stay live while it is on screen.
    var liveVitals: SessionMenu.LiveVitals?
    var vitalsTimer: Timer?
    var vitalsSampling = false
    var watcher: DispatchSourceFileSystemObject?
    var requestWatcher: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.toolTip = "Chute — drop context into your agent"
        // Placeholder menu, populated by menuWillOpen on click — no AppleScript on the launch path.
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        // NOT requesting notification permission here any more. Since the HUD became the only
        // surface, `Notify.post` runs only in the no-screen fallback — so a launch-time macOS
        // permission dialog asks a first-run user to approve a channel the app will almost never
        // use. `Notify.post`'s `.notDetermined` branch already asks at the moment one is actually
        // needed, which is the honest time to ask.
        registerHotKey()
        FirstRunWindow.showIfNeeded()
        // Teaching, not repair. FirstRunWindow shows only what is FAILING and stays silent when
        // everything passes — which means a stranger whose install went perfectly sees nothing at
        // all, in an app with no Dock icon. This runs once, on genuine first launch, and never
        // reappears uninvited; `chute onboard` is the way back.
        Onboard.showIfFirstRun()
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

    /// THE PAID BODY OF THE MENU BAR, behind the same gate as the Finder actions.
    ///
    /// It was not gated. `/buy` sells four things — the Finder menu, the session switcher, the
    /// local-server list and the ⌥⌘N hotkey — and three of them kept working forever after the
    /// trial ended. That is not generosity, it is the page describing a product the build does
    /// not deliver, which is the same defect as a privacy page claiming analytics that are not
    /// there.
    ///
    /// What a lapsed trial still gets, deliberately: Settings, Report a Problem, Refresh, Quit —
    /// nobody is trapped — and a plain statement that `chute sessions`, `chute focus` and
    /// `chute ports` still do all of this for free from the terminal. The convenience is what is
    /// bought; the capability was never taken away. That line is the open-core promise being
    /// kept at the exact moment it would be easiest to break.
    func populateBody(_ menu: NSMenu, trial: TrialState) {
        // CLEARED HERE, AND ONLY HERE. menuWillOpen populates the menu AppKit hands us IN PLACE,
        // so whatever was on it from last time is still there. SessionMenu.populate used to do
        // this — which meant the expired-trial branch below, which returns before ever reaching
        // it, appended a second complete copy of the menu on every open. It grew without bound,
        // in front of the one person who was deciding whether to pay.
        menu.removeAllItems()
        guard trial.isUnlocked else {
            // No count: the count is part of what is bought.
            SessionMenu.applyBadge(to: statusItem.button, count: 0)
            lastSessions = []

            let headline = NSMenuItem(title: "Trial ended — Buy Chute, $19 once",
                                      action: #selector(openLicenseSettings), keyEquivalent: "")
            headline.target = self
            menu.addItem(headline)

            let cli = NSMenuItem(title: "The chute CLI is still free — chute sessions, focus, ports",
                                 action: nil, keyEquivalent: "")
            cli.isEnabled = false
            cli.toolTip = "The command line tool is MIT and never expires. The app buys you the "
                        + "Finder menu and this switcher, not the ability to do these things."
            menu.addItem(cli)
            menu.addItem(.separator())
            return
        }
        let (sessions, problem) = discoverSessionsForMenu()
        SessionMenu.applyBadge(to: statusItem.button, count: SessionMenu.attentionCount(sessions))
        lastSessions = sessions
        liveVitals = SessionMenu.populate(menu, sessions: sessions, problem: problem,
                                          transcripts: transcripts,
                                          target: self, action: #selector(focusSession(_:)),
                                          openSettings: #selector(openAutomationSettings),
                                          alternate: #selector(runSessionCommand(_:)))
        // Refresh what the rows just rendered from cache, so the NEXT open is current. The read
        // is 37 ms per transcript and must never happen while a menu is being drawn.
        let ids = sessions.compactMap(\.sessionID)
        if !ids.isEmpty {
            DispatchQueue.global(qos: .utility).async { [transcripts] in
                transcripts.refresh(sessionIDs: ids)
            }
        }
    }

    func appendStandardItems(to menu: NSMenu, trial: TrialState) {
        if trial.isUnlocked {
            appendLocalServers(to: menu)
            BufferMenu.append(to: menu, target: self)
        }
        menu.addItem(.separator())
        // No file actions here on purpose. They act on a Finder selection, so they live in the
        // Finder right-click menu where the files are; in the menu bar they had nothing to act on.
        // Only ever set when a fallback notification was actually refused — which means the HUD
        // could not draw, so this really is the last channel left. The old tooltip claimed Chute
        // could not report anything without notifications; the HUD reports every action
        // regardless, so saying so would have been false.
        if Notify.deniedAtLastCheck {
            let fix = NSMenuItem(title: "Turn On Chute Notifications…",
                                 action: #selector(openNotificationSettings), keyEquivalent: "")
            fix.target = self
            fix.toolTip = "Chute normally confirms an action on screen. When it cannot — no "
                        + "display attached — a notification is the only way left to tell you."
            menu.addItem(fix)
        }

        let reportItem = NSMenuItem(title: "Report a Problem…", action: #selector(reportProblem),
                                    keyEquivalent: "")
        reportItem.target = self
        menu.addItem(reportItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings),
                                      keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Trial state, and nothing at all once it is paid for: an app that keeps mentioning
        // payment after the payment is nagging its own customer.
        if let label = Trial.menuLabel(trial) {
            let item = NSMenuItem(title: label, action: #selector(openLicenseSettings),
                                  keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())
        // NO "REFRESH NOW". It called refresh(), which built a NEW NSMenu and assigned it to
        // statusItem.menu — and menuWillOpen then fired on that fresh object and rebuilt the whole
        // thing again from scratch, so the work was discarded every time. It could not have done
        // anything: this menu is already rebuilt on every open, and the badge is driven by a
        // DispatchSource on the hook directory. A command that cannot change what you see is worse
        // than a missing one, because it teaches the reader that the menu might be stale.
        //
        // No key equivalents on what remains, either: in a status menu they only work while the
        // menu is open, so ⌘Q here would promise a global shortcut that does not exist.
        menu.addItem(NSMenuItem(title: "Quit Chute",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
    }

    /// Only for the ⌥⌘N HUD popup, which has no live NSMenu already being tracked by AppKit
    /// to populate in place. Every other path goes through menuWillOpen.
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        let trial = Trial.touch()
        populateBody(menu, trial: trial)
        appendStandardItems(to: menu, trial: trial)
        return menu
    }

    // MARK: - Clipboard buffer
    //
    // Every one of these is user-initiated. Nothing on this path runs unless a menu item is
    // clicked — Chute does not observe the pasteboard, and this is the whole of its involvement
    // with it.

    @objc func bufferCopyOne(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String,
              let entry = ContextBuffer().entries().first(where: { $0.name == name }) else { return }
        deliver(entry.text, "Copied")
    }

    @objc func bufferFlush() {
        let buf = ContextBuffer()
        guard let joined = buf.flushText() else { return }
        let n = buf.entries().count
        buf.clear()
        deliver(joined, n == 1 ? "Copied" : "\(n) copied as one")
    }

    @objc func bufferClear() {
        // No confirmation. Recent Copies refills itself every time you use the product, so there
        // is nothing here anyone assembled by hand — a sheet would cost more attention than the
        // contents are worth. Contrast Move Junk to Trash, which confirms because it touches
        // files the user made.
        ContextBuffer().clear()
        say("Recent copies cleared")
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

    @objc func openSettings() { SettingsWindow.show() }
    @objc func openLicenseSettings() { SettingsWindow.show(selecting: 1) }

    @objc func openNotificationSettings() {
        NSWorkspace.shared.open(Notify.settingsURL)
    }

    @objc func openAutomationSettings() {
        NSWorkspace.shared.open(URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }

    /// The ⌥ face of a session row. Four commands, all of which put text on the clipboard and
    /// none of which start anything — see `tmuxCommand` for why that matters.
    @objc func runSessionCommand(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? SessionCommand.Payload,
              let s = lastSessions.first(where: { $0.key == payload.key }),
              let sessionID = s.sessionID else { return }

        switch payload.kind {
        case .copyID:
            deliver(sessionID, "Session ID copied")
        case .copyResume:
            guard let cmd = ResumeCommand.resume(agent: s.agent, sessionID: sessionID) else { return }
            deliver(cmd, "Resume command copied")
        case .tmux:
            guard let cmd = ResumeCommand.tmux(project: s.project, cwd: s.cwd,
                                               agent: s.agent, sessionID: sessionID) else { return }
            deliver(cmd, "tmux command copied — the conversation resumes; the old window keeps running")
        case .copyCost:
            guard let t = transcripts.cached(sessionID),
                  let label = AgentTranscript.costLabel(output: t.outputTokens,
                                                        cacheRead: t.cacheReadTokens) else { return }
            deliver(label, "Cost copied")
        }
    }

    /// Put something on the clipboard and say so. NEVER writes an empty string: `deliver("", …)`
    /// would silently destroy whatever the user had copied, which is the opposite of this app's
    /// job. Use `say` for a message with nothing to hand over.
    func deliver(_ text: String, _ message: String) {
        guard !text.isEmpty else { say(message); return }
        Clipboard.write(text)
        // Remembered under the same words the confirmation used, so the row in Recent Copies and
        // the HUD that announced it say the same thing.
        ContextBuffer().record(text, label: message)
        say(message)
    }

    func say(_ message: String) {
        if !ResultHUD.show(message) { notify("Chute", message) }
    }

    @objc func focusSession(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String,
              let s = lastSessions.first(where: { $0.key == key }) else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            try? TerminalAppAdapter().focus(s)
        }
    }

    // AppleScript runs ONLY when the menu opens (menuWillOpen) — the user has just clicked,
    // so the cost is hidden by the click. Never called from the launch path.
    //
    // Populates the `menu` AppKit handed us IN PLACE. Do not build a new NSMenu and assign it to
    // statusItem.menu here: the object already being tracked for display is this one, so a swap
    // takes effect on the NEXT open, and the user sees the previous (stale) session list.
    func menuWillOpen(_ menu: NSMenu) {
        let trial = Trial.touch()
        populateBody(menu, trial: trial)
        appendStandardItems(to: menu, trial: trial)
        // Nothing to re-sample when the rows are not there.
        if trial.isUnlocked { startVitalsRefresh() }
    }

    /// While the menu is open, every row's CPU and memory figure is re-sampled every two seconds
    /// from ONE `ps` snapshot, so all of them describe the same instant — a row claiming 171%
    /// beside a row sampled a second earlier is what "live" must not mean.
    ///
    /// The timer runs in .common modes because menu tracking blocks the default run loop mode,
    /// and the sampling happens off the main thread so an open menu never stutters. It exists only
    /// while the menu is on screen: nothing is polled when nobody is looking.
    func startVitalsRefresh() {
        vitalsTimer?.invalidate()
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self, !self.vitalsSampling else { return }
            self.vitalsSampling = true
            DispatchQueue.global(qos: .userInteractive).async {
                let samples = SystemVitals.sample()
                DispatchQueue.main.async {
                    self.liveVitals?.apply(samples: samples)
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
        SessionMenu.applyBadge(to: statusItem.button, count: n)
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
