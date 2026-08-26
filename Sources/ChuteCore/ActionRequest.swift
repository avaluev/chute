import Foundation

/// A job the Finder extension cannot do itself, handed to the app that can.
///
/// WHY THIS EXISTS — three things were measured inside the loaded, sandboxed extension:
///   · `git` is an `xcrun` shim and refuses outright: "xcrun: error: cannot be used within an App
///     Sandbox", so every git-backed action fails there;
///   · launching an app is denied: `_LSOpenURLsWithCompletionHandler() failed … error -54`;
///   · AppleScript to Terminal is denied: "A privilege violation occurred. (-10004)".
/// The extension can, however, write files anywhere the user can. So it writes a request and
/// `ChuteApp` — an ordinary unsandboxed app — carries it out. This is what Google Drive's
/// extension does too: it signals its host app rather than doing file work itself.
public struct ActionRequest: Sendable, Equatable {
    public let id: String          // ChuteAction.id
    public let dir: String         // the folder in view
    public let files: [String]     // the Finder selection
    public let createdAt: Date

    public init(id: String, dir: String, files: [String], createdAt: Date = Date()) {
        self.id = id; self.dir = dir; self.files = files; self.createdAt = createdAt
    }
}

public enum ActionInbox {
    public static func directory(root: String? = nil) -> String {
        root ?? "/Users/" + NSUserName() + "/.chute/requests"
        // NOT NSHomeDirectory(): inside the extension that is the sandbox container, and a request
        // written there is a request nobody ever reads.
    }

    /// A request older than this is ignored and deleted: it belongs to a click from a previous
    /// session, and carrying out a stale one would surprise the user.
    public static let staleAfter: TimeInterval = 60

    /// Atomic write — the watcher must never read half a file.
    @discardableResult
    public static func write(_ request: ActionRequest, root: String? = nil) throws -> String {
        let dir = directory(root: root)
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let obj: [String: Any] = [
            "id": request.id,
            "dir": request.dir,
            "files": request.files,
            "ts": request.createdAt.timeIntervalSince1970,
        ]
        let data = try JSONSerialization.data(withJSONObject: obj)
        let name = "\(Int(request.createdAt.timeIntervalSince1970 * 1000))-\(request.id)-\(UInt32.random(in: 0...999999)).json"
        let final = (dir as NSString).appendingPathComponent(name)
        let temp = final + ".tmp"
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: final),
                                                  withItemAt: URL(fileURLWithPath: temp))
        return final
    }

    public static func parse(_ data: Data) -> ActionRequest? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = obj["id"] as? String,
              let dir = obj["dir"] as? String,
              let ts = obj["ts"] as? Double,
              ChuteActions.find(id) != nil
        else { return nil }
        return ActionRequest(id: id, dir: dir,
                             files: obj["files"] as? [String] ?? [],
                             createdAt: Date(timeIntervalSince1970: ts))
    }

    /// Every pending request, oldest first, with its file path. Corrupt files are deleted rather
    /// than retried forever; a malformed request can never be carried out anyway.
    public static func drain(root: String? = nil, now: Date = Date()) -> [(request: ActionRequest, path: String)] {
        let dir = directory(root: root)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [] }
        var out: [(ActionRequest, String)] = []
        for name in names.sorted() where name.hasSuffix(".json") {
            let path = (dir as NSString).appendingPathComponent(name)
            guard let data = FileManager.default.contents(atPath: path),
                  let request = parse(data) else {
                try? FileManager.default.removeItem(atPath: path)
                continue
            }
            let age = now.timeIntervalSince(request.createdAt)
            // A negative age means a clock skew, not a fresh request: drop it rather than trust it.
            guard age >= 0, age < staleAfter else {
                try? FileManager.default.removeItem(atPath: path)
                continue
            }
            out.append((request, path))
        }
        return out
    }
}
