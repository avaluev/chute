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

        // THE MENU AS DRAWN. Thirteen actions, but the number that matters is how many rows this
        // adds to a Finder context menu that is already long. Seven was arrived at by grouping,
        // not by dropping anything: three ways to copy context out, one to bring an answer back,
        // then create / set up / clean up. The terminal row was removed because macOS ships the
        // same action natively, four rows below. `chute open` stays in the CLI. Change this number
        // on purpose or not at all.
        let rows = ChuteActions.rows()
        T.eq(rows.count, 6, "the right-click adds six rows to Finder's menu")
        T.eq(rows.map(\.title), ["Copy Full Paths", "Copy Files as Context", "Copy Folder Tree",
                                 "Save Clipboard as Files…", "New File", "Set Up for an Agent"],
             "and they read in that order — context out, answer in, make, set up")
        T.eq(Set(rows.map(\.symbol)).count, rows.count,
             "no two DRAWN rows share an icon, submenu holders included")
        // ChuteFinderSync builds a submenu's holder from whichever child reaches it first, so the
        // holder's icon is the first DECLARED child's. Stated here because it is the reason the
        // tree depths were made to share one symbol, and the reason they no longer have to.
        for row in rows where !row.children.isEmpty {
            T.eq(row.symbol, ChuteActions.find(row.children[0])!.symbol,
                 "the '\(row.title)' submenu takes its icon from its first child")
        }
        // ONE JOB, ONE NAME — the invariant, not the instance.
        //
        // `sandbox-here` titled itself "New Scratch Folder", carried a comment explaining why
        // "Clean Room" was rejected as a term nobody can look up, and then toasted "Clean room
        // ready." six lines below it. The row and its confirmation named the same job two ways,
        // in one struct, past a comment arguing against exactly that.
        //
        // The rule that catches it, and only it: a confirmation may not introduce a word that
        // appears in NO title and NO detail anywhere in the table. Checked against the real data
        // before it was written — every other doneMessage passes, and the two tree-depth rows
        // ("2 Levels", "4 Levels") legitimately borrow "folder tree" from their parent row, which
        // is why the vocabulary is the whole table rather than each action's own two fields.
        //
        // A confirmation is allowed its own verbs: "copied", "saved", "written" are what a toast
        // says, not names of jobs, and no menu row is titled with them.
        let confirmationVerbs: Set<String> = ["copied", "saved", "added", "created", "opened",
                                              "written", "moved", "ready", "done"]
        func significantWords(_ s: String) -> [String] {
            s.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
                .filter { $0.count > 2 && !confirmationVerbs.contains($0) }
        }
        let vocabulary = Set(ChuteActions.all.flatMap { significantWords($0.title + " " + $0.detail) })
        // Prefix-matched at four characters so "files"/"file" and "rules"/"rule" are one word.
        func inVocabulary(_ w: String) -> Bool {
            vocabulary.contains { v in
                let n = min(4, min(v.count, w.count))
                return v.prefix(n) == w.prefix(n)
            }
        }
        for action in ChuteActions.all {
            for word in significantWords(action.doneMessage) where !inVocabulary(word) {
                T.ok(false, "'\(action.id)' confirms with \"\(word)\", a word no row in this "
                          + "menu uses — one job, one name")
            }
        }
        T.ok(true, "every confirmation uses the words its own menu already uses")

        // With nothing selected the selection-scoped rows drop out; nothing may be left orphaned.
        T.ok(ChuteActions.rows(hasSelection: false, targetIsFolder: true).count < rows.count,
             "an empty selection draws fewer rows, not the same ones greyed out")

        // COLOUR IS A SAFETY SIGNAL, so it may never disagree with the confirmation. `kind` is
        // what ChuteFinderSync draws the icon in; `confirmButton` is what makes the app ask before
        // writing. An action that asks but is drawn green, or one drawn red that writes without
        // asking, is worse than no colour at all — it is a promise the code does not keep.
        for a in ChuteActions.all {
            T.eq(a.isDestructive, a.kind == .destructive,
                 "'\(a.id)' is coloured for what it actually does to your disk")
        }
        // The tint switch is exhaustive over Kind, so this only has to prove no action was left
        // in a catch-all bucket that means nothing. `.open` is no longer in the Finder menu
        // (terminal row removed; `chute open` stays in the CLI).
        T.ok(ChuteActions.all.contains { $0.kind == .copy } && ChuteActions.all.contains { $0.kind == .create }
             && ChuteActions.all.contains { $0.kind == .setup } && ChuteActions.all.contains { $0.kind == .destructive },
             "every safety class actually represented in the menu is used — a class with no members is a class nobody learns")

        // THE ELLIPSIS, which is Apple's rule and not decoration: an item that opens a dialog
        // before it acts ends in one, so "does it now" and "asks first" are distinguishable
        // without clicking to find out.
        for a in ChuteActions.all {
            T.eq(a.menuTitle.hasSuffix("…"), a.isDestructive,
                 "'\(a.id)' ends in an ellipsis if and only if it asks first")
            T.ok(!a.plainTitle.hasSuffix("…"),
                 "'\(a.id)' keeps the ellipsis out of the notification subtitle")
        }

        // DESTRUCTIVE ACTIONS. A right-click that silently writes into a repo is the one thing
        // that would destroy the trust everything else here is sold on. Both of these preview by
        // default in the CLI (NFR-05); the guarantee only survives the trip through the menu if
        // the template stays in its harmless form and the app supplies --force after asking.
        let destructive = ChuteActions.all.filter(\.isDestructive)
        // One, not two: clean-junk was removed 2026-08-31 (git status already lists untracked
        // files, and a developer trusts it over a menu's list). The rule it proves is unchanged.
        T.eq(Set(destructive.map(\.id)), ["unpack-here"],
             "every action that changes files asks first")
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

        // THE PAID SURFACE. These three moved out of the CLI so the app demonstrates the three
        // highest-value jobs in the ledger instead of only the ones a terminal user already has.
        // If one is dropped, the landing page's arithmetic stops matching the product.
        // sandbox-here was removed 2026-08-31: ICP is Claude Code / Cursor users whose agents ship
        // their own sandboxing. The CLI keeps `chute sandbox`.
        for id in ["unpack-here", "seed-rules"] {
            guard let a = ChuteActions.find(id) else { T.ok(false, "'\(id)' is in the menu"); continue }
            T.eq(a.scope, .folder, "'\(id)' acts on the folder in view")
        }
        // JTBD #12 reached the menu as a THIRD CHILD, not a ninth row — the eight-row budget is
        // the whole reason the other six ledger gaps are still gaps. If this ever becomes a
        // top-level row, that decision was made on purpose or the budget has quietly gone.
        let agentSetup = ChuteActions.all.filter { $0.parentTitle == "Set Up for an Agent" }
        T.eq(agentSetup.map(\.id), ["seed-rules", "checkpoint-here"],
             "setting up for an agent is rules and a way back")
        T.ok(ChuteActions.find("checkpoint-here")?.isDestructive == false,
             "a checkpoint can only add a branch, so it never asks")

        // WHAT STAYS ONE CLICK. Not everything can: eight rows is already a lot to add to
        // Finder's own menu. The rule is the ledger — anything worth more than ~10 min/day is
        // reached in one click, everything else may sit one level down. Today that is bundle
        // (41.1) and unpack (28.5); seed (9.9) is under "Set Up for an Agent" with checkpoint (3.3).
        // A submenu is not a demotion, but burying the two biggest savings would be.
        for id in ["bundle-xml", "unpack-here"] {
            T.ok(ChuteActions.find(id)?.parentTitle == nil,
                 "'\(id)' is one click — it is one of the two largest savings in the ledger")
        }
        T.eq(ChuteActions.argv(ChuteActions.find("unpack-here")!, dir: "/tmp/p", files: ["/a.ts"]),
             ["unpack", "--dir", "/tmp/p"], "the selection never reaches a folder action")

        // Titles carry the count so you see what you are about to act on.
        T.eq(paths.title(count: 3), "Copy Full Paths (3)", "the count is substituted")
        T.eq(paths.plainTitle, "Copy Full Paths", "and dropped where it is unknown")

        // THE HUD READS THIS PREFIX to decide green or red. It was a bare literal in two files
        // and the panel drew every result green, so "Failed — not a directory" arrived with a
        // green dot beside it. Pin the contract, or the colour drifts away from the words again.
        for (err, code) in [("chute: not a directory: /x", Int32(1)), ("", Int32(2)), ("\n\n", Int32(3))] {
            T.ok(ChuteActions.message(stderr: err, exitCode: code, fallback: "Done.")
                    .hasPrefix(ChuteActions.failurePrefix),
                 "a failure (exit \(code)) is recognisable as one from its first characters")
        }
        T.no(ChuteActions.message(stderr: "→ copied", exitCode: 0, fallback: "Done.")
                .hasPrefix(ChuteActions.failurePrefix), "and a success never is")

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
