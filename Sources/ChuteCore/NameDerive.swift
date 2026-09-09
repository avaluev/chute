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

    /// A FILE NAME IS ONE PATH COMPONENT. Enforced HERE rather than at each call site, because
    /// this function is the single point every written name routes through: `cmdNew` slugifies
    /// its `--name` and `cmdPasteImage` did not, so `chute paste-image --name ../../evil.png`
    /// wrote outside the folder the user pointed at. Guarding one caller would have left the
    /// other, and the next command to call `writeUniquely` would have arrived unguarded too.
    ///
    /// The separator is what carries a file out of `dir`, so the separator is what cannot
    /// survive. Leading dots go with it: they make hidden files, and `..` is the traversal this
    /// exists to stop. Everything else is left alone — this is NOT `slugify`, which lowercases
    /// and dashes and would destroy `underscoreName`'s deliberate "This_is_the_header".
    static func fileComponent(_ s: String, fallback: String) -> String {
        let flattened = s.replacingOccurrences(of: "/", with: "-")
        let trimmed = String(flattened.drop(while: { $0 == "." }))
        return trimmed.isEmpty ? fallback : trimmed
    }

    static func candidate(dir: String, base: String, ext: String, n: Int) -> String {
        let b = fileComponent(base, fallback: "untitled")
        let e = fileComponent(ext, fallback: "txt")
        let name = n == 1 ? "\(b).\(e)" : "\(b)-\(n).\(e)"
        return (dir as NSString).appendingPathComponent(name)
    }

    /// NFR-08 under concurrency. Probing then writing is a race two simultaneous invocations can
    /// lose — both resolve `Shot-2.png`, the second silently clobbers the first. So the WRITE is
    /// the probe: `.withoutOverwriting` is O_EXCL at the filesystem, and a collision just moves to
    /// the next candidate name.
    public static func writeUniquely(dir: String, base: String, ext: String,
                                     data: Data) throws -> String {
        var n = 1
        while true {
            let path = candidate(dir: dir, base: base, ext: ext, n: n)
            do {
                try data.write(to: URL(fileURLWithPath: path), options: .withoutOverwriting)
                return path
            } catch let e as CocoaError where e.code == .fileWriteFileExists {
                n += 1
            }
        }
    }
}
