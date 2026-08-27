import Foundation
import ChuteCore

// MARK: - FR-01 paths

func cmdPaths(_ a: Args) {
    let files = a.paths(defaultToCWD: true)
    guard !files.isEmpty else { Out.fail("no files given") }
    let style = PathStyle(rawValue: a.value("format", or: "posix")) ?? .posix
    let sep: PathSeparator = a.value("sep", or: style == .at ? "space" : "line") == "space" ? .space : .line
    let text = PathFormat.render(files, style: style, separator: sep)
    Out.deliver(text, a, badge: "\(files.count) path(s)")
}

// MARK: - FR-02 bundle

func cmdBundle(_ a: Args) {
    let expanded = FileScan.expand(a.paths(defaultToCWD: true))
    guard !expanded.isEmpty else { Out.fail("no readable files in the selection") }
    let (files, skipped) = FileScan.bundleFiles(expanded)
    guard !files.isEmpty else { Out.fail("every selected file is binary or unreadable") }
    let root = ProjectRoot.of(files.map(\.path))
    let text = a.value("format", or: "xml") == "md"
        ? ContextBundle.markdown(files, root: root)
        : ContextBundle.xml(files, root: root)
    let tokens = TokenEstimate.tokens(in: text)
    Out.deliver(text, a, badge: "\(files.count) file(s) · \(TokenEstimate.badge(tokens))")
    if !skipped.isEmpty { Out.info("→ skipped \(skipped.count) binary file(s)") }
}

// MARK: - FR-03 tokens

func cmdTokens(_ a: Args) {
    let expanded = FileScan.expand(a.paths(defaultToCWD: true))
    guard !expanded.isEmpty else { Out.fail("no files given") }
    let root = ProjectRoot.of(expanded)
    var total = 0
    for p in expanded {
        guard let text = FileScan.readText(p) else { continue }
        let n = TokenEstimate.tokens(in: text)
        total += n
        Out.line(String(format: "%8d  %@", n, PathFormat.relativize(p, to: root)))
    }
    Out.line(String(repeating: "-", count: 40))
    Out.line(String(format: "%8d  TOTAL (%@)", total, TokenEstimate.badge(total)))
}

// MARK: - FR-10 tree

func cmdTree(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    guard FileScan.isDirectory(dir) else { Out.fail("not a directory: \(dir)") }
    let depth = Int(a.value("depth", or: "3")) ?? 3
    Out.deliver(TreeRender.render(dir, depth: depth), a)
}

// MARK: - FR-19 redact

func cmdRedact(_ a: Args) {
    let input = a.positional.isEmpty
        ? Clipboard.read()
        : FileScan.expand(a.paths()).compactMap { FileScan.readText($0) }.joined(separator: "\n\n")
    guard !input.isEmpty else { Out.fail("nothing to redact") }
    let out = Redact.apply(input)
    let hits = out.components(separatedBy: "[REDACTED]").count - 1
    Out.deliver(out, a, badge: "\(hits) secret(s) masked")
}

// MARK: - FR-23 data URL

func cmdDataURL(_ a: Args) {
    guard let file = a.paths().first, FileManager.default.fileExists(atPath: file) else {
        Out.fail("usage: chute dataurl <image>")
    }
    guard let data = FileManager.default.contents(atPath: file) else { Out.fail("cannot read \(file)") }
    let ext = (file as NSString).pathExtension.lowercased()
    let mime = ["png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg",
                "gif": "image/gif", "webp": "image/webp", "svg": "image/svg+xml",
                "pdf": "application/pdf"][ext] ?? "application/octet-stream"
    let name = (file as NSString).lastPathComponent
    let url = "data:\(mime);base64,\(data.base64EncodedString())"
    let text = a.has("markdown") ? "![\(name)](\(url))" : url
    Out.deliver(text, a, badge: "\(data.count / 1024) KB")
}

// MARK: - FR-22 context buffer

func cmdBuf(_ a: Args) {
    let dir = (NSHomeDirectory() as NSString).appendingPathComponent(".chute/buffer")
    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let action = a.positional.first ?? "list"
    let entries = ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []).sorted()

    switch action {
    case "add":
        let text = a.positional.count > 1 ? a.positional.dropFirst().joined(separator: " ") : Clipboard.read()
        guard !text.isEmpty else { Out.fail("clipboard is empty") }
        let name = String(format: "%03d.txt", entries.count + 1)
        do {
            try text.write(toFile: (dir as NSString).appendingPathComponent(name),
                           atomically: true, encoding: .utf8)
        } catch { Out.fail("cannot buffer: \(error.localizedDescription)") }
        Out.info("→ buffered entry \(entries.count + 1) (\(TokenEstimate.badge(TokenEstimate.tokens(in: text))))")
    case "list":
        guard !entries.isEmpty else { Out.info("buffer is empty"); return }
        for (i, e) in entries.enumerated() {
            let text = (try? String(contentsOfFile: (dir as NSString).appendingPathComponent(e), encoding: .utf8)) ?? ""
            let head = text.prefix(70).replacingOccurrences(of: "\n", with: " ")
            Out.line("\(i + 1). \(head)…  [\(TokenEstimate.badge(TokenEstimate.tokens(in: text)))]")
        }
    case "flush":
        guard !entries.isEmpty else { Out.fail("buffer is empty") }
        let joined = entries.enumerated().map { i, e -> String in
            let text = (try? String(contentsOfFile: (dir as NSString).appendingPathComponent(e), encoding: .utf8)) ?? ""
            return "--- context \(i + 1) ---\n\(text)"
        }.joined(separator: "\n\n")
        Out.deliver(joined, a, badge: "\(entries.count) entries · \(TokenEstimate.badge(TokenEstimate.tokens(in: joined)))")
        if !a.has("keep") { entries.forEach { try? FileManager.default.removeItem(atPath: (dir as NSString).appendingPathComponent($0)) } }
    case "clear":
        entries.forEach { try? FileManager.default.removeItem(atPath: (dir as NSString).appendingPathComponent($0)) }
        Out.info("→ buffer cleared (\(entries.count) entries)")
    default:
        Out.fail("usage: chute buf add|list|flush|clear")
    }
}
