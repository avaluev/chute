import Foundation

/// The one list of things Chute does to what you have selected in Finder.
///
/// It lives in ChuteCore because THREE surfaces must agree on it: the Finder context menu
/// (`ChuteFinder.appex`), the menu-bar HUD (`ChuteApp`), and the tests (`chute finder-actions
/// --json` drives the end-to-end suite). Two hand-maintained copies is how the menu ended up
/// offering actions that could not work.
///
/// NAMING: Apple's own menu wording — a verb, title case, no jargon, no abbreviations, and never
/// a name that promises something the command does not do.
public struct ChuteAction: Sendable, Equatable {
    /// What the action needs to work on.
    public enum Scope: String, Sendable {
        case selection   // the items selected in Finder
        case folder      // the folder in view, or the folder that is selected
    }

    public let id: String
    public let title: String
    /// One line for a tooltip: what happens and where it lands.
    public let detail: String
    public let scope: Scope
    /// Only offered when the thing clicked is a folder. A file tree of a PDF is nonsense.
    public let foldersOnly: Bool
    /// When set, the item lives inside a submenu with this title, next to its siblings.
    public let parentTitle: String?
    /// Command line with `{dir}` and `{files}` placeholders.
    public let template: [String]
    /// Shown when the command says nothing on its own.
    public let doneMessage: String

    public init(id: String, title: String, detail: String, scope: Scope,
                foldersOnly: Bool = false, parentTitle: String? = nil,
                template: [String], doneMessage: String) {
        self.id = id; self.title = title; self.detail = detail; self.scope = scope
        self.foldersOnly = foldersOnly; self.parentTitle = parentTitle
        self.template = template; self.doneMessage = doneMessage
    }

    public func title(count: Int) -> String {
        title.replacingOccurrences(of: "{n}", with: "\(count)")
    }

    /// The title with the count dropped — for surfaces that draw the menu before they know the
    /// selection, and for notification subtitles.
    public var plainTitle: String { title.replacingOccurrences(of: " ({n})", with: "") }
}

public enum ChuteActions {
    public static let all: [ChuteAction] = [
        ChuteAction(id: "copy-paths",
                    title: "Copy Full Paths ({n})",
                    detail: "Every selected file and folder, as full paths, on the clipboard.",
                    scope: .selection,
                    template: ["paths", "{files}"],
                    doneMessage: "Full paths copied."),

        // A folder's whole shape, for handing an agent context it can navigate. Three depths
        // rather than a dialog: a right-click menu cannot ask a question.
        ChuteAction(id: "tree-2",
                    title: "2 Levels",
                    detail: "This folder and one level inside it.",
                    scope: .folder, foldersOnly: true, parentTitle: "Copy Folder Tree",
                    template: ["tree", "{dir}", "--depth", "2"],
                    doneMessage: "Folder tree copied."),
        ChuteAction(id: "tree-4",
                    title: "4 Levels",
                    detail: "Deep enough for most projects.",
                    scope: .folder, foldersOnly: true, parentTitle: "Copy Folder Tree",
                    template: ["tree", "{dir}", "--depth", "4"],
                    doneMessage: "Folder tree copied."),
        ChuteAction(id: "tree-all",
                    title: "Everything",
                    detail: "The entire tree, with build and dependency folders left out.",
                    scope: .folder, foldersOnly: true, parentTitle: "Copy Folder Tree",
                    template: ["tree", "{dir}", "--depth", "99"],
                    doneMessage: "Folder tree copied."),

        ChuteAction(id: "new-markdown",
                    title: "New Markdown File",
                    detail: "An empty Untitled.md in this folder, revealed in Finder.",
                    scope: .folder,
                    template: ["new", "--blank", "--reveal", "--dir", "{dir}"],
                    doneMessage: "Markdown file created."),

        ChuteAction(id: "new-markdown-clipboard",
                    title: "New Markdown File from Clipboard",
                    detail: "The clipboard saved here, named after its first line.",
                    scope: .folder,
                    template: ["new", "--naming", "underscore", "--ext", "md", "--reveal", "--dir", "{dir}"],
                    doneMessage: "Markdown file created."),

        ChuteAction(id: "terminal",
                    title: "Open in Terminal",
                    detail: "A terminal window already sitting in this folder.",
                    scope: .folder,
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

    /// Which actions to show for the current Finder context, in declared order — a menu that
    /// reshuffles between right-clicks is a menu you cannot learn.
    public static func visible(hasSelection: Bool, targetIsFolder: Bool) -> [ChuteAction] {
        all.filter { action in
            if action.scope == .selection && !hasSelection { return false }
            if action.foldersOnly && !targetIsFolder { return false }
            return true
        }
    }

    /// Turn what the CLI said into one line a human can act on. The CLI writes progress to stderr
    /// with a `→ ` prefix and failures with a `chute: ` prefix; neither means anything in a banner.
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
