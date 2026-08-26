import Foundation

/// Per-tty state written by Claude Code hooks. One small JSON file per terminal tab.
/// Reads never throw: a corrupt file must degrade one row, never break the menu.
public enum HookState {
    public static func directory(root: String? = nil) -> String {
        root ?? (NSHomeDirectory() as NSString).appendingPathComponent(".chute/sessions")
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
                          sessionID: obj["session_id"] as? String,
                          timestamp: Date(timeIntervalSince1970: ts))
    }

    /// Atomic: written to a temp name then moved, so a reader never sees half a file.
    public static func write(_ record: HookRecord, root: String? = nil) throws {
        let dir = directory(root: root)
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        var obj: [String: Any] = [
            "tty": record.tty,
            "state": String(describing: stateName(record.state)),
            "ts": record.timestamp.timeIntervalSince1970,
        ]
        if let cwd = record.cwd { obj["cwd"] = cwd }
        if let sid = record.sessionID { obj["session_id"] = sid }

        let data = try JSONSerialization.data(withJSONObject: obj)
        let final = (dir as NSString).appendingPathComponent("\(record.tty).json")
        let temp = final + ".tmp"
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
