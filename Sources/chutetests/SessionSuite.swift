import Foundation
import ChuteCore

func sessionSuite() {
    T.suite("Session") {
        T.eq(Session.normalise(tty: "/dev/ttys004"), "ttys004", "strips /dev prefix")
        T.eq(Session.normalise(tty: "ttys004"), "ttys004", "already normalised is unchanged")
        T.eq(Session.makeKey(kind: .terminalApp, windowID: 207250, tty: "/dev/ttys004"),
             "Terminal:207250:ttys004", "stable session key")
        T.ok(SessionState.blocked < SessionState.waiting, "blocked outranks waiting")
        T.ok(SessionState.waiting < SessionState.idle, "waiting outranks idle")
        T.eq(SessionState.blocked.label, "BLOCKED", "label")

        // The load label names its unit.
        let busy = SessionLoad(cpuPercent: 12.4, residentBytes: 1_610_612_736, processes: 3)
        T.eq(busy.label, "12% CPU · 1.5 GB memory", "both numbers say what they measure")

        // WHAT THE ROW SAYS. The old row was "<project>   <window title>", and the window title
        // is written by whatever is running — which is why the menu appeared to say "Claude Code"
        // without Chute knowing anything. This is built from what Chute actually established.
        func sess(agent: String?, state: SessionState, since: Date?) -> Session {
            Session(key: "k", kind: .terminalApp, windowID: 1, tabIndex: 1, tty: "ttys004",
                    project: "37.chute", title: "◑ something", agent: agent, busy: true,
                    state: state, since: since, sessionID: "id", cwd: "/p")
        }
        let t = AgentTranscript(sessionID: "id", model: "claude-opus-5", effort: "high",
                                version: "2.1.250", branch: "main", cwd: "/p",
                                outputTokens: 352_928, cacheReadTokens: 88_247_948, cacheWriteTokens: 0)

        T.eq(SessionPhrasing.detail(agent: "claude", transcript: t),
             "Claude Code · Opus 5 · high", "agent, model and effort, in that order")
        T.eq(SessionPhrasing.detail(agent: "claude", transcript: nil), "Claude Code",
             "with no transcript it says only what it is sure of")
        T.eq(SessionPhrasing.detail(agent: "cursor", transcript: nil), "Cursor", "other agents are named")
        T.eq(SessionPhrasing.detail(agent: nil, transcript: nil), "no agent running",
             "and a plain shell says so, rather than naming the terminal it obviously is")

        // Effort is dropped when it is the default — a row that says "high" on the one session
        // running high is information; a row that says "medium" on all of them is furniture.
        let medium = AgentTranscript(sessionID: "id", model: "claude-opus-5", effort: "medium",
                                     version: nil, branch: nil, cwd: nil, outputTokens: 0,
                                     cacheReadTokens: 0, cacheWriteTokens: 0)
        T.eq(SessionPhrasing.detail(agent: "claude", transcript: medium),
             "Claude Code · Opus 5", "the default effort is not worth a word")
    }
}
