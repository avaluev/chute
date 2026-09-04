import Foundation
import ChuteCore

func hookStateSuite() {
    T.suite("HookState") {

        // ISOLATION HAS TO ACTUALLY ISOLATE. NSHomeDirectory() ignores $HOME, so the three
        // `HOME="$T"` cases in Scripts/smoke.sh were reading the developer's REAL
        // ~/.chute/sessions the whole time. "resume with no live session" passed only while that
        // machine happened to have no hook records; it failed the hour they were wired.
        let realHome = ProcessInfo.processInfo.environment["HOME"]
        let fake = NSTemporaryDirectory() + "chute-home-\(UInt32.random(in: 0...99999))"
        setenv("HOME", fake, 1)
        T.ok(Home.path == fake, "$HOME wins over the password database")
        T.ok(HookState.directory().hasPrefix(fake),
             "so the sessions directory follows a redirected HOME")
        T.ok(ContextBuffer.home.hasPrefix(fake), "and so does the basket")
        if let realHome { setenv("HOME", realHome, 1) } else { unsetenv("HOME") }
        T.no(HookState.directory().hasPrefix(fake), "and it follows HOME back again")

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
