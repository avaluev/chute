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

    /// What the action DOES to your disk — and therefore what colour it is drawn in.
    ///
    /// Colour carries meaning here, never identity. Identity is the icon and the word beside it,
    /// which is why no two drawn rows share a symbol. Colour answers the only question worth
    /// answering before you let go of the mouse: is this safe?
    ///
    /// It used to be one colour per SF Symbol, in a table in `ChuteFinderSync`, and four of the
    /// symbols were simply missing from it — so they all fell through to blue, including
    /// `trash.fill`. "Move Junk to Trash" drawn the same colour as "Copy Full Paths" is the one
    /// miss that actually costs a user something. Keying on this instead makes the mapping total:
    /// every action declares a kind, so no action can fall through to a default.
    public enum Kind: String, Sendable {
        case copy         // reads, and writes only to the clipboard
        case create       // makes something new, never touches what is there
        case setup        // prepares a folder for an agent, additively
        case destructive  // changes or removes files that already exist — always asks first
        case open         // leaves Finder for another app
    }

    public let id: String
    public let title: String
    /// Safety class, and the colour that follows from it. `isDestructive` and `kind ==
    /// .destructive` must always agree; `FinderActionsSuite` fails the build if they drift.
    public let kind: Kind
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

    public init(id: String, title: String, detail: String, scope: Scope, kind: Kind,
                foldersOnly: Bool = false, parentTitle: String? = nil,
                symbol: String, template: [String], doneMessage: String,
                confirmButton: String? = nil) {
        self.id = id; self.title = title; self.detail = detail; self.scope = scope
        self.kind = kind
        self.foldersOnly = foldersOnly; self.parentTitle = parentTitle
        self.symbol = symbol
        self.template = template; self.doneMessage = doneMessage
        self.confirmButton = confirmButton
    }

    /// True for anything that writes or deletes. Reads as a question at the call site.
    public var isDestructive: Bool { confirmButton != nil }

    /// The row as Finder draws it, for a known selection.
    public func title(count: Int) -> String {
        ellipsised(title.replacingOccurrences(of: "{n}", with: "\(count)"))
    }

    /// The title with the count dropped — for surfaces that draw the menu before they know the
    /// selection, and for notification subtitles. NO ellipsis: "Move Junk to Trash…" as the
    /// subtitle of a banner that says the junk is already in the Trash reads as still in progress.
    public var plainTitle: String { title.replacingOccurrences(of: " ({n})", with: "") }

    /// The row as Finder draws it when the selection count is not yet known. Apple's rule, and
    /// the reason this is not just `plainTitle`: an item that opens a dialog before it acts ends
    /// in an ellipsis, so a user can tell "does it now" from "asks first" without clicking to
    /// find out. Both destructive actions preview before they write; both must say so.
    public var menuTitle: String { ellipsised(plainTitle) }

    private func ellipsised(_ text: String) -> String { isDestructive ? text + "…" : text }
}

public enum ChuteActions {
    public static let all: [ChuteAction] = [
        ChuteAction(id: "copy-paths",
                    title: "Copy Full Paths ({n})",
                    detail: "Every selected file and folder, as full paths, on the clipboard.",
                    scope: .selection, kind: .copy,
                    symbol: "list.clipboard.fill",
                    template: ["paths", "{files}"],
                    doneMessage: "Full paths copied."),

        // THE WEDGE. Eight files and everything in them, as one blob with a token count, in one
        // click. It was CLI-only until now, which meant the largest saving in the JTBD ledger was
        // invisible to anyone who never opened a terminal — and unfilmable for the demo that is
        // supposed to carry it. XML only: the format is the default everywhere else, and a menu
        // that asks "which format?" before the most-used action taxes every use to serve a few.
        // `chute bundle --format md` still exists for the people who want it.
        // NAME. "Copy Files with Contents" was the one row that could be read as Finder's own
        // Copy — "with contents" is what an ordinary file copy already does. It is not a copy of
        // the files, it is a copy of what is IN them, formatted for an agent and counted in
        // tokens. "as Context" says that in two words, and it is the product's own vocabulary:
        // the site sells "drop context into your agent", so the menu should use the same noun.
        ChuteAction(id: "bundle-xml",
                    title: "Copy Files as Context ({n})",
                    detail: "Everything inside the selected files, as one block with a token count, ready to paste into an agent.",
                    scope: .selection, kind: .copy,
                    symbol: "shippingbox.fill",
                    template: ["bundle", "{files}"],
                    doneMessage: "Files and contents copied."),

        // A folder's whole shape, for handing an agent context it can navigate. Three depths
        // rather than a dialog: a right-click menu cannot ask a question. NOT foldersOnly:
        // right-clicking a FILE offers the tree of its enclosing folder — hiding the action
        // there read as "the tree action is gone" the first time it was tried on a file.
        ChuteAction(id: "tree-2",
                    title: "2 Levels",
                    detail: "The folder here (or around your selection) and one level inside it.",
                    scope: .folder, kind: .copy, parentTitle: "Copy Folder Tree",
                    symbol: "folder.fill",
                    template: ["tree", "{dir}", "--depth", "2"],
                    doneMessage: "Folder tree copied."),

        ChuteAction(id: "tree-4",
                    title: "4 Levels",
                    detail: "Deep enough for most projects.",
                    scope: .folder, kind: .copy, parentTitle: "Copy Folder Tree",
                    symbol: "folder.fill",
                    template: ["tree", "{dir}", "--depth", "4"],
                    doneMessage: "Folder tree copied."),

        ChuteAction(id: "tree-all",
                    title: "All Levels",
                    detail: "The entire tree, with build and dependency folders left out.",
                    scope: .folder, kind: .copy, parentTitle: "Copy Folder Tree",
                    symbol: "folder.fill",
                    template: ["tree", "{dir}", "--depth", "99"],
                    doneMessage: "Folder tree copied."),

        // The other direction, and the second-largest saving in the ledger (JTBD #9, 28.5 min/day).
        // It was CLI-only, which meant the buyer never saw the half of the loop that gets the
        // agent's answer back onto disk. Destructive, so it previews first — see `confirmButton`.
        // NAME. "Write Clipboard Files Here" named a thing that does not exist — there is no such
        // object as a "clipboard file". The clipboard holds an agent's answer; this saves the
        // files inside it. `menuTitle` appends the ellipsis, because it previews first.
        ChuteAction(id: "unpack-here",
                    title: "Save Clipboard as Files",
                    detail: "The files in a copied answer, written into this folder — after you see the list.",
                    scope: .folder, kind: .destructive,
                    symbol: "arrow.down.doc.fill",
                    template: ["unpack", "--dir", "{dir}"],
                    doneMessage: "Files written.",
                    confirmButton: "Write Files"),

        ChuteAction(id: "new-markdown",
                    title: "Empty Markdown File",
                    detail: "An empty Untitled.md in this folder, with its name ready to type over.",
                    scope: .folder, kind: .create, parentTitle: "New File",
                    symbol: "square.and.pencil",
                    template: ["new", "--blank", "--rename", "--dir", "{dir}"],
                    doneMessage: "Markdown file created."),

        ChuteAction(id: "new-markdown-clipboard",
                    title: "Markdown File from Clipboard",
                    detail: "The clipboard saved here, named after its first line, ready to rename.",
                    scope: .folder, kind: .create, parentTitle: "New File",
                    symbol: "doc.on.clipboard.fill",
                    template: ["new", "--naming", "underscore", "--ext", "md", "--rename", "--dir", "{dir}"],
                    doneMessage: "Markdown file created."),

        // The bug-report loop: screenshot → save here → type a better name → paste the path into
        // the issue you are writing. Saving the image was never the hard part; getting its path
        // out of Finder and into a prompt was.
        ChuteAction(id: "paste-image",
                    title: "Image from Clipboard",
                    detail: "Saves the clipboard image here as a PNG and copies its full path.",
                    scope: .folder, kind: .create, parentTitle: "New File",
                    symbol: "photo.fill",
                    template: ["paste-image", "--dir", "{dir}"],
                    doneMessage: "Image saved, path copied."),

        // JTBD #7, 9.9 min/day. Never overwrites an existing rules file (NFR-08), so it needs no
        // confirmation — the worst case is "kept existing CLAUDE.md".
        ChuteAction(id: "seed-rules",
                    title: "Add Agent Rules",
                    detail: "CLAUDE.md, .cursorrules and SCRATCHPAD.md here, without touching any that exist.",
                    scope: .folder, kind: .setup, parentTitle: "Set Up for an Agent",
                    symbol: "doc.badge.gearshape.fill",
                    template: ["seed", "{dir}"],
                    doneMessage: "Agent rules added."),

        // JTBD #6, 7.3 min/day. Creates a NEW folder beside this one and launches the agent there,
        // so an agent told to go wild does it somewhere that is not your repo. Additive: nothing
        // existing is touched, so no confirmation.
        // NAME. "Clean Room" appears nowhere else in this product, its docs or its CLI — a term
        // invented for one menu row is a term nobody can look up. "Scratch" is already the word
        // used for the files `clean` removes, and the row sits under "Set Up for an Agent", so it
        // does not have to repeat "for an Agent" either.
        //
        // ICON. `shippingbox.and.arrow.backward.fill` was a near-twin of the bundle action's
        // `shippingbox.fill` at 18pt — two boxes in one menu. This makes a folder,
        // so it is drawn as one.
        ChuteAction(id: "sandbox-here",
                    title: "New Scratch Folder",
                    detail: "A fresh folder here with git and rules ready, and the agent already running in it.",
                    scope: .folder, kind: .setup, parentTitle: "Set Up for an Agent",
                    symbol: "folder.badge.plus",
                    template: ["sandbox", "--dir", "{dir}"],
                    doneMessage: "Clean room ready."),

        // JTBD #12, T1: 3.3 min/day on the clock and ~20 min/day risk-adjusted — the largest
        // number in the ledger that had no Finder surface at all. It is also the job that makes
        // every OTHER agent action psychologically affordable: the reason people hesitate before
        // letting an agent loose is that they cannot cheaply undo it.
        //
        // NOT destructive, despite being a git command. `checkpoint` uses `git add -A` against a
        // PRIVATE index and `commit-tree` (NFR-08), so it never touches the worktree, the index
        // or HEAD — it can only add a branch. Nothing to preview, nothing to confirm, no ellipsis.
        //
        // Third child rather than a ninth row: eight rows added to Finder's own menu is the
        // budget, and this sits with the other two things you do to a folder before an agent
        // runs. Declared LAST so the submenu holder keeps `seed-rules`' icon and the drawn menu
        // is unchanged.
        ChuteAction(id: "checkpoint-here",
                    title: "Save a Checkpoint",
                    detail: "A restore point for this folder before an agent runs — your own files are never touched.",
                    scope: .folder, kind: .setup, parentTitle: "Set Up for an Agent",
                    symbol: "clock.arrow.circlepath",
                    template: ["checkpoint", "{dir}"],
                    doneMessage: "Checkpoint saved."),

        // JTBD #13, 6.6 min/day. Moves to the Trash, never `rm` — but it still removes files from
        // where the user put them, so it shows the list first.
        ChuteAction(id: "clean-junk",
                    title: "Move Junk to Trash",
                    detail: "The scratch files an agent left behind, moved to the Trash — after you see the list.",
                    scope: .folder, kind: .destructive,
                    symbol: "trash.fill",
                    template: ["clean", "{dir}"],
                    doneMessage: "Junk moved to Trash.",
                    confirmButton: "Move to Trash"),

        ChuteAction(id: "terminal",
                    title: "Open in Terminal",
                    detail: "A terminal window already sitting in this folder.",
                    scope: .folder, kind: .open,
                    symbol: "terminal.fill",
                    template: ["open", "{dir}"],
                    doneMessage: "Terminal opened."),
    ]

    public static func find(_ id: String) -> ChuteAction? { all.first { $0.id == id } }

    /// One row of Finder's context menu as it is actually drawn: either an action, or a submenu
    /// holder standing in for its children.
    public struct Row: Sendable, Equatable {
        public let title: String
        /// The icon on that row. For a submenu it is the FIRST declared child's — which is what
        /// ChuteFinderSync does, because the holder is created by whichever child arrives first.
        public let symbol: String
        public let children: [String]   // action ids, empty for a plain row
    }

    /// What the user sees. Fourteen actions, but a context menu is judged on how many rows it
    /// adds to Finder's own — and Finder's own is already long. This is the one implementation;
    /// the test and `chute finder-actions --menu` both read it rather than keeping a second copy,
    /// which is how the menu drifted the first time.
    public static func rows(hasSelection: Bool = true, targetIsFolder: Bool = true) -> [Row] {
        var out: [Row] = []
        var index: [String: Int] = [:]
        for action in visible(hasSelection: hasSelection, targetIsFolder: targetIsFolder) {
            guard let parent = action.parentTitle else {
                out.append(Row(title: action.menuTitle, symbol: action.symbol, children: []))
                continue
            }
            if let i = index[parent] {
                out[i] = Row(title: out[i].title, symbol: out[i].symbol,
                             children: out[i].children + [action.id])
            } else {
                index[parent] = out.count
                out.append(Row(title: parent, symbol: action.symbol, children: [action.id]))
            }
        }
        return out
    }

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

    /// Every failure message starts with this, and the HUD reads it to decide whether to draw
    /// the result green or red. It was a bare string in two files: the panel drew a GREEN dot
    /// beside "Failed — not a directory", so the colour said one thing and the words said the
    /// opposite. Colour is what gets read first.
    public static let failurePrefix = "Failed — "

    /// Turn what the CLI said into one line a human can act on. The CLI writes progress to stderr
    /// with a `→ ` prefix and failures with a `chute: ` prefix; neither means anything in a banner.
    public static func message(stderr: String, exitCode: Int32, fallback: String) -> String {
        let line = stderr
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last(where: { !$0.isEmpty })
        guard var text = line, !text.isEmpty else {
            return exitCode == 0 ? fallback : failurePrefix + "the command said nothing."
        }
        for prefix in ["→ ", "chute: "] where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }
        if exitCode != 0 { return failurePrefix + text }
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
