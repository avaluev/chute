import Foundation
import ChuteCore

func treeRenderSuite() {
    T.suite("TreeRender") {
        let fm = FileManager.default
        let base = (NSTemporaryDirectory() + "chute-tree-\(UUID().uuidString)" as NSString)
            .resolvingSymlinksInPath
        defer { try? fm.removeItem(atPath: base) }
        let root = base + "/proj"
        try? fm.createDirectory(atPath: root + "/src/deep", withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: root + "/node_modules/x", withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: root + "/.github", withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: root + "/.hidden", withIntermediateDirectories: true)
        fm.createFile(atPath: root + "/README.md", contents: Data("x".utf8))
        fm.createFile(atPath: root + "/src/a.ts", contents: Data("x".utf8))
        fm.createFile(atPath: root + "/src/deep/b.ts", contents: Data("x".utf8))
        fm.createFile(atPath: root + "/node_modules/x/i.js", contents: Data("x".utf8))
        fm.createFile(atPath: root + "/.github/ci.yml", contents: Data("x".utf8))

        let out = TreeRender.render(root, depth: 99)
        T.ok(out.hasPrefix("proj/"), "the root names itself")
        T.ok(out.contains("README.md"), "files are listed")
        T.ok(out.contains("src/"), "a directory carries a trailing slash")
        T.ok(!out.contains("node_modules"), "build and dependency folders are left out")
        T.ok(out.contains(".github"), ".github is the one dotdir kept — CI is part of a repo's shape")
        T.ok(!out.contains(".hidden"), "other dot directories are not")
        T.ok(out.contains("b.ts"), "depth 99 reaches the bottom")
        T.ok(!TreeRender.render(root, depth: 1).contains("a.ts"), "depth 1 stops at the top level")

        // THE HANG, 2026-09-02. `links/real/loop -> ..` is an ordinary shape — node_modules/.bin,
        // a venv, a framework's Current link. FileScan.isDirectory FOLLOWS a symlink, so the
        // walker entered itself: depth 2 produced 11 lines, depth 4 gave 31, depth 8 gave 151,
        // and depth 99 — which is exactly what `Copy Folder Tree ▸ All Levels` runs — never
        // returned. Killed at 20 seconds with no output at all.
        let loops = base + "/loops"
        try? fm.createDirectory(atPath: loops + "/real", withIntermediateDirectories: true)
        fm.createFile(atPath: loops + "/real/target.txt", contents: Data("x".utf8))
        try? fm.createSymbolicLink(atPath: loops + "/real/loop", withDestinationPath: "..")
        try? fm.createSymbolicLink(atPath: loops + "/outside", withDestinationPath: "/etc")
        let looped = TreeRender.render(loops, depth: 99)
        T.ok(looped.split(separator: "\n").count < 10, "a symlink loop terminates instead of hanging")
        T.ok(looped.contains("loop -> .."), "the link is named rather than followed")
        // And the same rule stops the tree describing files outside the folder it claims to show.
        T.ok(looped.contains("outside -> /etc"), "a link out of the tree is named, not walked into")
        T.ok(!looped.contains("passwd"), "and nothing from /etc appears in the output")

        // The function's own doc says "without flooding its window" and nothing enforced it until
        // this assertion existed. All Levels on a large monorepo put the whole repo on the
        // clipboard.
        let big = base + "/big"
        try? fm.createDirectory(atPath: big, withIntermediateDirectories: true)
        for i in 0..<50 { fm.createFile(atPath: big + "/f\(i).txt", contents: Data("x".utf8)) }
        let capped = TreeRender.render(big, depth: 99, limit: 20)
        T.eq(capped.split(separator: "\n").count, 21, "output stops at the limit, plus the notice")
        T.ok(capped.hasSuffix("… truncated at 20 entries"), "and says it was truncated rather than lying about the shape")
        T.ok(!TreeRender.render(big, depth: 99).contains("truncated"), "under the limit nothing is claimed")
    }
}
