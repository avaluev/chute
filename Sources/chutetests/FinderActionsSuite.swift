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
        // THE WEDGE, guarded. It is the largest saving in the ledger and the hero of the demo,
        // so it must stay ONE click (no submenu) and must keep passing every selected file.
        let bundle = ChuteActions.find("bundle-xml")!
        T.ok(bundle.parentTitle == nil, "the bundle action is one click, never behind a submenu")
        T.eq(bundle.scope, .selection, "it acts on what you selected, not the folder in view")
        T.eq(ChuteActions.argv(bundle, dir: "/tmp/p", files: ["/a.ts", "/b.ts"]),
             ["bundle", "/a.ts", "/b.ts"], "every selected file reaches the bundler")
        let tree = ChuteActions.find("tree-4")!
        T.eq(ChuteActions.argv(tree, dir: "/tmp/p", files: ["/ignored"]),
             ["tree", "/tmp/p", "--depth", "4"], "a folder action ignores the selection")

        // Visibility: never offer what cannot work here.
        T.ok(ChuteActions.visible(hasSelection: false, targetIsFolder: true)
                .allSatisfy { $0.scope == .folder },
             "with nothing selected, only folder actions are offered")
        // The tree is offered on a FILE too — it copies the ENCLOSING folder's tree. Hiding it
        // there read as "the tree action disappeared" the first time it was tried on a file.
        T.ok(ChuteActions.visible(hasSelection: true, targetIsFolder: false).contains { $0.id == "tree-2" },
             "the folder tree is offered when a file is selected")
        T.ok(ChuteActions.visible(hasSelection: true, targetIsFolder: true).contains { $0.id == "tree-2" },
             "and when a folder is")
        T.eq(ChuteActions.visible(hasSelection: true, targetIsFolder: true).map(\.id),
             ChuteActions.all.map(\.id), "order is the declared order, every time")

        // The tree depths live together in one submenu rather than as three loose items.
        let depths = ChuteActions.all.filter { $0.parentTitle == "Copy Folder Tree" }
        T.eq(depths.count, 3, "three depths to choose from")
        T.ok(depths.allSatisfy { !$0.foldersOnly }, "none folders-only — a file click trees its folder")

        // The actions sit inline in Finder's own context menu; the icons ARE the branding, so a
        // missing one is a naked row in the middle of a labelled group.
        T.ok(ChuteActions.all.allSatisfy { !$0.symbol.isEmpty }, "every action carries an SF Symbol")
        T.eq(Set(depths.map(\.symbol)).count, 1,
             "siblings in one submenu share a symbol, so the submenu's own icon is deterministic")
        let inline = ChuteActions.all.filter { $0.parentTitle == nil }
        T.eq(Set(inline.map(\.symbol)).count, inline.count,
             "no two inline rows share an icon — an icon that cannot distinguish is decoration")

        // DESTRUCTIVE ACTIONS. A right-click that silently writes into a repo is the one thing
        // that would destroy the trust everything else here is sold on. Both of these preview by
        // default in the CLI (NFR-05); the guarantee only survives the trip through the menu if
        // the template stays in its harmless form and the app supplies --force after asking.
        let destructive = ChuteActions.all.filter(\.isDestructive)
        T.eq(Set(destructive.map(\.id)), ["unpack-here", "clean-junk"],
             "exactly the two actions that change files ask first")
        for a in destructive {
            T.ok(!(a.confirmButton ?? "").isEmpty, "'\(a.id)' names the button that does the thing")
            T.ok(!a.template.contains("--force"),
                 "'\(a.id)' does not carry --force — the first run must be the preview")
        }
        // And the inverse, so a future action cannot quietly become destructive: anything whose
        // command has a --force mode must declare a confirmation.
        for a in ChuteActions.all where ["unpack", "clean"].contains(a.template.first ?? "") {
            T.ok(a.isDestructive, "'\(a.id)' runs a --force-capable command, so it must confirm")
        }

        // THE PAID SURFACE. These four moved out of the CLI so the app demonstrates the four
        // highest-value jobs in the ledger instead of only the ones a terminal user already has.
        // If one is dropped, the landing page's arithmetic stops matching the product.
        for id in ["unpack-here", "seed-rules", "sandbox-here", "clean-junk"] {
            guard let a = ChuteActions.find(id) else { T.ok(false, "'\(id)' is in the menu"); continue }
            T.eq(a.scope, .folder, "'\(id)' acts on the folder in view")
            T.ok(a.parentTitle == nil, "'\(id)' is one click")
        }
        T.eq(ChuteActions.argv(ChuteActions.find("unpack-here")!, dir: "/tmp/p", files: ["/a.ts"]),
             ["unpack", "--dir", "/tmp/p"], "the selection never reaches a folder action")

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
