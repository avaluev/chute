import Foundation
import ChuteCore

func finderTargetSuite() {
    T.suite("FinderTarget") {
        let fm = FileManager.default
        let base = (NSTemporaryDirectory() + "chute-target-\(UUID().uuidString)" as NSString)
            .resolvingSymlinksInPath
        defer { try? fm.removeItem(atPath: base) }
        let proj = base + "/39.IMDB_Parsing"
        try? fm.createDirectory(atPath: proj + "/__pycache__", withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: proj + "/data", withIntermediateDirectories: true)
        for f in ["api.py", "config.py", "README.md"] {
            fm.createFile(atPath: proj + "/" + f, contents: Data("x".utf8))
        }
        fm.createFile(atPath: proj + "/__pycache__/api.cpython-310.pyc", contents: Data("x".utf8))

        // THE REPORTED BUG, 2026-09-02. Select everything in a project and ask for the folder
        // tree: the old rule took `selectedItemURLs().first`, which in a Python project is
        // `__pycache__`, so the answer was thirteen .pyc files instead of the project.
        let everything = ["__pycache__", "api.py", "config.py", "data", "README.md"].map { proj + "/" + $0 }
        let multi = FinderTarget.folder(selection: everything, targeted: proj)
        T.eq(multi?.path, proj, "a multi-selection resolves to the folder that contains it")
        T.eq(multi?.isFolder, true, "and that container is a folder")

        // Order must not matter. Finder hands the selection back in ITS sort order, which is why
        // the bug looked like "it always picks __pycache__" — that is simply what sorts first.
        T.eq(FinderTarget.folder(selection: everything.reversed(), targeted: proj)?.path, proj,
             "the answer does not depend on which item Finder listed first")

        // Unchanged behaviour, and the reason the old rule looked right: one folder selected is
        // unambiguous and must still resolve to itself, not to its parent.
        T.eq(FinderTarget.folder(selection: [proj + "/data"], targeted: proj)?.path, proj + "/data",
             "one selected folder is still its own tree")
        // One file selected offers the tree of the folder it sits in.
        let oneFile = FinderTarget.folder(selection: [proj + "/api.py"], targeted: proj)
        T.eq(oneFile?.path, proj, "one selected file resolves to its enclosing folder")
        T.eq(oneFile?.isFolder, false, "and reports that what was clicked was not a folder")
        // Right-clicking the background selects nothing.
        T.eq(FinderTarget.folder(selection: [], targeted: proj)?.path, proj,
             "an empty selection uses the folder that was right-clicked")
        T.eq(FinderTarget.folder(selection: [], targeted: nil)?.path, nil,
             "nothing selected and nothing targeted is nothing to act on")
        // A path Finder named but that has since gone is not a target.
        T.eq(FinderTarget.folder(selection: [proj + "/gone.py"], targeted: proj)?.path, nil,
             "a vanished selection is refused rather than guessed at")
        // Two items whose only shared ancestor is "/" must not turn the whole disk into a tree.
        T.eq(FinderTarget.folder(selection: ["/Users/a/x.py", "/Volumes/b/y.py"], targeted: nil)?.path, nil,
             "a selection spanning the filesystem root is refused, not rendered")
    }
}
