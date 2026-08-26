import Foundation

/// The one list of things Chute can do to what you have selected in Finder.
///
/// It lives in ChuteCore because THREE surfaces must agree on it: the Finder context menu
/// (`ChuteFinder.appex`), the menu-bar HUD (`ChuteApp`), and the tests (`chute finder-actions
/// --json` drives the end-to-end suite). Two hand-maintained copies of this list is exactly how
/// the menu ended up offering actions that could not work.
///
/// NAMING RULE: a title says what happens and where it lands, in words someone who has never read
/// the README would use. No jargon ("bundle", "yolo", "unpack"), no abbreviations, and never a
/// name that hides a dry run behind a verb that promises a write.
public struct ChuteAction: Sendable, Equatable {
    /// What the action needs to work on.
    public enum Scope: String, Sendable {
        case selection   // the items selected in Finder
        case folder      // the folder in view (or the parent of the selected file)
    }

    public let id: String
    /// Plain-language menu title. `{n}` is replaced with the selection count.
    public let title: String
    /// One line for a tooltip: what lands where.
    public let detail: String
    /// Menu section. Items are grouped in table order and separated by a divider.
    public let group: String
    public let scope: Scope
    /// Actions that only make sense inside a git repository are hidden elsewhere, rather than
    /// offered and then failing with "not a git repository".
    public let requiresGit: Bool
    /// Command line with `{dir}` and `{files}` placeholders.
    public let template: [String]
    /// Shown when the command says nothing on stderr.
    public let doneMessage: String

    public func title(count: Int) -> String {
        title.replacingOccurrences(of: "{n}", with: "\(count)")
    }

    /// The title with the count dropped entirely — for surfaces that do not know the selection
    /// when the menu is drawn, and for notification subtitles.
    public var plainTitle: String {
        title.replacingOccurrences(of: " ({n})", with: "")
    }
}

public enum ChuteActions {
    public static let all: [ChuteAction] = [
        // ---- Give context to an agent ------------------------------------------------------
        ChuteAction(id: "copy-paths",
                    title: "Copy Paths ({n})",
                    detail: "Full paths of the selected items, ready to paste into a prompt.",
                    group: "Give to your agent", scope: .selection, requiresGit: false,
                    template: ["paths", "{files}"],
                    doneMessage: "Paths copied."),
        ChuteAction(id: "copy-contents",
                    title: "Copy Paths + Contents ({n})",
                    detail: "Every selected file's contents in one block the agent can read.",
                    group: "Give to your agent", scope: .selection, requiresGit: false,
                    template: ["bundle", "--format", "xml", "{files}"],
                    doneMessage: "Contents copied."),
        ChuteAction(id: "copy-masked",
                    title: "Copy Contents, Secrets Masked ({n})",
                    detail: "Same, with API keys and tokens replaced by [REDACTED].",
                    group: "Give to your agent", scope: .selection, requiresGit: false,
                    template: ["redact", "{files}"],
                    doneMessage: "Copied with secrets masked."),
        ChuteAction(id: "token-cost",
                    title: "Count Tokens ({n})",
                    detail: "Will the selection fit in the context window? Copies the tally.",
                    group: "Give to your agent", scope: .selection, requiresGit: false,
                    template: ["tokens", "{files}"],
                    doneMessage: "Token cost copied."),
        ChuteAction(id: "copy-tree",
                    title: "Copy Folder Layout",
                    detail: "This folder's structure as a tree, junk folders left out.",
                    group: "Give to your agent", scope: .folder, requiresGit: false,
                    template: ["tree", "{dir}"],
                    doneMessage: "Folder layout copied."),

        // ---- Take what the agent gave back -------------------------------------------------
        ChuteAction(id: "clipboard-to-file",
                    title: "Save Clipboard as a New File Here",
                    detail: "Names it from its heading, picks the extension from its syntax.",
                    group: "Take from your agent", scope: .folder, requiresGit: false,
                    template: ["new", "--reveal", "--dir", "{dir}"],
                    doneMessage: "File created."),
        ChuteAction(id: "clipboard-to-files",
                    title: "Write Clipboard's Code Blocks as Files Here",
                    detail: "A multi-file answer becomes real files. Existing files are never overwritten.",
                    group: "Take from your agent", scope: .folder, requiresGit: false,
                    template: ["unpack", "--force", "--dir", "{dir}"],
                    doneMessage: "Files written."),

        // ---- Guard rails around a running agent --------------------------------------------
        ChuteAction(id: "snapshot",
                    title: "Snapshot This Folder Before an Agent Runs",
                    detail: "A git snapshot including untracked files. Your worktree is untouched.",
                    group: "Before and after", scope: .folder, requiresGit: true,
                    template: ["checkpoint", "{dir}"],
                    doneMessage: "Snapshot taken."),
        ChuteAction(id: "review-changes",
                    title: "Copy What Changed Here",
                    detail: "The full patch of what the agent changed, on the clipboard.",
                    group: "Before and after", scope: .folder, requiresGit: true,
                    template: ["diff", "{dir}", "--copy"],
                    doneMessage: "Patch copied."),
        ChuteAction(id: "workspace",
                    title: "New Agent Workspace Here",
                    detail: "A fresh folder with git, CLAUDE.md and a terminal running the agent.",
                    group: "Before and after", scope: .folder, requiresGit: false,
                    template: ["sandbox", "--dir", "{dir}"],
                    doneMessage: "Workspace created."),

        // ---- Plain utility ------------------------------------------------------------------
        ChuteAction(id: "terminal",
                    title: "Open Terminal Here",
                    detail: "A terminal window already sitting in this folder.",
                    group: "Open", scope: .folder, requiresGit: false,
                    template: ["open", "{dir}"],
                    doneMessage: "Terminal opened."),
    ]

    public static func find(_ id: String) -> ChuteAction? { all.first { $0.id == id } }

    /// Expand an action's template into a real command line.
    /// `{files}` expands in place to every selected path; `{dir}` to the folder in view.
    public static func argv(_ action: ChuteAction, dir: String, files: [String]) -> [String] {
        var out: [String] = []
        for token in action.template {
            switch token {
            case "{files}": out += files
            case "{dir}":   out.append(dir)
            default:        out.append(token)
            }
        }
        return out
    }

    /// Which actions to show for the current Finder context. Ordered as declared, so the menu
    /// groups stay in a deliberate order rather than dictionary order.
    public static func visible(hasSelection: Bool, inGitRepo: Bool) -> [ChuteAction] {
        all.filter { action in
            if action.scope == .selection && !hasSelection { return false }
            if action.requiresGit && !inGitRepo { return false }
            return true
        }
    }

    /// Walks up from `dir` looking for `.git`. Deliberately not `git rev-parse`: a menu is built
    /// while the user waits, and this must not spawn a process per right-click.
    public static func isInGitRepo(_ dir: String) -> Bool {
        var path = (dir as NSString).standardizingPath
        while path.count > 1 {
            if FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent(".git")) {
                return true
            }
            path = (path as NSString).deletingLastPathComponent
        }
        return false
    }

    /// Turn what the CLI said into one line a human can act on.
    /// The CLI writes progress to stderr with a `→ ` prefix and failures with a `chute: ` prefix;
    /// neither prefix means anything to someone reading a notification.
    public static func message(stderr: String, exitCode: Int32, fallback: String) -> String {
        let line = stderr
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last(where: { !$0.isEmpty })
        guard var text = line, !text.isEmpty else {
            return exitCode == 0 ? fallback : "Failed — the command said nothing."
        }
        for prefix in ["→ ", "chute: "] where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }
        if exitCode != 0 { return "Failed — " + text }
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
