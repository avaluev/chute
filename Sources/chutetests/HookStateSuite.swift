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
    }
}
