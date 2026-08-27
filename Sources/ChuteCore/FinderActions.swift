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
    /// SF Symbol drawn beside the title. With the actions inlined into Finder's own context
    /// menu (no `Chute ▸` wrapper), the icons are what makes the group read as one product.
    public let symbol: String
    /// Command line with `{dir}` and `{files}` placeholders.
    public let template: [String]
    /// Shown when the command says nothing on its own.
    public let doneMessage: String
    /// Non-nil for an action that CHANGES FILES. The app runs the command's dry run first, shows
    /// the list it printed, and only re-runs it with `--force` if the user presses this button.
    ///
    /// A right-click that silently writes into a repo is the one thing that would destroy the
    /// trust the rest of this product is sold on, so the destructive step is never the same click
    /// as the one that opened the menu. `unpack` and `clean` both preview by default already
    /// (NFR-05) — this carries that guarantee across the Finder boundary instead of restating it.
    public let confirmButton: String?

    public init(id: String, title: String, detail: String, scope: Scope,
                foldersOnly: Bool = false, parentTitle: String? = nil,
                symbol: String, template: [String], doneMessage: String,
                confirmButton: String? = nil) {
        self.id = id; self.title = title; self.detail = detail; self.scope = scope
        self.foldersOnly = foldersOnly; self.parentTitle = parentTitle
        self.symbol = symbol
        self.template = template; self.doneMessage = doneMessage
        self.confirmButton = confirmButton
    }

    /// True for anything that writes or deletes. Reads as a question at the call site.
    public var isDestructive: Bool { confirmButton != nil }

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
                    symbol: "list.clipboard.fill",
                    template: ["paths", "{files}"],
                    doneMessage: "Full paths copied."),

        // THE WEDGE. Eight files and everything in them, as one blob with a token count, in one
        // click. It was CLI-only until now, which meant the largest saving in the JTBD ledger was
        // invisible to anyone who never opened a terminal — and unfilmable for the demo that is
        // supposed to carry it. XML only: the format is the default everywhere else, and a menu
        // that asks "which format?" before the most-used action taxes every use to serve a few.
        // `chute bundle --format md` still exists for the people who want it.
        ChuteAction(id: "bundle-xml",
                    title: "Copy Files with Contents ({n})",
                    detail: "Every selected file and everything in it, in one blob, with a token count.",
                    scope: .selection,
                    symbol: "shippingbox.fill",
                    template: ["bundle", "{files}"],
                    doneMessage: "Files and contents copied."),

        // The other direction, and the second-largest saving in the ledger (JTBD #9, 28.5 min/day).
        // It was CLI-only, which meant the buyer never saw the half of the loop that gets the
        // agent's answer back onto disk. Destructive, so it previews first — see `confirmButton`.
        ChuteAction(id: "unpack-here",
                    title: "Write Clipboard Files Here",
                    detail: "The files in a copied answer, written into this folder — after you see the list.",
                    scope: .folder,
                    symbol: "arrow.down.doc.fill",
                    template: ["unpack", "--dir", "{dir}"],
                    doneMessage: "Files written.",
                    confirmButton: "Write Files"),

        // A folder's whole shape, for handing an agent context it can navigate. Three depths
        // rather than a dialog: a right-click menu cannot ask a question. NOT foldersOnly:
        // right-clicking a FILE offers the tree of its enclosing folder — hiding the action
        // there read as "the tree action is gone" the first time it was tried on a file.
        ChuteAction(id: "tree-2",
                    title: "2 Levels",
                    detail: "The folder here (or around your selection) and one level inside it.",
                    scope: .folder, parentTitle: "Copy Folder Tree",
                    symbol: "folder.fill",
                    template: ["tree", "{dir}", "--depth", "2"],
                    doneMessage: "Folder tree copied."),
        ChuteAction(id: "tree-4",
                    title: "4 Levels",
                    detail: "Deep enough for most projects.",
                    scope: .folder, parentTitle: "Copy Folder Tree",
                    symbol: "folder.fill",
                    template: ["tree", "{dir}", "--depth", "4"],
                    doneMessage: "Folder tree copied."),
        ChuteAction(id: "tree-all",
                    title: "Everything",
                    detail: "The entire tree, with build and dependency folders left out.",
                    scope: .folder, parentTitle: "Copy Folder Tree",
                    symbol: "folder.fill",
                    template: ["tree", "{dir}", "--depth", "99"],
                    doneMessage: "Folder tree copied."),

        // The bug-report loop: screenshot → save here → type a better name → paste the path into
        // the issue you are writing. Saving the image was never the hard part; getting its path
        // out of Finder and into a prompt was.
        ChuteAction(id: "paste-image",
                    title: "Paste Image from Clipboard",
                    detail: "Saves the clipboard image here as a PNG and copies its full path.",
                    scope: .folder,
                    symbol: "photo.fill",
                    template: ["paste-image", "--dir", "{dir}"],
                    doneMessage: "Image saved, path copied."),

        ChuteAction(id: "new-markdown",
                    title: "New Markdown File",
                    detail: "An empty Untitled.md in this folder, with its name ready to type over.",
                    scope: .folder,
                    symbol: "square.and.pencil",
                    template: ["new", "--blank", "--rename", "--dir", "{dir}"],
                    doneMessage: "Markdown file created."),

        ChuteAction(id: "new-markdown-clipboard",
                    title: "New Markdown File from Clipboard",
                    detail: "The clipboard saved here, named after its first line, ready to rename.",
                    scope: .folder,
                    symbol: "doc.on.clipboard.fill",
                    template: ["new", "--naming", "underscore", "--ext", "md", "--rename", "--dir", "{dir}"],
                    doneMessage: "Markdown file created."),

        // JTBD #7, 9.9 min/day. Never overwrites an existing rules file (NFR-08), so it needs no
        // confirmation — the worst case is "kept existing CLAUDE.md".
        ChuteAction(id: "seed-rules",
                    title: "Add Agent Rules",
                    detail: "CLAUDE.md, .cursorrules and SCRATCHPAD.md here, without touching any that exist.",
                    scope: .folder,
                    symbol: "doc.badge.gearshape.fill",
                    template: ["seed", "{dir}"],
                    doneMessage: "Agent rules added."),

        // JTBD #6, 7.3 min/day. Creates a NEW folder beside this one and launches the agent there,
        // so an agent told to go wild does it somewhere that is not your repo. Additive: nothing
        // existing is touched, so no confirmation.
        ChuteAction(id: "sandbox-here",
                    title: "New Clean Room for an Agent",
                    detail: "A fresh folder here with git and rules ready, and the agent already running in it.",
                    scope: .folder,
                    symbol: "shippingbox.and.arrow.backward.fill",
                    template: ["sandbox", "--dir", "{dir}"],
                    doneMessage: "Clean room ready."),

        // JTBD #13, 6.6 min/day. Moves to the Trash, never `rm` — but it still removes files from
        // where the user put them, so it shows the list first.
        ChuteAction(id: "clean-junk",
                    title: "Move Junk to Trash",
                    detail: "The scratch files an agent left behind, moved to the Trash — after you see the list.",
                    scope: .folder,
                    symbol: "trash.fill",
                    template: ["clean", "{dir}"],
                    doneMessage: "Junk moved to Trash.",
                    confirmButton: "Move to Trash"),

        ChuteAction(id: "terminal",
                    title: "Open in Terminal",
                    detail: "A terminal window already sitting in this folder.",
                    scope: .folder,
                    symbol: "terminal.fill",
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
