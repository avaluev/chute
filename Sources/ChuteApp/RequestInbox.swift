import AppKit
import ChuteCore

/// The unsandboxed half of the Finder extension: it writes a request, this carries it out.
/// See `ActionRequest` for why the extension cannot simply do the work itself.
extension AppDelegate {
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

            // ABOVE THE GATE, deliberately. The user performed the right-click; the teaching
            // succeeded. Whether the action is PERMITTED is a different question, and if the
            // trial has lapsed beat 3 must still complete — otherwise the one beat that proves
            // the product works becomes unreachable at exactly the moment someone is deciding
            // whether to pay for it.
            Onboard.observe(action.id)

            // THE GATE, and the only one. Every Finder action arrives here, so the trial is
            // checked once rather than in eight action handlers. The sandboxed extension is
            // deliberately not involved: it cannot read the licence file from inside its
            // container, and licence logic has no business inside a sandbox.
            //
            // The `chute` CLI is never gated — it is MIT and free forever, and install.sh
            // symlinks it out of this very bundle.
            guard Trial.touch().isUnlocked else {
                notify("Trial ended", "Chute's Finder actions need a licence. $19, one payment.")
                DispatchQueue.main.async { SettingsWindow.show(selecting: 1) }
                continue
            }

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
