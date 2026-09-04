import Foundation

/// Per-tty state written by Claude Code hooks. One small JSON file per terminal tab.
/// Reads never throw: a corrupt file must degrade one row, never break the menu.
public enum HookState {
    public static func directory(root: String? = nil) -> String {
        root ?? Home.chute("sessions")
    }

    public static func parse(_ data: Data) -> HookRecord? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawTTY = obj["tty"] as? String,
              let rawState = obj["state"] as? String,
              let ts = obj["ts"] as? Double
        else { return nil }

        let states: [String: SessionState] = [
            "blocked": .blocked, "waiting": .waiting,
            "working": .working, "idle": .idle,
        ]
        guard let state = states[rawState] else { return nil }

        return HookRecord(tty: Session.normalise(tty: rawTTY),
                          state: state,
                          cwd: obj["cwd"] as? String,
                          // Empty is ABSENT. The snippet writes "" whenever
                          // CLAUDE_CODE_SESSION_ID is unset — a different agent, or a Claude Code
                          // old enough not to export it. Treating "" as a value would build a
                          // resume command for a session that does not exist.
                          sessionID: (obj["session_id"] as? String).flatMap { $0.isEmpty ? nil : $0 },
                          timestamp: Date(timeIntervalSince1970: ts))
    }

    /// Atomic: written to a temp name then moved, so a reader never sees half a file.
    public static func write(_ record: HookRecord, root: String? = nil) throws {
        let dir = directory(root: root)
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        // Normalise here, not in the caller. A raw "/dev/ttys004" would otherwise become part of
        // the FILENAME and the on-disk key would never match readAll's normalised keys — the join
        // would fail silently and the menu would simply never update.
        let tty = Session.normalise(tty: record.tty)
        var obj: [String: Any] = [
            "tty": tty,
            "state": stateName(record.state),
            "ts": record.timestamp.timeIntervalSince1970,
        ]
        if let cwd = record.cwd { obj["cwd"] = cwd }
        if let sid = record.sessionID { obj["session_id"] = sid }

        let data = try JSONSerialization.data(withJSONObject: obj)
        let final = (dir as NSString).appendingPathComponent("\(tty).json")
        let temp = final + ".tmp"
        defer { try? FileManager.default.removeItem(atPath: temp) }
        try data.write(to: URL(fileURLWithPath: temp))
        _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: final),
                                                  withItemAt: URL(fileURLWithPath: temp))
    }

    public static func readAll(root: String? = nil) -> [String: HookRecord] {
        let dir = directory(root: root)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [:] }
        var out: [String: HookRecord] = [:]
        for name in names where name.hasSuffix(".json") {
            let path = (dir as NSString).appendingPathComponent(name)
            guard let data = FileManager.default.contents(atPath: path),
                  let record = parse(data) else { continue }
            out[record.tty] = record
        }
        return out
    }

    /// tty names that still have a process attached. A hook file outlives the window that wrote
    /// it (up to `staleAfter`), so liveness — not the file existing — is what makes a badge count
    /// trustworthy. `ps -o tty=` prints "??" when there is no controlling terminal, never an

    public static func stateName(_ s: SessionState) -> String {
        switch s {
        case .blocked: return "blocked"
        case .waiting: return "waiting"
        case .working: return "working"
        case .idle:    return "idle"
        case .unknown: return "idle"
        }
    }
}
