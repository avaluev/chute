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

        // WHICH AGENT, NOT WHETHER. The adapter matched the name out of the process list and then
        // collapsed it to a Bool, so the menu could say a session was an agent but never which
        // one — and the "Claude Code" a user sees today is the terminal WINDOW TITLE leaking
        // through, a string Chute neither derived nor can rely on.
        T.eq(sessions[0].agent, "claude", "the matched agent's name survives")
        T.eq(sessions[1].agent, nil, "a plain shell has no agent")
        T.eq(sessions[0].isAgent, sessions[0].agent != nil, "isAgent still agrees with agent")
        T.eq(sessions[1].isAgent, sessions[1].agent != nil, "on both branches")

        // cursor was missing from the list entirely, so a Cursor terminal read as a plain shell
        // and never appeared under "Agents Working".
        let cursorRaw = rec(["1", "app — cursor", "1", "/dev/ttys009", "true", "true",
                             "login-zsh, cursor-agent, node", "editing"])
        T.eq(TerminalAppAdapter.parse(cursorRaw, hooks: [:], now: now).first?.agent, "cursor",
             "cursor is recognised")

        // The longest match wins, so "claude" inside "claude-code" cannot mask a different agent
        // and the order of the table cannot change the answer.
        T.eq(TerminalAppAdapter.agentName(in: "login-zsh, node"), nil, "no agent is nil, not \"\"")
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

        // Proves the helper consults its argument AND that the ps-based match actually works.
        // `launchd` is running on every macOS machine including CI, so this is deterministic —
        // unlike asserting on Terminal.app, which is not running on a CI runner.
        T.ok(isAppRunning(bundleExecutable: "launchd"),
             "a process that is always running is detected")
        T.no(isAppRunning(bundleExecutable: "NoSuchApp.app/Contents/MacOS/NoSuchApp"),
             "an app that is not running is reported absent")

        // Project extraction edge cases.
        T.eq(TerminalAppAdapter.project(fromWindowName: "36.macai — ◑ Chut — x"), "36.macai", "first segment")
        T.eq(TerminalAppAdapter.project(fromWindowName: "solo"), "solo", "no separator")
        T.eq(TerminalAppAdapter.project(fromWindowName: ""), "—", "empty name has a placeholder")
    }
}
