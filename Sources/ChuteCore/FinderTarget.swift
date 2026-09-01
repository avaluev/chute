import Foundation

/// WHICH FOLDER a folder-scoped Finder action applies to.
///
/// Lived inside `ChuteFinder/ChuteFinderSync.swift` as one line until 2026-09-02, in a target no
/// test can import — and that line was wrong for the commonest way anyone uses the menu:
///
///     controller.selectedItemURLs()?.first ?? controller.targetedURL()
///
/// Select every item in a project and choose **Copy Folder Tree ▸ All Levels**, and you got the
/// tree of whichever item Finder happened to sort first. For a Python project that is
/// `__pycache__`, so the answer was a list of `.pyc` files. Reported with a screenshot: 34 items
/// selected, thirteen `.pyc` files returned.
///
/// The rule, and the reasoning for each line:
///
///   · **One item selected** — that folder, or a file's enclosing folder. Unchanged: "show me the
///     shape of this" is unambiguous, and right-clicking a file has always offered the tree of the
///     folder it sits in rather than hiding the action.
///   · **Several items selected** — the folder that CONTAINS them. There is no such thing as the
///     tree of thirty-four things, and the action is called *Copy Folder Tree*: its subject is a
///     folder. The one folder every selected item is inside is the only honest answer, and
///     `PathFormat.commonAncestor` already computes it.
///   · **Nothing selected** — the folder whose background was right-clicked.
///
/// Deliberately NOT pruned to the selection. Selecting three of thirty items still returns all
/// thirty, because the action's subject is the folder, not the selection — and a tree that
/// silently omitted the sibling directories would be a worse lie than one that shows extra.
public enum FinderTarget {
    public static func folder(selection: [String],
                              targeted: String?,
                              isDirectory: (String) -> Bool = FileScan.isDirectory,
                              exists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) })
        -> (path: String, isFolder: Bool)? {

        if selection.count > 1 {
            // Every item in one Finder window shares a parent, so this IS the container. It is
            // computed rather than assumed so a selection spanning two places still resolves to
            // something that contains all of it instead of to an arbitrary member.
            let ancestor = PathFormat.commonAncestor(selection)
            guard !ancestor.isEmpty, ancestor != "/", exists(ancestor) else { return nil }
            return (ancestor, true)
        }
        guard let path = selection.first ?? targeted, exists(path) else { return nil }
        return isDirectory(path)
            ? (path, true)
            : ((path as NSString).deletingLastPathComponent, false)
    }
}
