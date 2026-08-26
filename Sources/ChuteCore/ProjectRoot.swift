import Foundation

/// Paths handed to an agent must mean something to the agent: `src/a.ts`, not `a.ts`.
/// Priority: the git top level, then the working directory, then the deepest shared directory.
public enum ProjectRoot {
    public static func of(_ paths: [String],
                          cwd: String = FileManager.default.currentDirectoryPath) -> String {
        let ancestor = PathFormat.commonAncestor(paths)
        let start = FileScan.isDirectory(ancestor) ? ancestor : (ancestor as NSString).deletingLastPathComponent

        if !start.isEmpty {
            let r = Shell.run("git", ["rev-parse", "--show-toplevel"], cwd: start)
            let top = r.out.trimmingCharacters(in: .whitespacesAndNewlines)
            if r.ok, !top.isEmpty, paths.allSatisfy({ $0.hasPrefix(top + "/") }) { return top }
        }
        if paths.allSatisfy({ $0.hasPrefix(cwd + "/") }) { return cwd }
        return ancestor
    }
}
