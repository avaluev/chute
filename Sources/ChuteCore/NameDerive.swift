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
