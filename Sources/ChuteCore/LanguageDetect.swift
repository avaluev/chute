import Foundation

/// FR-05 — content (or a fence hint) to a file extension.
public enum LanguageDetect {
    static let byHint: [String: String] = [
        "python": "py", "py": "py", "python3": "py",
        "typescript": "ts", "ts": "ts", "tsx": "tsx",
        "javascript": "js", "js": "js", "jsx": "jsx", "node": "js",
        "swift": "swift", "sql": "sql", "json": "json",
        "bash": "sh", "sh": "sh", "shell": "sh", "zsh": "sh", "console": "sh",
        "yaml": "yaml", "yml": "yaml", "toml": "toml", "xml": "xml",
        "html": "html", "css": "css", "scss": "scss",
        "ruby": "rb", "rb": "rb", "go": "go", "golang": "go",
        "rust": "rs", "rs": "rs", "java": "java", "kotlin": "kt",
        "c": "c", "cpp": "cpp", "c++": "cpp", "objc": "m", "php": "php",
        "markdown": "md", "md": "md", "text": "txt", "txt": "txt", "diff": "diff",
    ]

    public static func fileExtension(for content: String, hint: String? = nil) -> String {
        if let h = hint?.lowercased(), let ext = byHint[h] { return ext }

        let t = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return "md" }
        let first = String(t.split(separator: "\n", maxSplits: 1).first ?? "")

        if first.hasPrefix("#!") {
            if first.contains("python") { return "py" }
            if first.contains("node")   { return "js" }
            if first.contains("ruby")   { return "rb" }
            return "sh"
        }
        if (t.hasPrefix("{") && t.hasSuffix("}")) || (t.hasPrefix("[") && t.hasSuffix("]")),
           (try? JSONSerialization.jsonObject(with: Data(t.utf8))) != nil {
            return "json"
        }
        let upper = t.uppercased()
        for kw in ["SELECT ", "CREATE TABLE", "INSERT INTO", "ALTER TABLE"] where upper.contains(kw) {
            return "sql"
        }
        if t.contains("import Foundation") || t.contains("import SwiftUI")
            || t.range(of: #"\bfunc\s+\w+\s*\("#, options: .regularExpression) != nil { return "swift" }
        if t.contains("<!DOCTYPE html") || t.contains("<html") { return "html" }
        if t.range(of: #"^\s*(def|class)\s+\w+"#, options: .regularExpression) != nil
            || t.contains("import numpy") || t.contains("__name__") { return "py" }
        if t.contains("interface ") || t.contains("export const") || t.contains(": string") { return "ts" }
        if t.contains("=>") || t.contains("function ") { return "js" }
        return "md"
    }
}
