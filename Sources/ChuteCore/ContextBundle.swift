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
    /// Content is deliberately NOT XML-escaped. Escaping turns `Set<String>` into
    /// `Set&lt;String&gt;`, which is harder for a model to read and costs more tokens. Only the
    /// path attribute is escaped, plus any literal closing tag inside the body.
    public static func xml(_ files: [BundleFile], root: String?) -> String {
        files.map { f in
            let body = f.content.replacingOccurrences(of: "</file>", with: "<\\/file>")
            return "<file path=\"\(escapeAttribute(rel(f.path, root)))\">\n\(body)\n</file>"
        }.joined(separator: "\n\n")
    }

    public static func markdown(_ files: [BundleFile], root: String?) -> String {
        files.map { f in
            let r = rel(f.path, root)
            let lang = (r as NSString).pathExtension
            return "```\(lang) \(r)\n\(f.content)\n```"
        }.joined(separator: "\n\n")
    }

    static func escapeAttribute(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "\"", with: "&quot;")
         .replacingOccurrences(of: "<", with: "&lt;")
    }

    static func rel(_ p: String, _ root: String?) -> String {
        guard let root, root != "/", p.hasPrefix(root + "/") else { return p }
        return String(p.dropFirst(root.count + 1))
    }
}
