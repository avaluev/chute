import Foundation

/// FR-04 — name a file the way a human would have named it.
public enum NameDerive {
    /// First markdown heading of any level, as a kebab slug.
    public static func slug(fromMarkdown text: String) -> String? {
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("#") else { continue }
            let title = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            let s = slugify(title)
            return s.isEmpty ? nil : s
        }
        return nil
    }

    public static func slugify(_ s: String, maxLength: Int = 60) -> String {
        var out = ""
        var lastDash = false
        for ch in s.lowercased() {
            if ch.isLetter || ch.isNumber {
                out.append(ch); lastDash = false
            } else if !lastDash && !out.isEmpty {
                out.append("-"); lastDash = true
            }
        }
        while out.hasSuffix("-") { out.removeLast() }
        if out.count > maxLength {
            out = String(out.prefix(maxLength))
            if let i = out.lastIndex(of: "-") { out = String(out[out.startIndex..<i]) }
        }
        return out
    }

    /// The name a person would type: the document's first line of text, as-is, with spaces made
    /// underscores. No slugging, no lowercasing, no cleverness — "# This is the header" becomes
    /// "This_is_the_header.md", which is predictable enough to guess before you click.
    public static func underscoreName(from text: String, maxLength: Int = 60) -> String? {
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            var line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            // A markdown heading is still just the first line of text.
            line = line.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            // Characters no filesystem, Finder column or shell should have to argue about.
            let forbidden = CharacterSet(charactersIn: "/\\:*?\"<>|\u{0}")
            var out = ""
            for ch in line.prefix(maxLength) {
                if ch == " " || ch == "\t" { out.append("_") }
                else if ch.unicodeScalars.allSatisfy({ !forbidden.contains($0) }) { out.append(ch) }
            }
            while out.hasSuffix("_") || out.hasSuffix(".") { out.removeLast() }
            return out.isEmpty ? nil : out
        }
        return nil
    }

    public static func fallbackName(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return "chute-" + f.string(from: date)
    }

    /// NFR-08 — never overwrite. Falls back to `name-2`, `name-3`, …
    public static func uniquePath(dir: String, base: String, ext: String,
                                  exists: (String) -> Bool) -> String {
        func candidate(_ n: Int) -> String {
            let name = n == 1 ? "\(base).\(ext)" : "\(base)-\(n).\(ext)"
            return (dir as NSString).appendingPathComponent(name)
        }
        var n = 1
        while exists(candidate(n)) { n += 1 }
        return candidate(n)
    }
}
