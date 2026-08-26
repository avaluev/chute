import Foundation

/// FR-10 — structural awareness for an agent without flooding its window.
public enum TreeRender {
    public static func render(_ root: String, depth: Int = 3) -> String {
        let name = (root as NSString).lastPathComponent
        var lines = [name + "/"]
        walk(root, prefix: "", depth: depth, into: &lines)
        return lines.joined(separator: "\n")
    }

    static func walk(_ dir: String, prefix: String, depth: Int, into lines: inout [String]) {
        guard depth > 0 else { return }
        let fm = FileManager.default
        guard let raw = try? fm.contentsOfDirectory(atPath: dir) else { return }
        let entries = raw
            .filter { !Junk.isJunk(name: $0, isDirectory: FileScan.isDirectory((dir as NSString).appendingPathComponent($0))) }
            .filter { !$0.hasPrefix(".") || $0 == ".github" }
            .sorted()
        for (i, name) in entries.enumerated() {
            let full = (dir as NSString).appendingPathComponent(name)
            let isDir = FileScan.isDirectory(full)
            let last = i == entries.count - 1
            lines.append(prefix + (last ? "└── " : "├── ") + name + (isDir ? "/" : ""))
            if isDir {
                walk(full, prefix: prefix + (last ? "    " : "│   "), depth: depth - 1, into: &lines)
            }
        }
    }
}
