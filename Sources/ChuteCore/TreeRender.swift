import Foundation

/// FR-10 — structural awareness for an agent without flooding its window.
public enum TreeRender {
    /// The promise in the line above was not enforced until 2026-09-02. `Copy Folder Tree ▸ All
    /// Levels` walks to depth 99, and on a large monorepo that put every entry in the repository
    /// on the clipboard — the exact opposite of "without flooding its window", from the menu item
    /// whose whole purpose is to avoid it.
    ///
    /// 2,000 entries is far more shape than an agent needs to navigate and still pastes without
    /// eating a context window.
    public static let maxEntries = 2000

    public static func render(_ root: String, depth: Int = 3, limit: Int = maxEntries) -> String {
        let name = (root as NSString).lastPathComponent
        var lines = [name + "/"]
        var truncated = false
        walk(root, prefix: "", depth: depth, limit: limit, into: &lines, truncated: &truncated)
        // Say so. A tree silently cut off at an arbitrary point is a tree that lies about the
        // shape of the folder, which is the one thing this function exists to report.
        if truncated { lines.append("… truncated at \(limit) entries") }
        return lines.joined(separator: "\n")
    }

    static func walk(_ dir: String, prefix: String, depth: Int, limit: Int,
                     into lines: inout [String], truncated: inout Bool) {
        guard depth > 0, !truncated else { return }
        let fm = FileManager.default
        // Say so. A TCC-protected or other-owned folder drawn as a bare `name/` tells the agent
        // it is empty, which is the one thing this function exists not to do.
        guard let raw = try? fm.contentsOfDirectory(atPath: dir) else {
            lines.append(prefix + "└── (unreadable)"); return
        }
        let entries = raw
            .filter { !Junk.isJunk(name: $0, isDirectory: FileScan.isDirectory((dir as NSString).appendingPathComponent($0))) }
            .filter { !$0.hasPrefix(".") || $0 == ".github" }
            .sorted()
        for (i, name) in entries.enumerated() {
            if lines.count >= limit { truncated = true; return }
            let full = (dir as NSString).appendingPathComponent(name)

            // A SYMLINKED DIRECTORY IS NAMED AND NEVER ENTERED.
            //
            // `FileScan.isDirectory` follows the link, so `links/real/loop -> ..` read as a
            // directory and this function walked into itself. Measured 2026-09-02: depth 2 gave
            // 11 lines, depth 4 gave 31, depth 8 gave 151, and depth 99 — which is what
            // `Copy Folder Tree ▸ All Levels` uses — never returned. Killed at 20 seconds with no
            // output. A loop like that is ordinary: `node_modules/.bin`, a venv, a `Current`
            // link in a framework.
            //
            // Not following them also stops the tree leaving the folder it claims to describe:
            // a link to `/etc` would otherwise be rendered as part of your project.
            //
            // `attributesOfItem` reports on the LINK rather than its target — the same lstat
            // semantics `ActionRequest.isTrustworthy` relies on. `tree(1)` makes the same choice
            // by default and needs `-l` to opt in.
            let attrs = try? fm.attributesOfItem(atPath: full)
            let isLink = (attrs?[.type] as? FileAttributeType) == .typeSymbolicLink
            let isDir = !isLink && FileScan.isDirectory(full)
            let last = i == entries.count - 1
            let arrow = isLink ? " -> \((try? fm.destinationOfSymbolicLink(atPath: full)) ?? "?")" : ""
            lines.append(prefix + (last ? "└── " : "├── ") + name + (isDir ? "/" : "") + arrow)
            if isDir {
                walk(full, prefix: prefix + (last ? "    " : "│   "),
                     depth: depth - 1, limit: limit, into: &lines, truncated: &truncated)
            }
        }
    }
}
