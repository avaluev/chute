import Foundation
import ChuteCore

func hookStateSuite() {
    T.suite("HookState") {
        let json = Data("""
        {"tty":"ttys004","state":"blocked","cwd":"/Users/sxope/p","session_id":"abc","ts":1756219200}
        """.utf8)
        guard let r = HookState.parse(json) else {
            T.ok(false, "parses a well-formed record"); return
        }
        T.eq(r.tty, "ttys004", "tty parsed")
        T.eq(r.state, .blocked, "state parsed")
        T.eq(r.cwd ?? "", "/Users/sxope/p", "cwd parsed")
        T.eq(r.timestamp, Date(timeIntervalSince1970: 1_756_219_200), "timestamp parsed")

        T.ok(HookState.parse(Data("not json".utf8)) == nil, "garbage returns nil, never throws")
        T.ok(HookState.parse(Data("{}".utf8)) == nil, "missing fields returns nil")
        T.ok(HookState.parse(Data(#"{"tty":"t","state":"nonsense","ts":1}"#.utf8)) == nil,
             "unknown state string returns nil")
        T.ok(HookState.parse(Data(#"{"tty":"/dev/ttys004","state":"waiting","ts":1}"#.utf8))?.tty == "ttys004",
             "tty is normalised on the way in")

        // Round-trip through a real temp directory.
        let root = NSTemporaryDirectory() + "chute-hookstate-test-\(UInt32.random(in: 0...99999))"
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rec = HookRecord(tty: "ttys009", state: .waiting,
                             timestamp: Date(timeIntervalSince1970: 1_756_219_200))
        T.noThrow("writes a record") { try HookState.write(rec, root: root) }
        let all = HookState.readAll(root: root)
        T.eq(all.count, 1, "one record read back")
        T.eq(all["ttys009"]?.state, .waiting, "keyed by normalised tty")

        T.eq(HookState.readAll(root: root + "-does-not-exist").count, 0,
             "a missing directory is empty, not an error")

        // A caller handing write() an AppleScript-style tty must still produce a joinable key.
        let rawTTY = HookRecord(tty: "/dev/ttys077", state: .blocked,
                                timestamp: Date(timeIntervalSince1970: 1_756_219_200))
        T.noThrow("writes a record carrying a /dev-prefixed tty") { try HookState.write(rawTTY, root: root) }
        let joined = HookState.readAll(root: root)
        T.ok(joined["ttys077"] != nil, "write normalises the tty so the key joins on read")
        T.eq(joined["ttys077"]?.state, .blocked, "the normalised record round-trips intact")

        // PHANTOM BADGE — a hook record from a window that has since been closed must not count.
        let now = Date(timeIntervalSince1970: 1_756_219_200)
        func make(_ tty: String, _ state: SessionState, ageHours: Double) -> HookRecord {
            HookRecord(tty: tty, state: state, timestamp: now.addingTimeInterval(-ageHours * 3600))
        }
        let records: [String: HookRecord] = [
            "ttys001": make("ttys001", .waiting, ageHours: 0.1),   // live, fresh   → counts
            "ttys002": make("ttys002", .blocked, ageHours: 0.1),   // dead tty      → phantom
            "ttys003": make("ttys003", .waiting, ageHours: 7),     // live, stale   → dropped
            "ttys004": make("ttys004", .working, ageHours: 0.1),   // live, working → not attention
            "ttys005": make("ttys005", .waiting, ageHours: -2),    // clock skew    → untrusted
        ]
        let live: Set<String> = ["ttys001", "ttys003", "ttys004", "ttys005"]
        let hot = HookState.attention(records, live: live, now: now)
        T.eq(hot.count, 1, "only the live, fresh, attention-seeking record badges")
        T.eq(hot.first?.tty, "ttys001", "and it is the live one")
        T.eq(HookState.attention(records, live: [], now: now).count, 0,
             "no live ttys means no badge, however many hook files linger")

        // liveTTYs reads the real process table: this test process has one, and "??" never leaks.
        let realLive = HookState.liveTTYs()
        T.ok(!realLive.contains("??"), "a process with no controlling terminal is not a tty")
        T.ok(realLive.allSatisfy { !$0.isEmpty && $0.allSatisfy { c in c.isLetter || c.isNumber } },
             "every live tty is a bare alphanumeric name")

        // EMPTY IS ABSENT. The hook writes "session_id":"" for anything that is not Claude Code,
        // and for a Claude Code old enough not to export CLAUDE_CODE_SESSION_ID. An empty string
        // must read as nil, or every such session looks like one whose id is the empty string —
        // and a resume command built from it would be silently wrong.
        let blank = HookState.parse(Data(#"{"tty":"ttys004","state":"working","cwd":"/p","session_id":"","ts":1}"#.utf8))
        T.eq(blank?.sessionID, nil, "an empty session_id is absent, not empty")
        T.eq(blank?.cwd, "/p", "and the rest of the record still parses")

        let real = HookState.parse(Data(#"{"tty":"ttys004","state":"working","session_id":"14e46ac7-12b2","ts":1}"#.utf8))
        T.eq(real?.sessionID, "14e46ac7-12b2", "a real one comes through")

        let missing = HookState.parse(Data(#"{"tty":"ttys004","state":"working","ts":1}"#.utf8))
        T.eq(missing?.sessionID, nil, "an older snippet that omits the field still parses")
    }
}
