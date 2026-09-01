import Foundation
import ChuteCore

func projectRootSuite() {
    T.suite("ProjectRoot") {
        let fm = FileManager.default
        let tmp = NSTemporaryDirectory() + "chute-root-\(UUID().uuidString)"
        // A real path, not a symlink: /var is a symlink to /private/var on macOS, and `hasPrefix`
        // comparisons against an unresolved path silently never match.
        let base = (tmp as NSString).resolvingSymlinksInPath
        defer { try? fm.removeItem(atPath: base) }
        try? fm.createDirectory(atPath: base + "/repo/src/deep", withIntermediateDirectories: true)
        fm.createFile(atPath: base + "/repo/src/deep/a.swift", contents: Data("x".utf8))

        // No .git anywhere yet — the walk must not claim a root it did not find.
        T.eq(ProjectRoot.of([base + "/repo/src/deep/a.swift"], cwd: base + "/repo"), base + "/repo",
             "with no .git it falls back to the working directory")

        // The ordinary case: .git as a DIRECTORY.
        try? fm.createDirectory(atPath: base + "/repo/.git", withIntermediateDirectories: true)
        T.eq(ProjectRoot.of([base + "/repo/src/deep/a.swift"], cwd: base),
             base + "/repo", "the nearest ancestor holding .git is the root")

        // THE ONE A NAIVE isDirectory CHECK GETS WRONG. In a linked worktree or a submodule, .git
        // is a regular FILE containing `gitdir: …`. `git rev-parse --show-toplevel` reports the
        // root for both; anything that requires a directory reports "not a repository".
        try? fm.createDirectory(atPath: base + "/wt/src", withIntermediateDirectories: true)
        fm.createFile(atPath: base + "/wt/src/b.swift", contents: Data("x".utf8))
        fm.createFile(atPath: base + "/wt/.git", contents: Data("gitdir: /elsewhere/.git/worktrees/wt".utf8))
        T.eq(ProjectRoot.of([base + "/wt/src/b.swift"], cwd: base), base + "/wt",
             "a worktree's .git is a file, and it is still a root")

        // A path OUTSIDE the repo it found must not be relativised against it.
        T.eq(ProjectRoot.of([base + "/repo/src/deep/a.swift", base + "/wt/src/b.swift"], cwd: base),
             base, "a root that does not contain every path is rejected")
    }
}
