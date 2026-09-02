import Foundation

/// Making a session portable: the command that picks the same conversation up somewhere else.
///
/// ── WHY THERE IS NO "MOVE TO TMUX" ──────────────────────────────────────────────────────────
///
/// macOS cannot transplant a running process onto a different terminal. `reptyr` does this on
/// Linux by attaching with ptrace and rewriting the process's file descriptors; the semantics it
/// depends on do not exist on macOS, and there is no equivalent. Any product that offers to
/// "move your session to tmux" on this platform is describing something the OS does not provide.
///
/// What is genuinely available — and what someone actually wants when they ask, which is a session
/// that survives closing the lid, a Terminal crash or a reboot — is to RE-CREATE it: a tmux session
/// in the same directory, with the agent resuming the same conversation by its own id. The old
/// window keeps running until it is closed. That is why the word here is "Continue" and never
/// "move", and why the string is copied rather than run.
public enum ResumeCommand {
    /// Agents whose resume syntax is actually known. Everything else returns nil rather than a
    /// guess: a command on the clipboard that fails when pasted is worse than no command, because
    /// the failure happens in the user's shell and looks like their mistake.
    static let resumeSyntax: [String: (String) -> String] = [
        "claude": { "claude --resume \($0)" },
    ]

    /// The id is the ONE field from the hook file that was reaching the clipboard unquoted, and
    /// `tmux` wraps the whole command in literal single quotes — so a `'` in it ended the quoting
    /// and the rest ran when pasted. `cwd` and `project` were both sanitised; this is the same
    /// rule `AgentTranscript.find` already applies to the same field: refuse rather than quote.
    public static func resume(agent: String?, sessionID: String) -> String? {
        guard let agent, let build = resumeSyntax[agent], !sessionID.isEmpty,
              sessionID.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") })
        else { return nil }
        return build(sessionID)
    }

    /// `new-session -A` attaches to a session of that name if one exists rather than failing, so
    /// pasting this twice is harmless.
    public static func tmux(project: String, cwd: String?,
                            agent: String?, sessionID: String) -> String? {
        guard let inner = resume(agent: agent, sessionID: sessionID) else { return nil }
        let dir = cwd.map { " -c \(shellQuote($0))" } ?? ""
        return "tmux new-session -A -s \(shellQuote(sessionName(project)))\(dir) '\(inner)'"
    }

    /// tmux session names cannot contain a colon or a period-delimited window reference, and a
    /// project name here came out of a terminal window TITLE — arbitrary text from another
    /// process. Reduced to letters, numbers, dot, dash and underscore; spaces become dashes.
    static func sessionName(_ project: String) -> String {
        let cleaned = project.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "." || $0 == "_" }
        return "chute-" + (cleaned.isEmpty ? "session" : cleaned)
    }

    /// Single quotes, with the one escape that single-quoting allows: close, escaped quote, reopen.
    ///
    /// The path this wraps arrives from a JSON file written by a shell hook and leaves on a
    /// clipboard the user will paste into a shell. It is not ours to trust just because it came
    /// off this machine.
    public static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }
}
