import Foundation

public struct BundleFile: Sendable, Equatable {
    public let path: String
    public let content: String
    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

/// FR-02 — the wedge: many files into one paste-ready blob.
public enum ContextBundle {
    public static func xml(_ files: [BundleFile], root: String?) -> String {
        files.map { f in
            "<file path=\"\(escape(rel(f.path, root)))\">\n\(escape(f.content))\n</file>"
        }.joined(separator: "\n\n")
    }

    public static func markdown(_ files: [BundleFile], root: String?) -> String {
        files.map { f in
            let r = rel(f.path, root)
            let lang = (r as NSString).pathExtension
            return "```\(lang) \(r)\n\(f.content)\n```"
        }.joined(separator: "\n\n")
    }

    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
         .replacingOccurrences(of: "\"", with: "&quot;")
    }

    static func rel(_ p: String, _ root: String?) -> String {
        guard let root, root != "/", p.hasPrefix(root + "/") else { return p }
        return String(p.dropFirst(root.count + 1))
    }
}
