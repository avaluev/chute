import Foundation

public struct HookReport: Sendable {
    public let changed: [String]
    public let backupPath: String?
}

public enum HookInstallError: Error, CustomStringConvertible {
    case unreadable(String)
    case unparseable(String)
    case backupFailed(String)
    case validationFailed(String)

    public var description: String {
        switch self {
        case .unreadable(let p):       return "cannot read \(p)"
        case .unparseable(let p):      return "\(p) is not valid JSON — refusing to touch it"
        case .backupFailed(let m):     return "backup failed, nothing was changed: \(m)"
        case .validationFailed(let m): return "refusing to write: \(m)"
        }
    }
}

/// Chute NEVER writes to the user's Claude Code configuration. Decided 2026-08-27:
/// another tool's live settings file is not ours to edit, however carefully — a corrupted
/// agent setup costs the user more than any badge is worth. What remains here is read-only
/// (`status`), generative (`manualSnippet` — JSON the user pastes in themselves), and
/// subtractive (`uninstall` — removes exactly the blocks earlier Chute versions added,
/// backed up first, for machines that still carry them).
public enum HookInstaller {
    public static let marker = "chute-session-state"

    public static let events: [String: SessionState] = [
        "PermissionRequest": .blocked,
        "Stop":              .waiting,
        "UserPromptSubmit":  .working,
        "SessionStart":      .working,
    ]

    /// A single line. Writes one small file and always exits 0 — a Chute failure must never
    /// break the user's agent session. $PPID is the claude process, whose tty is the tab's tty.
    /// `ps -o tty=` prints `??` (not empty) when there is no controlling terminal, so we whitelist
    /// alphanumeric tty names rather than just checking for non-empty. The cwd is escaped for JSON
    /// before being embedded, so a directory name containing `"` or `\` cannot break the printf.
    public static func command(for state: SessionState) -> String {
        let name = HookState.stateName(state)
        return "# \(marker)\n"
            + "S=\"$HOME/.chute/sessions\"; mkdir -p \"$S\" 2>/dev/null; "
            + "T=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' '); "
            + "case \"$T\" in \"\"|*[!a-zA-Z0-9]*) printf '{}\\n'; exit 0;; esac; "
            + "CWD=$(printf '%s' \"$PWD\" | sed 's/\\\\/\\\\\\\\/g; s/\"/\\\\\"/g'); "
            + "printf '{\"tty\":\"%s\",\"state\":\"%s\",\"cwd\":\"%s\",\"ts\":%s}' "
            + "\"$T\" \"\(name)\" \"$CWD\" \"$(date +%s)\" > \"$S/$T.json.tmp\" 2>/dev/null "
            + "&& mv \"$S/$T.json.tmp\" \"$S/$T.json\" 2>/dev/null; "
            + "printf '{}\\n'; exit 0"
    }

    /// Our command always OPENS with the marker comment line. Matching the prefix (including its
    /// trailing newline, exactly what `command(for:)` emits) rather than a loose `contains` means
    /// a user command that merely mentions the marker — or one that shares our prefix but diverges,
    /// like `# chute-session-state-mine` — is never mistaken for ours, in either direction.
    public static func isChuteCommand(_ command: String) -> Bool {
        command.hasPrefix("# \(marker)\n")
    }

    static func loadObject(_ path: String) throws -> [String: Any] {
        guard let data = FileManager.default.contents(atPath: path) else {
            throw HookInstallError.unreadable(path)
        }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.unparseable(path)
        }
        return obj
    }

    public static func status(settingsPath: String) -> [String: Bool] {
        guard let obj = try? loadObject(settingsPath),
              let hooks = obj["hooks"] as? [String: Any] else {
            return events.keys.reduce(into: [:]) { $0[$1] = false }
        }
        return events.keys.reduce(into: [:]) { out, event in
            let blocks = (hooks[event] as? [[String: Any]]) ?? []
            out[event] = blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    isChuteCommand(($0["command"] as? String) ?? "")
                }
            }
        }
    }

    /// The `hooks` object a user can paste into their own settings.json, verbatim. Chute
    /// generates the JSON but the user's hand does the writing — that is the whole contract.
    public static func manualSnippet() -> String {
        var hooks: [String: Any] = [:]
        for (event, state) in events {
            hooks[event] = [["hooks": [["type": "command", "command": command(for: state)]]]]
        }
        let data = (try? JSONSerialization.data(withJSONObject: ["hooks": hooks],
                                                options: [.prettyPrinted, .sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    @discardableResult
    public static func uninstall(settingsPath: String,
                                 now: Date = Date()) throws -> HookReport {
        let path = URL(fileURLWithPath: settingsPath).resolvingSymlinksInPath().path
        let original = try loadObject(path)
        let originalKeys = Set(original.keys)

        var root = original
        var hooks: [String: Any] = [:]
        if let existing = root["hooks"] {
            guard let obj = existing as? [String: Any] else {
                throw HookInstallError.validationFailed(
                    "`hooks` is not an object — refusing to modify this file")
            }
            hooks = obj
        }
        var changed: [String] = []

        for event in events.keys.sorted() {
            guard let existing = hooks[event] else { continue }
            guard var blocks = existing as? [[String: Any]] else {
                throw HookInstallError.validationFailed(
                    "hooks.\(event) is not an array of objects — refusing to modify this file")
            }
            let before = blocks.count
            blocks.removeAll { block in
                // Only remove a block that is exactly the one we wrote. If someone merged our
                // hook into a block with theirs, leave it alone rather than taking their hook
                // with it.
                guard block["matcher"] == nil,
                      let inner = block["hooks"] as? [[String: Any]],
                      inner.count == 1 else { return false }
                return isChuteCommand((inner[0]["command"] as? String) ?? "")
            }
            if blocks.count != before {
                changed.append(event)
                // Removing our block can empty the event entirely. An empty array is a husk we
                // left behind, not config the user wrote — drop the key so uninstall reverses.
                if blocks.isEmpty { hooks.removeValue(forKey: event) } else { hooks[event] = blocks }
            }
        }
        root["hooks"] = hooks

        // Nothing of ours in the file → nothing to write, no backup to leave behind. This is what
        // lets uninstall.sh run it unconditionally on machines that never had hooks wired.
        guard !changed.isEmpty else { return HookReport(changed: [], backupPath: nil) }

        // Backup only after every shape guard above has passed — a refusal leaves no trace at all.
        let backup = try makeBackup(path, now: now)
        try validateAndWrite(root, originalKeys: originalKeys, path: path)
        return HookReport(changed: changed, backupPath: backup)
    }

    static func makeBackup(_ path: String, now: Date) throws -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        let dest = path + ".chute-backup-" + f.string(from: now)
        do {
            if FileManager.default.fileExists(atPath: dest) {
                try FileManager.default.removeItem(atPath: dest)
            }
            try FileManager.default.copyItem(atPath: path, toPath: dest)
        } catch {
            throw HookInstallError.backupFailed(error.localizedDescription)
        }
        return dest
    }

    /// Nothing is written until the new document is proven to re-parse and to have kept
    /// every top-level key.
    static func validateAndWrite(_ root: [String: Any],
                                 originalKeys: Set<String>,
                                 path: String) throws {
        guard JSONSerialization.isValidJSONObject(root) else {
            throw HookInstallError.validationFailed("result is not a serialisable object")
        }
        // .sortedKeys is deliberate. Swift dictionaries are unordered and hash seeds are
        // randomised per process, so WITHOUT this the same input serialises in a different order
        // every run — reshuffling the user's entire 33 KB file on every install. Sorted normalises
        // once, on first install, then stays byte-identical forever. Preserving the user's original
        // order is not achievable here without text splicing, which guarantee 2 forbids.
        let data = try JSONSerialization.data(withJSONObject: root,
                                              options: [.prettyPrinted, .sortedKeys])
        guard let reparsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.validationFailed("result does not re-parse")
        }
        let lost = originalKeys.subtracting(reparsed.keys)
        guard lost.isEmpty else {
            throw HookInstallError.validationFailed("would drop top-level keys: \(lost.sorted())")
        }
        let temp = path + ".chute-tmp"
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: path),
                                                  withItemAt: URL(fileURLWithPath: temp))
    }
}
