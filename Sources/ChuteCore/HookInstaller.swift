import Foundation

public struct HookReport: Sendable {
    public let changed: [String]
    public let skipped: [String]
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

/// Append-only, backed up, idempotent, reversible. Anything less is unacceptable:
/// this edits the user's live global Claude Code configuration.
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
    public static func command(for state: SessionState) -> String {
        let name = HookState.stateName(state)
        return "# \(marker)\n"
            + "S=\"$HOME/.chute/sessions\"; mkdir -p \"$S\" 2>/dev/null; "
            + "T=$(ps -o tty= -p $PPID 2>/dev/null | tr -d ' '); "
            + "if [ -n \"$T\" ]; then "
            + "printf '{\"tty\":\"%s\",\"state\":\"%s\",\"cwd\":\"%s\",\"ts\":%s}' "
            + "\"$T\" \"\(name)\" \"$PWD\" \"$(date +%s)\" > \"$S/$T.json.tmp\" 2>/dev/null "
            + "&& mv \"$S/$T.json.tmp\" \"$S/$T.json\" 2>/dev/null; fi; "
            + "printf '{}\\n'; exit 0"
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
                    (($0["command"] as? String) ?? "").contains(marker)
                }
            }
        }
    }

    @discardableResult
    public static func install(settingsPath: String,
                               now: Date = Date()) throws -> HookReport {
        let original = try loadObject(settingsPath)
        let originalKeys = Set(original.keys)
        let backup = try makeBackup(settingsPath, now: now)

        var root = original
        var hooks = (root["hooks"] as? [String: Any]) ?? [:]
        var changed: [String] = [], skipped: [String] = []

        for (event, state) in events.sorted(by: { $0.key < $1.key }) {
            var blocks = (hooks[event] as? [[String: Any]]) ?? []
            let already = blocks.contains { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    (($0["command"] as? String) ?? "").contains(marker)
                }
            }
            if already { skipped.append(event); continue }
            blocks.append(["hooks": [["type": "command", "command": command(for: state)]]])
            hooks[event] = blocks
            changed.append(event)
        }
        root["hooks"] = hooks

        try validateAndWrite(root, original: original, originalKeys: originalKeys,
                             path: settingsPath)
        return HookReport(changed: changed, skipped: skipped, backupPath: backup)
    }

    @discardableResult
    public static func uninstall(settingsPath: String,
                                 now: Date = Date()) throws -> HookReport {
        let original = try loadObject(settingsPath)
        let originalKeys = Set(original.keys)
        let backup = try makeBackup(settingsPath, now: now)

        var root = original
        var hooks = (root["hooks"] as? [String: Any]) ?? [:]
        var changed: [String] = []

        for event in events.keys.sorted() {
            guard var blocks = hooks[event] as? [[String: Any]] else { continue }
            let before = blocks.count
            blocks.removeAll { block in
                ((block["hooks"] as? [[String: Any]]) ?? []).contains {
                    (($0["command"] as? String) ?? "").contains(marker)
                }
            }
            if blocks.count != before { changed.append(event); hooks[event] = blocks }
        }
        root["hooks"] = hooks

        try validateAndWrite(root, original: original, originalKeys: originalKeys,
                             path: settingsPath, allowShrink: true)
        return HookReport(changed: changed, skipped: [], backupPath: backup)
    }

    static func makeBackup(_ path: String, now: Date) throws -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss"
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
    /// every top-level key and (unless uninstalling) every pre-existing hook entry.
    static func validateAndWrite(_ root: [String: Any],
                                 original: [String: Any],
                                 originalKeys: Set<String>,
                                 path: String,
                                 allowShrink: Bool = false) throws {
        guard JSONSerialization.isValidJSONObject(root) else {
            throw HookInstallError.validationFailed("result is not a serialisable object")
        }
        let data = try JSONSerialization.data(withJSONObject: root,
                                              options: [.prettyPrinted, .sortedKeys])
        guard let reparsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw HookInstallError.validationFailed("result does not re-parse")
        }
        let lost = originalKeys.subtracting(reparsed.keys)
        guard lost.isEmpty else {
            throw HookInstallError.validationFailed("would drop top-level keys: \(lost.sorted())")
        }
        if !allowShrink {
            let before = (original["hooks"] as? [String: Any]) ?? [:]
            let after = (reparsed["hooks"] as? [String: Any]) ?? [:]
            for (event, value) in before {
                let b = (value as? [Any])?.count ?? 0
                let a = (after[event] as? [Any])?.count ?? 0
                guard a >= b else {
                    throw HookInstallError.validationFailed("would shrink hooks.\(event) from \(b) to \(a)")
                }
            }
        }
        let temp = path + ".chute-tmp"
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: path),
                                                  withItemAt: URL(fileURLWithPath: temp))
    }
}
