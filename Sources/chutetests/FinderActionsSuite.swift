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
        T.eq(Set(ChuteActions.all.map(\.title)).count, ChuteActions.all.count, "titles are unique")

        // NAMING GUARD. These words all appeared in the first menu and none of them tell a reader
        // what the action does to their files.
        let jargon = ["yolo", "bundle", "unpack", "xml)", "redacted", "prompt for"]
        for a in ChuteActions.all {
            let lower = a.title.lowercased()
            for word in jargon {
                T.ok(!lower.contains(word), "title '\(a.title)' avoids jargon '\(word)'")
            }
        }
        // A title that promises a write must not run a dry run underneath it.
        let write = ChuteActions.find("clipboard-to-files")!
        T.ok(write.template.contains("--force"),
             "'\(write.title)' actually writes — a preview under a writing verb is a lie")

        // Placeholder expansion.
        let paths = ChuteActions.find("copy-paths")!
        T.eq(ChuteActions.argv(paths, dir: "/tmp/p", files: ["/a.ts", "/b.ts"]),
             ["paths", "/a.ts", "/b.ts"], "{files} expands in place, one argument per file")
        let snapshot = ChuteActions.find("snapshot")!
        T.eq(ChuteActions.argv(snapshot, dir: "/tmp/p", files: []),
             ["checkpoint", "/tmp/p"], "{dir} becomes the folder in view")
        let workspace = ChuteActions.find("workspace")!
        T.eq(ChuteActions.argv(workspace, dir: "/tmp/p", files: ["/ignored"]),
             ["sandbox", "--dir", "/tmp/p"], "a folder action ignores the selection")

        // Visibility: no action is ever offered where it is guaranteed to fail.
        let noSelection = ChuteActions.visible(hasSelection: false, inGitRepo: true)
        T.ok(noSelection.allSatisfy { $0.scope == .folder },
             "with nothing selected, only folder actions are offered")
        let noGit = ChuteActions.visible(hasSelection: true, inGitRepo: false)
        T.ok(noGit.allSatisfy { !$0.requiresGit },
             "outside a git repo, the git actions are hidden rather than offered and failing")
        T.eq(ChuteActions.visible(hasSelection: true, inGitRepo: true).count, ChuteActions.all.count,
             "with a selection inside a repo, everything is available")
        // Order is the declared order — the menu groups must not reshuffle between right-clicks.
        T.eq(ChuteActions.visible(hasSelection: true, inGitRepo: true).map(\.id),
             ChuteActions.all.map(\.id), "visible() preserves table order")

        // Titles carry the count so the user sees what they are about to act on.
        T.eq(paths.title(count: 3), "Copy Paths (3)", "the count is substituted")
        T.eq(paths.plainTitle, "Copy Paths", "and dropped where it is unknown")

        // git detection walks up, and says no outside a repo.
        let tmp = NSTemporaryDirectory() + "chute-git-\(UInt32.random(in: 0...99999))"
        let nested = (tmp as NSString).appendingPathComponent("a/b/c")
        try? FileManager.default.createDirectory(atPath: nested, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        T.ok(!ChuteActions.isInGitRepo(nested), "a plain folder is not a repo")
        try? FileManager.default.createDirectory(atPath: (tmp as NSString).appendingPathComponent(".git"),
                                                 withIntermediateDirectories: true)
        T.ok(ChuteActions.isInGitRepo(nested), "a folder three levels inside a repo IS a repo")
        T.ok(!ChuteActions.isInGitRepo("/"), "the root of the disk is not treated as a repo")

        // Notification text: the user reads this, so no CLI prefixes and no empty banners.
        T.eq(ChuteActions.message(stderr: "→ copied to clipboard · 2 path(s)", exitCode: 0,
                                  fallback: "Done."),
             "Copied to clipboard · 2 path(s)", "the arrow prefix is dropped and the line reads as prose")
        T.eq(ChuteActions.message(stderr: "chute: not a git repository: /x", exitCode: 1,
                                  fallback: "Done."),
             "Failed — not a git repository: /x", "a failure says so, without the CLI prefix")
        T.eq(ChuteActions.message(stderr: "", exitCode: 0, fallback: "Files written."),
             "Files written.", "a silent success still reports something")
        T.eq(ChuteActions.message(stderr: "\n\n", exitCode: 1, fallback: "Done."),
             "Failed — the command said nothing.", "a silent failure is never reported as success")
        T.eq(ChuteActions.message(stderr: "first line\n→ last line", exitCode: 0, fallback: "Done."),
             "Last line", "the summary is the LAST line, not the first")
    }
}
