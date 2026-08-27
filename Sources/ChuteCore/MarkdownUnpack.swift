import Foundation

public struct UnpackedFile: Sendable, Equatable {
    public let path: String
    public let content: String
    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}

public enum UnpackError: Error, CustomStringConvertible {
    case unsafePath(String)
    public var description: String {
        switch self {
        case .unsafePath(let p):
            return "refusing to write outside the target directory: \(p)"
        }
    }
}

/// FR-06 — the other direction of the loop: an LLM answer back onto disk.
public enum MarkdownUnpack {
    public static func parse(_ markdown: String) -> [UnpackedFile] {
        let lines = markdown.components(separatedBy: "\n")
        var out: [UnpackedFile] = []
        var i = 0
        while i < lines.count {
            guard lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") else {
                i += 1; continue
            }
            let info = String(lines[i].trimmingCharacters(in: .whitespaces).dropFirst(3))
                .trimmingCharacters(in: .whitespaces)
            var body: [String] = []
            var j = i + 1
            while j < lines.count, !lines[j].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                body.append(lines[j]); j += 1
            }
            if let path = pathFrom(info: info) ?? pathFromContext(lines, before: i) {
                out.append(UnpackedFile(path: path, content: body.joined(separator: "\n")))
            }
            i = j + 1
        }
        return out
    }

    /// NFR-06 — a path from an LLM is untrusted input.
    @discardableResult
    public static func validate(_ files: [UnpackedFile]) throws -> [UnpackedFile] {
        for f in files {
            let p = f.path
            guard !p.hasPrefix("/"), !p.hasPrefix("~") else { throw UnpackError.unsafePath(p) }
            let comps = p.split(separator: "/").map(String.init)
            guard !comps.isEmpty, !comps.contains("..") else { throw UnpackError.unsafePath(p) }
        }
        return files
    }

    /// The final guard, applied where the write happens. `validate` rejects `..` and absolute
    /// paths in the TEXT, but a path can still escape through a symlink that already exists in the
    /// target folder: with `src -> /etc`, the innocent-looking `src/passwd` writes to /etc/passwd.
    /// Resolving both sides and comparing is the only check that survives that.
    public static func staysInside(dir: String, path: String) -> Bool {
        let root = URL(fileURLWithPath: dir).resolvingSymlinksInPath().standardizedFileURL
        let full = URL(fileURLWithPath: (dir as NSString).appendingPathComponent(path))
        // Resolve the PARENT: the file itself does not exist yet, and a non-existent leaf resolves
        // to itself, which would hide an escaping parent.
        let parent = full.deletingLastPathComponent().resolvingSymlinksInPath().standardizedFileURL
        let rootPath = root.path.hasSuffix("/") ? root.path : root.path + "/"
        return parent.path == root.path || parent.path.hasPrefix(rootPath)
    }

    static func looksLikePath(_ s: String) -> Bool {
        guard !s.isEmpty, !s.contains(" "), s.count <= 200 else { return false }
        if s.contains("/") { return true }
        let ext = (s as NSString).pathExtension
        return !ext.isEmpty && ext.count <= 5 && s.count > ext.count + 1
    }

    static func pathFrom(info: String) -> String? {
        for token in info.split(separator: " ").map(String.init) where looksLikePath(token) {
            return token
        }
        return nil
    }

    /// Looks back up to three non-empty lines for a heading or bold line naming the file.
    static func pathFromContext(_ lines: [String], before idx: Int) -> String? {
        var seen = 0
        var k = idx - 1
        while k >= 0, seen < 3 {
            let raw = lines[k].trimmingCharacters(in: .whitespaces)
            k -= 1
            if raw.isEmpty { continue }
            seen += 1
            let cleaned = raw
                .replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "`", with: "")
                .replacingOccurrences(of: ":", with: "")
                .trimmingCharacters(in: .whitespaces)
            if looksLikePath(cleaned) { return cleaned }
        }
        return nil
    }
}
