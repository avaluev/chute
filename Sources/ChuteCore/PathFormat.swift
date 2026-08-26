import Foundation

public enum PathStyle: String, CaseIterable, Sendable {
    case posix, quoted, relative, at
}

public enum PathSeparator: String, Sendable { case line, space }

/// FR-01 — turn a Finder selection into paths an agent can consume.
public enum PathFormat {
    /// Deepest directory containing every given path. Paths must be absolute.
    public static func commonAncestor(_ paths: [String]) -> String {
        guard !paths.isEmpty else { return "" }
        let dirs = paths.map { p -> [String] in
            var c = p.split(separator: "/").map(String.init)
            if !c.isEmpty { c.removeLast() }   // drop the file name
            return c
        }
        var common = dirs[0]
        for d in dirs.dropFirst() {
            var i = 0
            while i < min(common.count, d.count), common[i] == d[i] { i += 1 }
            common = Array(common[0..<i])
        }
        return "/" + common.joined(separator: "/")
    }

    public static func render(_ paths: [String],
                              style: PathStyle,
                              separator: PathSeparator = .line) -> String {
        guard !paths.isEmpty else { return "" }
        let root = commonAncestor(paths)
        let out = paths.map { p -> String in
            switch style {
            case .posix:    return p
            case .quoted:   return shellQuote(p)
            case .relative: return relativize(p, to: root)
            case .at:       return "@" + relativize(p, to: root)
            }
        }
        return out.joined(separator: separator == .line ? "\n" : " ")
    }

    public static func relativize(_ path: String, to root: String) -> String {
        guard root != "/", path.hasPrefix(root + "/") else { return path }
        return String(path.dropFirst(root.count + 1))
    }

    /// POSIX single-quoting: safe for every character including quotes and spaces.
    public static func shellQuote(_ p: String) -> String {
        "'" + p.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
