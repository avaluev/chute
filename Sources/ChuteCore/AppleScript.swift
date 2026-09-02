import Foundation

/// AppleScript is a string language. A quote or a backslash in interpolated text ends the literal
/// early and everything after it is read as code, not as text — so every script this repo builds
/// runs its interpolations through here.
///
/// There were FOUR hand-kept copies of this before 2026-09-01 (`FinderReveal`, `AgentCommands`
/// twice in one function, `ChuteFinderSync`, `Notify`) and two had already drifted: they mapped
/// `"` → `'`, which silently rewrites the user's text instead of escaping it. One function, four
/// callers, no sync to keep.
public enum AppleScript {
    /// Backslash FIRST. Escaping quotes first leaves a trailing backslash that escapes the
    /// CLOSING quote, and the rest of the payload becomes executable script.
    /// A literal newline is legal in a macOS file name and illegal inside an AppleScript string
    /// literal — the script fails to compile and the reveal reads "Finder did not respond".
    public static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
