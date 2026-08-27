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
}
