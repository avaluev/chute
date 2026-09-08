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

        // ttys004's hook carries a cwd whose leaf DISAGREES with the window title ("36.macai") —
        // proof that Phase 1c's wiring actually prefers the hook over the title, not just that it
        // compiles. A synthetic, `/nonexistent-…` path so this stays machine-independent: see
        // SignalSuite's own note on why a real absolute path would not be safe here.
        let hooks = ["ttys004": HookRecord(tty: "ttys004", state: .blocked,
                                          cwd: "/nonexistent-chute-test-root/renamed-project",
                                          timestamp: now.addingTimeInterval(-120))]
        let sessions = TerminalAppAdapter.parse(raw, hooks: hooks, now: now)

        T.eq(sessions.count, 3, "three tabs parsed")
        // NO HOOK, NO CWD: the window title's head is still the last resort — unchanged from
        // before Phase 1c, because these two tabs have no hook record at all.
        T.eq(sessions[0].project, "sntz_mockups", "project taken from the window name")
        T.eq(sessions[1].project, "docs", "project for a plain shell")
        // A HOOK, WITH A CWD: the cwd's leaf wins over the window title outright — this is the
        // whole point of Phase 1c. Before this wiring, `sessions[2].project` read "36.macai" (the
        // window title's head); now it reads the hook's cwd instead.
        T.eq(sessions[2].project, "renamed-project",
             "once a hook carries a cwd, ITS leaf names the session — never the window title")
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

        // ANTIGRAVITY. The founder's tab reported `agy.1788445358670789000.old` — an update had
        // renamed the binary under the running process — and it read as a plain shell, so the menu
        // said "no agent running" while an agent was plainly running in it.
        T.eq(TerminalAppAdapter.agentName(in: "login-zsh, agy"), "agy", "the Antigravity CLI is an agent")
        T.eq(TerminalAppAdapter.agentName(in: "login-zsh, agy.1788445358670789000.old"), "agy",
             "and still is after an update renames the binary under it")
        T.eq(SessionPhrasing.detail(agent: "agy", transcript: nil), "Antigravity",
             "and it is called Antigravity, not agy")
        // It ships no hooks (`agy help` has no such subcommand), so it can never report a state.
        // The honest answer is unknown — never "working" off Terminal's busy flag.
        T.eq(StateResolver.resolve(hook: nil, isAgent: true,
                                   now: Date(timeIntervalSince1970: 1_756_219_200)),
             .unknown, "an agent with no hooks reports nothing, and Chute says so")
        T.no(sessions[1].isAgent, "a plain shell is not an agent")
        T.eq(sessions[1].state, .idle, "plain idle shell")
        T.eq(sessions[2].state, .blocked, "the hook for ttys004 wins")
        T.eq(sessions[0].state, .unknown,
             "a hookless agent is unknown — its title glyph is not cleared when the turn ends")
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

        // `TerminalAppAdapter.project(fromWindowName:)` is DELETED — Phase 1c moved its body,
        // verbatim, to `ProjectName.titleHead`, which is where its own coverage now lives (see
        // PathAbbrevSuite.swift's "titleHead" block).
    }
}
