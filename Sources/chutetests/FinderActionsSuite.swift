import Foundation
import ChuteCore

func finderActionsSuite() {
    T.suite("FinderActions") {
        // Every action must be usable: an id, a title, a command, and something to say when the
        // command is silent. A blank title is a menu item nobody can guess the effect of.
        for a in ChuteActions.all {
            T.ok(!a.id.isEmpty && !a.title.isEmpty && !a.detail.isEmpty && !a.template.isEmpty
                 && !a.doneMessage.isEmpty, "action '\(a.id)' is fully described")
            T.ok(a.detail.hasSuffix("."), "action '\(a.id)' detail reads as a sentence")
        }
        T.eq(Set(ChuteActions.all.map(\.id)).count, ChuteActions.all.count, "ids are unique")

        // THE BUG THIS SUITE EXISTS FOR. A FinderSync menu is drawn by Finder, and only plain
        // properties cross that boundary: `tag` survives, `representedObject` comes back nil.
        // Dispatch is therefore by index into `all`, so that index must be stable and findable.
        for (index, action) in ChuteActions.all.enumerated() {
            T.eq(ChuteActions.all.firstIndex(where: { $0.id == action.id }), index,
                 "action '\(action.id)' is addressable by its tag")
        }

        // NAMING GUARD — words that appeared in the first menu and told the reader nothing.
        let jargon = ["yolo", "bundle", "unpack", "xml", "redacted", "sandbox"]
        for a in ChuteActions.all {
            let lower = a.title.lowercased()
            for word in jargon { T.ok(!lower.contains(word), "title '\(a.title)' avoids '\(word)'") }
        }

        // Placeholder expansion.
        let paths = ChuteActions.find("copy-paths")!
        T.eq(ChuteActions.argv(paths, dir: "/tmp/p", files: ["/a.ts", "/b.ts"]),
             ["paths", "/a.ts", "/b.ts"], "{files} expands in place, one argument per file")
        let tree = ChuteActions.find("tree-4")!
        T.eq(ChuteActions.argv(tree, dir: "/tmp/p", files: ["/ignored"]),
             ["tree", "/tmp/p", "--depth", "4"], "a folder action ignores the selection")

        // Visibility: never offer what cannot work here.
        T.ok(ChuteActions.visible(hasSelection: false, targetIsFolder: true)
                .allSatisfy { $0.scope == .folder },
             "with nothing selected, only folder actions are offered")
        T.ok(ChuteActions.visible(hasSelection: true, targetIsFolder: false)
                .allSatisfy { !$0.foldersOnly },
             "a file tree is not offered for a file")
        T.ok(ChuteActions.visible(hasSelection: true, targetIsFolder: true).contains { $0.id == "tree-2" },
             "and it IS offered for a folder")
        T.eq(ChuteActions.visible(hasSelection: true, targetIsFolder: true).map(\.id),
             ChuteActions.all.map(\.id), "order is the declared order, every time")

        // The tree depths live together in one submenu rather than as three loose items.
        let depths = ChuteActions.all.filter { $0.parentTitle == "Copy Folder Tree" }
        T.eq(depths.count, 3, "three depths to choose from")
        T.ok(depths.allSatisfy { $0.foldersOnly }, "all of them folders-only")

        // The actions sit inline in Finder's own context menu; the icons ARE the branding, so a
        // missing one is a naked row in the middle of a labelled group.
        T.ok(ChuteActions.all.allSatisfy { !$0.symbol.isEmpty }, "every action carries an SF Symbol")
        T.eq(Set(depths.map(\.symbol)).count, 1,
             "siblings in one submenu share a symbol, so the submenu's own icon is deterministic")
        let inline = ChuteActions.all.filter { $0.parentTitle == nil }
        T.eq(Set(inline.map(\.symbol)).count, inline.count,
             "no two inline rows share an icon — an icon that cannot distinguish is decoration")

        // Titles carry the count so you see what you are about to act on.
        T.eq(paths.title(count: 3), "Copy Full Paths (3)", "the count is substituted")
        T.eq(paths.plainTitle, "Copy Full Paths", "and dropped where it is unknown")

        // Notification text: no CLI prefixes, no empty banners.
        T.eq(ChuteActions.message(stderr: "→ copied to clipboard · 2 path(s)", exitCode: 0,
                                  fallback: "Done."),
             "Copied to clipboard · 2 path(s)", "the arrow prefix goes, the line reads as prose")
        T.eq(ChuteActions.message(stderr: "chute: not a directory: /x", exitCode: 1, fallback: "Done."),
             "Failed — not a directory: /x", "a failure says so, without the CLI prefix")
        T.eq(ChuteActions.message(stderr: "", exitCode: 0, fallback: "Full paths copied."),
             "Full paths copied.", "a silent success still reports something")
        T.eq(ChuteActions.message(stderr: "\n\n", exitCode: 1, fallback: "Done."),
             "Failed — the command said nothing.", "a silent failure is never reported as success")
        T.eq(ChuteActions.message(stderr: "first line\n→ last line", exitCode: 0, fallback: "Done."),
             "Last line", "the summary is the LAST line, not the first")
    }
}
