import Foundation
import ChuteCore

func terminalParseSuite() {
    T.suite("TerminalAppAdapter.parse") {
        let now = Date(timeIntervalSince1970: 1_756_219_200)
        let US = "\u{1F}", RS = "\u{1E}"
        func rec(_ f: [String]) -> String { f.joined(separator: US) }

        let raw = [
            rec(["207250", "sntz_mockups — ✳ File-size gate refactor complete — node ◂ claude",
                 "1", "/dev/ttys000", "true", "true",
                 "login-zsh, claude, node, mcp@latest", "✳ File-size gate refactor complete"]),
            rec(["207397", "docs — -zsh — 80×24", "1", "/dev/ttys003", "false", "true",
                 "login-zsh", "Terminal"]),
            rec(["210583", "36.macai — ◑ Chut — caffeinate ◂ claude — 245×76",
                 "1", "/dev/ttys004", "true", "true",
                 "login-zsh, claude, node, caffeinate", "◑ Chut"]),
        ].joined(separator: RS)

        let hooks = ["ttys004": HookRecord(tty: "ttys004", state: .blocked,
                                          timestamp: now.addingTimeInterval(-120))]
        let sessions = TerminalAppAdapter.parse(raw, hooks: hooks, now: now)

        T.eq(sessions.count, 3, "three tabs parsed")
        T.eq(sessions[0].project, "sntz_mockups", "project taken from the window name")
        T.eq(sessions[1].project, "docs", "project for a plain shell")
        T.eq(sessions[0].tty, "ttys000", "tty normalised")
        T.eq(sessions[0].windowID, 207250, "window id parsed")
        T.ok(sessions[0].isAgent, "claude in the process list means agent")
        T.no(sessions[1].isAgent, "a plain shell is not an agent")
        T.eq(sessions[1].state, .idle, "plain idle shell")
        T.eq(sessions[2].state, .blocked, "the hook for ttys004 wins")
        T.eq(sessions[0].state, .working, "glyph resolves the hookless agent")
        T.eq(sessions[2].key, "Terminal:210583:ttys004", "key built from kind, window and tty")

        // Malformed input must degrade, never crash.
        T.eq(TerminalAppAdapter.parse("", hooks: [:], now: now).count, 0, "empty input")
        T.eq(TerminalAppAdapter.parse("garbage", hooks: [:], now: now).count, 0, "too few fields")
        T.eq(TerminalAppAdapter.parse(rec(["notanumber", "p — t", "1", "ttys1", "false", "true", "zsh", "t"]),
                                      hooks: [:], now: now).count, 0, "non-numeric window id is skipped")

        // A VALID window id with a truncated record: this exercises the f.count >= 8 half of the
        // guard, which the "garbage" fixture cannot reach because it fails the Int(f[0]) half first.
        T.eq(TerminalAppAdapter.parse(rec(["207250", "proj — title", "1", "/dev/ttys000", "true"]),
                                      hooks: [:], now: now).count, 0,
             "a record with a valid window id but too few fields is skipped, not indexed into")

        // Proves the helper actually consults its argument. Before the fix this returned true for
        // ANY name whenever Terminal.app happened to be running.
        T.no(isProcessRunning("no-such-process-9f3a2b7c"), "an absent process is reported absent")

        // Project extraction edge cases.
        T.eq(TerminalAppAdapter.project(fromWindowName: "36.macai — ◑ Chut — x"), "36.macai", "first segment")
        T.eq(TerminalAppAdapter.project(fromWindowName: "solo"), "solo", "no separator")
        T.eq(TerminalAppAdapter.project(fromWindowName: ""), "—", "empty name has a placeholder")
    }
}
