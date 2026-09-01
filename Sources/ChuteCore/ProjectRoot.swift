import Foundation

/// Paths handed to an agent must mean something to the agent: `src/a.ts`, not `a.ts`.
/// Priority: the git top level, then the working directory, then the deepest shared directory.
public enum ProjectRoot {
    /// The git top level WITHOUT spawning git.
    ///
    /// This used to be `Shell.run("git", ["rev-parse", "--show-toplevel"])`. Measured 2026-09-01:
    /// one `chute bundle` of a SINGLE file took 97 ms, of which ~85 ms was that subprocess — 88%
    /// of the command's entire runtime, paid before a byte of the user's file was read. `chute
    /// tokens` paid it twice (184 ms) because it resolves the root and then assembles the bundle,
    /// which resolves it again.
    ///
    /// What `--show-toplevel` returns is the nearest ancestor containing `.git`. That is a handful
    /// of `stat` calls.
    ///
    /// `.git` is tested for EXISTENCE, not for being a directory: inside a linked worktree or a
    /// submodule it is a regular FILE containing `gitdir: …`. Requiring a directory would report
    /// "not a repository" for both, which is the bug this sentence exists to prevent.
    static func gitTopLevel(from start: String) -> String? {
        let fm = FileManager.default
        var dir = start
        while !dir.isEmpty, dir != "/" {
            if fm.fileExists(atPath: (dir as NSString).appendingPathComponent(".git")) { return dir }
            let parent = (dir as NSString).deletingLastPathComponent
            if parent == dir { break }   // no progress — stop rather than spin
            dir = parent
        }
        return nil
    }

    public static func of(_ paths: [String],
                          cwd: String = FileManager.default.currentDirectoryPath) -> String {
        let ancestor = PathFormat.commonAncestor(paths)
        let start = FileScan.isDirectory(ancestor) ? ancestor : (ancestor as NSString).deletingLastPathComponent

        if !start.isEmpty, let top = gitTopLevel(from: start),
           paths.allSatisfy({ $0.hasPrefix(top + "/") }) { return top }
        if paths.allSatisfy({ $0.hasPrefix(cwd + "/") }) { return cwd }
        return ancestor
    }
}
