import Foundation
import ChuteCore

// MARK: - FR-01 paths

func cmdPaths(_ a: Args) {
    let files = a.paths(defaultToCWD: true)
    guard !files.isEmpty else { Out.fail("no files given") }
    let style = PathStyle(rawValue: a.value("format", or: "posix")) ?? .posix
    let sep: PathSeparator = a.value("sep", or: style == .at ? "space" : "line") == "space" ? .space : .line
    let text = PathFormat.render(files, style: style, separator: sep)
    Out.deliver(text, a, badge: "\(files.count) path(s)",
                label: files.count == 1 ? "1 full path" : "\(files.count) full paths")
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
    Out.deliver(text, a, badge: "\(files.count) file(s) · \(TokenEstimate.badge(tokens))",
                label: "\(contextLabel(files.map(\.path))) · \(files.count) file(s) · \(TokenEstimate.badge(tokens))")
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
    Out.deliver(TreeRender.render(dir, depth: depth), a,
                label: "Folder tree · \((dir as NSString).lastPathComponent) (\(depth) deep)")
}

// MARK: - FR-19 redact

func cmdRedact(_ a: Args) {
    let input = a.positional.isEmpty
        ? Clipboard.read()
        : FileScan.expand(a.paths()).compactMap { FileScan.readText($0) }.joined(separator: "\n\n")
    guard !input.isEmpty else { Out.fail("nothing to redact") }
    let out = Redact.apply(input)
    let hits = out.components(separatedBy: "[REDACTED]").count - 1
    Out.deliver(out, a, badge: "\(hits) secret(s) masked",
                label: "Redacted · \(hits) secret(s) masked")
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
    Out.deliver(text, a, badge: "\(data.count / 1024) KB",
                label: "Image as a data URL · \(data.count / 1024) KB")
}

// MARK: - FR-22 context buffer

func cmdBuf(_ a: Args) {
    // The store is ChuteCore.ContextBuffer, shared with the menu bar's Clipboard Buffer submenu.
    // It used to live here, and naming entries after the CURRENT COUNT meant removing one made the
    // next add overwrite a surviving entry — in the one feature whose entire purpose is not losing
    // a copy. See ContextBuffer.add.
    let buf = ContextBuffer()
    let action = a.positional.first ?? "list"

    switch action {
    case "add":
        let text = a.positional.count > 1 ? a.positional.dropFirst().joined(separator: " ") : Clipboard.read()
        guard !text.isEmpty else { Out.fail("clipboard is empty") }
        guard buf.add(text) != nil else { Out.fail("cannot buffer: could not write to \(buf.directory)") }
        Out.info("→ buffered entry \(buf.entries().count) (\(TokenEstimate.badge(TokenEstimate.tokens(in: text))))")
    case "list":
        let entries = buf.entries()
        guard !entries.isEmpty else { Out.info("buffer is empty"); return }
        for (i, e) in entries.enumerated() {
            Out.line("\(i + 1). \(e.preview)  [\(TokenEstimate.badge(TokenEstimate.tokens(in: e.text)))]")
        }
    case "flush":
        guard let joined = buf.flushText() else { Out.fail("buffer is empty") }
        let n = buf.entries().count
        Out.deliver(joined, a, badge: "\(n) entries · \(TokenEstimate.badge(TokenEstimate.tokens(in: joined)))",
                    label: "\(n) recent copies, together")
        if !a.has("keep") { buf.clear() }
    case "clear":
        let n = buf.entries().count
        buf.clear()
        Out.info("→ buffer cleared (\(n) entries)")
    default:
        Out.fail("usage: chute buf add|list|flush|clear")
    }
}

/// The shortest true description of what a bundle covered, for a menu row. Folder names where
/// they are common, otherwise a count — "src/auth, src/api" is what you are scanning for; the
/// first sixty characters of an XML blob is not.
func contextLabel(_ files: [String]) -> String {
    let dirs = Array(Set(files.map { ($0 as NSString).deletingLastPathComponent })).sorted()
        .map { $0.isEmpty ? "." : ($0 as NSString).lastPathComponent }
    if dirs.isEmpty { return "Context" }
    if dirs.count <= 2 { return dirs.joined(separator: ", ") }
    return "\(dirs.count) folders"
}
