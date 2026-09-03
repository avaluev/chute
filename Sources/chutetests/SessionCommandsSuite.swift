import Foundation
import ChuteCore

func sessionCommandsSuite() {
    T.suite("SessionCommand") {
        func sess(agent: String?, sessionID: String?) -> Session {
            Session(key: "k", kind: .terminalApp, windowID: 1, tabIndex: 1, tty: "ttys004",
                    project: "37.chute", title: "◑ something", agent: agent, busy: true,
                    state: .waiting, since: nil, sessionID: sessionID, cwd: "/p")
        }
        func kinds(_ s: Session, _ t: AgentTranscript? = nil, tmux: Bool = false) -> [String] {
            SessionCommand.available(for: s, transcript: t, hasTmux: tmux).map(\.kind)
        }
        let spent = AgentTranscript(sessionID: "id", model: nil, effort: nil, version: nil,
                                    branch: nil, cwd: nil, outputTokens: 352_928,
                                    cacheReadTokens: 88_247_948, cacheWriteTokens: 0)
        let fresh = AgentTranscript(sessionID: "id", model: nil, effort: nil, version: nil,
                                    branch: nil, cwd: nil, outputTokens: 0,
                                    cacheReadTokens: 0, cacheWriteTokens: 0)

        // ── WHICH COMMANDS A ROW OFFERS ────────────────────────────────────────────────────
        T.eq(kinds(sess(agent: "claude", sessionID: nil)), [],
             "no session id — an older hook wrote the record, there is nothing to resume")
        T.eq(kinds(sess(agent: "claude", sessionID: "abc-123")), ["copyID", "copyResume"],
             "a known agent offers its id and its resume command")
        T.eq(kinds(sess(agent: "claude", sessionID: "abc-123"), tmux: true),
             ["copyID", "copyResume", "tmux"], "and tmux, where tmux is installed")

        // The one that puts a failing command on someone's clipboard if it regresses.
        T.eq(kinds(sess(agent: "aider", sessionID: "abc-123"), tmux: true), ["copyID"],
             "an agent whose resume syntax is unknown offers neither resume nor tmux")
        T.eq(kinds(sess(agent: nil, sessionID: "abc-123"), tmux: true), ["copyID"],
             "and a plain shell offers only the id")
        T.eq(kinds(sess(agent: "claude", sessionID: "no spaces allowed"), tmux: true), ["copyID"],
             "an id ResumeCommand refuses to quote takes tmux down with it")

        T.eq(kinds(sess(agent: "claude", sessionID: "abc-123"), spent),
             ["copyID", "copyResume", "copyCost"], "a transcript with tokens adds the cost row")
        T.eq(kinds(sess(agent: "claude", sessionID: "abc-123"), fresh), ["copyID", "copyResume"],
             "a transcript that has spent nothing does not — 0 out · 0 cached is not information")
        T.eq(kinds(sess(agent: nil, sessionID: "abc-123"), spent), ["copyID", "copyCost"],
             "cost does not depend on the resume syntax being known")

        T.ok(SessionCommand.available(for: sess(agent: "claude", sessionID: "abc-123"),
                                      transcript: spent, hasTmux: true)
                .allSatisfy { !$0.title.isEmpty },
             "every offered command carries a title")

        // ── WHICH MODIFIER REVEALS EACH ONE ───────────────────────────────────────────────
        //
        // THE LOAD-BEARING ONE. AppKit draws ONE alternate per distinct modifier mask, so two
        // commands sharing a mask means the second row is built, is correct, and is never seen.
        // Nothing in the drawing code can notice that; this can.
        let masks = SessionCommand.Kind.allCases.map { SessionCommand.modifiers(for: $0.rawValue) }
        T.eq(Set(masks).count, SessionCommand.Kind.allCases.count,
             "every command has its own mask — a shared one silently hides a row")
        T.ok(masks.allSatisfy { $0.contains(.option) },
             "every mask carries ⌥, which is what the row's tooltip promises")

        T.eq(SessionCommand.modifiers(for: "copyID"), [.option], "the plain alternate is ⌥")
        T.eq(SessionCommand.modifiers(for: "copyResume"), [.option, .shift], "resume is ⌥⇧")
        T.eq(SessionCommand.modifiers(for: "tmux"), [.option, .command], "tmux is ⌥⌘")
        T.eq(SessionCommand.modifiers(for: "copyCost"), [.option, .control], "cost is ⌥⌃")
        T.eq(SessionCommand.modifiers(for: "not-a-kind"), [.option],
             "an unknown kind falls back to plain ⌥ rather than to no modifier at all")
    }
}
