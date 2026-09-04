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
        // THE WIZARD OR THE REPAIR WINDOW, NEVER BOTH. Both are titled "Chute" and both call
        // NSApp.activate — run unconditionally, one launch could stack two windows with the
        // teaching one buried underneath. First launch gets the wizard, which already shows a
        // failing check's own row (see Onboard.render); every launch after gets the repair window,
        // which stays silent unless something that actually blocks the product is failing.
        // `chute onboard` and the menu's `Setup…` row are the ways back to either, on demand.
        if Onboard.hasOnboarded {
            FirstRunWindow.showIfNeeded()
        } else {
            Onboard.showIfFirstRun()
        }
        startWatchingRequests()
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
        // so whatever was on it from last time is still there. SessionMenu used to do this —
        // which meant the expired-trial branch, which returned before ever reaching it, appended
        // a second complete copy of the menu on every open. It grew without bound, in front of
        // the one person who was deciding whether to pay. `StatusMenuSuite` now asserts that
        // building the menu twice produces the same menu rather than two of it.
        menu.removeAllItems()

        let (sessions, problem) = trial.isUnlocked ? discoverSessionsForMenu() : ([], nil)
        SessionMenu.applyBadge(to: statusItem.button)
        lastSessions = sessions

        // ONE `SystemVitals.sample()` FOR THE WHOLE MENU. Sampling per row would be thirteen
        // process listings for a menu the user is already waiting on.
        let samples = trial.isUnlocked ? SystemVitals.sample() : []

        // Read once, used twice: the entries for the rows, and — only when there are any — the
        // files' own content for the token count on "Copy Basket as Context". StatusMenu.model
        // stays free of disk reads; this is the one place that does them, same as `samples` above.
        let basketBuf = ContextBuffer()
        let basketEntries = trial.isUnlocked ? basketBuf.entries().reversed().map { $0 } : []
        let basketTokens = basketEntries.isEmpty ? 0
            : TokenEstimate.tokens(in: basketBuf.bundleText() ?? "")

        let model = StatusMenu.model(
            sessions: sessions,
            trial: trial,
            problem: problem,
            recent: basketEntries,
            recentTokens: basketTokens,
            notificationsDenied: Notify.deniedAtLastCheck,
            loadFor: { SystemVitals.load(forTTY: $0, in: samples) },
            sessionCommands: { [transcripts] s in
                SessionCommand.available(for: s, transcript: transcripts.cached(s.sessionID))
            },
            detailFor: { [transcripts] s in
                SessionPhrasing.detail(agent: s.agent, transcript: transcripts.cached(s.sessionID))
            })

        let live = SessionMenu.LiveVitals()
        SessionMenu.render(model, into: menu, target: self,
                           selector: { Self.selector(for: $0) },
                           servers: { [weak self] in self?.appendLocalServers(to: $0) },
                           live: live)
        liveVitals = live

        // Refresh what the rows just rendered from cache, so the NEXT open is current. The read
        // is 37 ms per transcript and must never happen while a menu is being drawn.
        let ids = sessions.compactMap(\.sessionID)
        if !ids.isEmpty {
            DispatchQueue.global(qos: .utility).async { [transcripts] in
                transcripts.refresh(sessionIDs: ids)
            }
        }
    }

    /// The one place a model Command becomes an AppKit selector. Kept exhaustive on purpose: a
    /// new command added to the model will not compile until it has somewhere to go.
    static func selector(for command: StatusMenu.Command) -> Selector? {
        switch command {
        case .focusSession:              return #selector(focusSession(_:))
        case .sessionCommand:            return #selector(runSessionCommand(_:))
        case .openLicenseSettings:       return #selector(openLicenseSettings)
        case .openAutomationSettings:    return #selector(openAutomationSettings)
        case .openNotificationSettings:  return #selector(openNotificationSettings)
        case .reportProblem:             return #selector(reportProblem)
        case .openSettings:              return #selector(openSettings)
        case .openSetup:                 return #selector(openSetup)
        case .quit:                      return #selector(NSApplication.terminate(_:))
        case .bufferReveal:              return #selector(bufferReveal(_:))
        case .bufferMentions:            return #selector(bufferMentions)
        case .bufferFlush:               return #selector(bufferFlush)
        case .bufferClear:               return #selector(bufferClear)
        }
    }

    /// Only for the ⌥⌘N HUD popup. `popUp` sends `menuWillOpen` like any other open, which is
    /// where the body is built — populating here as well ran the Terminal scan and both `lsof`
    /// calls twice per keypress.
    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        return menu
    }

    // MARK: - Context basket
    //
    // Every one of these is user-initiated. Nothing on this path runs unless a menu item is
    // clicked — Chute does not observe the pasteboard, and this is the whole of its involvement
    // with it. Nothing here files a NEW entry, either: only `chute basket add` and the Finder's
    // "Add to Basket" row do that. This section only ever reads and copies.

    /// Reveal, not "put back on the clipboard" — an entry is a file path now, not a copy of its
    /// content, so there is nothing to put back. Says something on both failure paths rather than
    /// the silent no-op this used to be when a row's entry had been evicted between the menu
    /// drawing and the click.
    @objc func bufferReveal(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String,
              ContextBuffer().entries().contains(where: { $0.path == path }) else {
            say("That file is no longer in the basket")
            return
        }
        guard FileManager.default.fileExists(atPath: path) else {
            say("That file no longer exists on disk")
            return
        }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }

    /// The ICP's format, first in the menu: Claude Code / Cursor already have filesystem access,
    /// so they need paths pointed at, not content pasted. Does not empty the basket — copying it
    /// is not the same decision as being done with it; "Empty Basket" is its own explicit row.
    @objc func bufferMentions() {
        let buf = ContextBuffer()
        guard let text = buf.mentionText() else { say("Basket is empty"); return }
        Clipboard.write(text)
        say("\(buf.entries().count) copied as @mentions")
    }

    /// The chat-UI format — the bundle `chute unpack` still serves, byte-identical to
    @objc func bufferFlush() {
        let buf = ContextBuffer()
        guard let text = buf.bundleText() else { say("Basket is empty"); return }
        let n = buf.entries().count
        Clipboard.write(text)
        say("\(n) copied as context (\(TokenEstimate.badge(TokenEstimate.tokens(in: text))))")
    }

    @objc func bufferClear() {
        // No confirmation. The basket refills itself the moment you add to it again, so there is
        // nothing here a sheet would protect that "Empty Basket" itself does not already say
        // plainly. Contrast Move Junk to Trash, which confirms because it touches files the user
        // made — this only ever touches Chute's own bookkeeping of paths.
        ContextBuffer().clear()
        say("Basket emptied")
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

        // Every label names its SESSION. Four agents running means four "Resume command" rows,
        // and without the project on each one the list cannot tell you which is which.
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
    ///
    /// NO LONGER FILES INTO THE BASKET. It used to — every session command (a session ID, a
    /// resume command, a tmux command) auto-recorded here, which is the same "everything files
    /// itself" defect `Out.deliver` had on the CLI side. None of these are file paths, and a
    /// basket entry is one now (see `ContextBuffer.swift`), so there is nothing left for this to
    /// hand over to it. The former `label` parameter existed only to name that recording; it is
    /// gone with it.
    func deliver(_ text: String, _ message: String) {
        guard !text.isEmpty else { say(message); return }
        Clipboard.write(text)
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

    /// FE-02 — ⌥⌘N pops the session switcher at the pointer, wherever you are. It used to pop
    /// file actions, which needed a Finder selection the keyboard user did not have.
    func registerHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x43485554), id: 1)   // 'CHUT'
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            DispatchQueue.main.async { (NSApp.delegate as? AppDelegate)?.showHUD() }
            return noErr
        }, 1, &eventType, nil, nil)
        let status = RegisterEventHotKey(UInt32(kVK_ANSI_N), UInt32(optionKey | cmdKey),
                                         hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        // ⌥⌘N is one of the four things /buy sells. Another app owning it left the key dead
        // with nothing anywhere saying so.
        HotKeyStatus.problem(status).map { NSLog("Chute: %@", $0) }
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
