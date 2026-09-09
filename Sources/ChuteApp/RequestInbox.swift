import AppKit
import ChuteCore

/// The unsandboxed half of the Finder extension: it writes a request, this carries it out.
/// See `ActionRequest` for why the extension cannot simply do the work itself.
extension AppDelegate {
    /// The Finder extension is sandboxed and cannot run git, launch Terminal or drive AppleScript.
    /// It writes a request instead; this is the end that carries it out. See `ActionRequest`.
    /// Watch a directory and call back when anything in it changes.
    ///
    /// A kqueue, NOT A POLL. It costs nothing at all until the kernel says a file moved, which is
    /// what lets the menu-bar light be live without breaking NFR-02 ("no background CPU when
    /// idle"). The one `guard` here is the ONLY one: this used to be inline in
    /// `startWatchingRequests`, and the hook watcher needed the identical eight lines. Copying
    /// them would have cost a second `guard` in a target where `Scripts/check-untested-logic.sh`
    /// counts every branch against a baseline — so the guard MOVED here rather than multiplying.
    func watch(_ dir: String, _ onChange: @escaping () -> Void) -> DispatchSourceFileSystemObject? {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let fd = open(dir, O_EVTONLY)
        guard fd >= 0 else { return nil }
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend], queue: .main)
        src.setEventHandler(handler: onChange)
        src.setCancelHandler { close(fd) }
        src.resume()
        return src
    }

    func startWatchingRequests() {
        requestWatcher = watch(ActionInbox.directory()) { [weak self] in self?.runPendingRequests() }
        runPendingRequests()   // anything queued while the app was not running

        // THE TRAFFIC LIGHT. Hook files land in ~/.chute/sessions as the agent crosses a turn
        // boundary; this redraws the menu-bar mark the moment one does, with the menu shut and
        // nobody looking. Reads hooks and `ps` only — no AppleScript, so no Automation prompt
        // and nothing that needs a logged-in Finder.
        hookWatcher = watch(HookState.directory()) { [weak self] in self?.refreshSignal() }
        refreshSignal()
    }

    /// Worst live state across every session, straight onto the icon. No branch, and no NUMBER:
    /// a count is a cardinality that can be falsified by looking, which is exactly how the old
    /// badge died. `.unknown` and `.idle` draw the plain mark, so an un-instrumented machine
    /// stays silent instead of claiming everything is fine.
    ///
    /// READ OFF THE MAIN THREAD, DRAW ON IT. `HookState.liveTTYs()` forks `ps` and waits for it,
    /// and this fires on every hook file the agent writes — once per turn boundary, per session,
    /// with a dozen sessions running. On `.main` that is a subprocess round-trip on the thread
    /// AppKit draws with, which is the definition of a beachball. The read moves to a background
    /// queue; only `applyBadge` comes back, because it touches an `NSStatusItem` button and
    /// AppKit is main-thread-only.
    func refreshSignal() {
        // The button is read HERE, on the caller's thread, and captured by value. Capturing
        // `self` instead would need a `guard let self` on the way back, and that is a decision
        // point in a target no test can import — `Scripts/check-untested-logic.sh` counts those
        // against a baseline and fails, which is how this got written the other way round once.
        let button = statusItem.button
        DispatchQueue.global(qos: .utility).async {
            let signal = SignalReader.read(records: HookState.readAll(),
                                           live: HookState.liveTTYs(),
                                           now: Date())
            let token = StatusMenu.stateToken(signal.state)
            DispatchQueue.main.async { SessionMenu.applyBadge(token, to: button) }
        }
    }

    func runPendingRequests() {
        for (request, path) in ActionInbox.drain() {
            // Delete FIRST: a request that crashes the run must not be retried on every write
            // event for the next minute.
            try? FileManager.default.removeItem(atPath: path)
            guard let action = ChuteActions.find(request.id) else { continue }

            // There was a trial gate here: every Finder action checked Trial.touch().isUnlocked
            // and, past the 14 days, stopped and pointed at the (now also gone) License tab.
            // Chute went free and MIT on 2026-09-08 — nothing is left to unlock, so nothing is
            // left to check.
            Onboard.observe(action.id)

            DispatchQueue.global(qos: .userInitiated).async {
                let command = Self.commandLine(for: action, request: request)
                // The selection list is scratch, not a record. It is removed once NOTHING will
                // read it again — which for a confirmed action is after the second run, not the
                // first, or the write re-runs against a file that is no longer there.
                func discardSelectionList() {
                    if let i = command.firstIndex(of: "--files-from"), i + 1 < command.count {
                        try? FileManager.default.removeItem(atPath: command[i + 1])
                    }
                }
                func report(_ r: ShellResult) {
                    notify(action.plainTitle,
                           ChuteActions.message(stderr: r.err, exitCode: r.code,
                                                fallback: action.doneMessage))
                }

                let r = chute(command)

                // `unpack` and `clean` print what they WOULD do and change nothing until they are
                // given --force. So the first run above is the preview; the write only happens if
                // the user reads the list and says yes.
                guard let button = action.confirmButton, r.ok else {
                    discardSelectionList()
                    report(r)
                    return
                }
                DispatchQueue.main.async {
                    guard Self.confirm(action: action, button: button, preview: r.out) else {
                        discardSelectionList()
                        notify(action.plainTitle, "Nothing was changed.")
                        return
                    }
                    DispatchQueue.global(qos: .userInitiated).async {
                        let written = chute(command + ["--force"])
                        discardSelectionList()
                        report(written)
                    }
                }
            }
        }
    }

    /// The second, explicit action. Shows what the dry run listed and asks before anything on
    /// disk changes. Cancel is the default button: a stray Return key must not write files.
    @MainActor
    static func confirm(action: ChuteAction, button: String, preview: String) -> Bool {
        // WHAT it says is `ConfirmPrompt` in ChuteCore, where a headless test can read it. What is
        // left here is the window — which is the only part that needs a screen.
        let prompt = ConfirmPrompt(actionTitle: action.plainTitle, preview: preview)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = prompt.title
        alert.informativeText = prompt.body
        alert.addButton(withTitle: "Cancel")     // first = default = Return
        alert.addButton(withTitle: button)
        // A modal from an accessory app can open behind whatever is in front; without this the
        // user sees nothing happen and clicks the menu item again.
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal() == .alertSecondButtonReturn
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
}
