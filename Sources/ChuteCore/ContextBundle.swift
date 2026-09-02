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
            return "<file path=\"\(escapeAttribute((root).map { PathFormat.relativize(f.path, to: $0) } ?? f.path))\">\n\(body)\n</file>"
        }.joined(separator: "\n\n")
    }

    public static func markdown(_ files: [BundleFile], root: String?) -> String {
        files.map { f in
            let r = (root).map { PathFormat.relativize(f.path, to: $0) } ?? f.path
            let lang = (r as NSString).pathExtension
            return "```\(lang) \(r)\n\(f.content)\n```"
        }.joined(separator: "\n\n")
    }

    static func escapeAttribute(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "\"", with: "&quot;")
         .replacingOccurrences(of: "<", with: "&lt;")
    }

}

/// ONE DEFINITION OF "THE BUNDLE", reused rather than copied — `chute bundle`'s `assembledBundle`
/// (`chute`'s `ContextCommands.swift`) and `ContextBuffer.bundleText()` both call this and only
/// this, so they can never drift into two different formats. The precise defect a previous commit
/// already collapsed out of `doctor --fix` once.
///
/// It lived in `ContextBuffer.swift` for one commit, because the agent that wrote it did not own
/// this file and Swift lets an extension sit anywhere in the module. It compiled and it was
/// correct — but "where is the bundle defined?" then had two plausible answers and only one right
/// one, which is the same cost as two definitions minus the drift.
extension ContextBundle {
    public static func assemble(_ paths: [String], format: String = "xml")
        -> (text: String, files: [BundleFile], skipped: [String]) {
        let (files, skipped) = FileScan.bundleFiles(paths)
        let root = ProjectRoot.of(files.map(\.path))
        let text = format == "md" ? markdown(files, root: root) : xml(files, root: root)
        return (text, files, skipped)
    }
}
