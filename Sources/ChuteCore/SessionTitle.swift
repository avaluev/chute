import Foundation

/// WHICH of the four tabs open on the same directory is this one.
///
/// The project name answers "where", and on a machine running six agents inside one repo that is
/// the same answer six times: the founder reported four Antigravity tabs in one directory as
/// "invisible", and they were — same project, same path, same agent, so the menu drew the same
/// row four times over. The terminal's own tab title is the only thing that differs, and Chute
/// has been collecting it into `Session.title` all along and spending it on a tooltip.
///
/// THIS IS NOT THE PROJECT NAME AND CANNOT BECOME IT. `ProjectName` derives from the kernel's cwd
/// precisely because a window title is a string another process writes and the user can
/// reconfigure; that ruling stands. A label is allowed to be wrong in a way a name is not — it
/// sits beside the row, it names nothing, and nothing else is derived from it.
public enum SessionTitle {
    /// Titles that identify a category rather than a session. `claude` sets "Claude Code" before
    /// it has named the conversation, and Antigravity sets a literal "Terminal" and never
    /// revisits it — both are true, both are useless, and both are already spelled out one column
    /// to the right under the agent's own name.
    static let generic: Set<String> = [
        "terminal", "iterm", "iterm2", "console",
        "bash", "-bash", "zsh", "-zsh", "sh", "fish", "login", "tmux", "ssh", "node",
        "claude", "claude code", "codex", "cursor", "cursor-agent", "gemini", "aider",
        "agy", "antigravity",
    ]

    /// The title if it distinguishes this session from its neighbours, else nil.
    ///
    /// THE LEADING STATUS GLYPH IS STRIPPED, not kept. `claude` prefixes its title with a
    /// spinner (`✳`, `◑`, `◐`) that changes as it works, which is two problems in one character:
    /// "◑ Claude Code" and "✳ Claude Code" are the same useless title wearing two hats, and `✳`
    /// is an EMOJI-PRESENTATION character — the first render of this cell put a green blob beside
    /// every row, an inch from Chute's own coloured state square, saying the same thing worse.
    /// The state belongs to the dot and to column 2; this cell is for the words.
    public static func meaningful(_ title: String, project: String?) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let core = trimmed.drop { !$0.isLetter && !$0.isNumber }
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !core.isEmpty else { return nil }
        let folded = core.lowercased()
        guard !generic.contains(folded) else { return nil }
        // A title that just repeats the project name is the same redundancy as a generic one,
        // arriving by a different door: the row already says it, one line up.
        guard folded != project?.lowercased() else { return nil }
        return core
    }
}
