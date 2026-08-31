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

/// The text `bundle` hands over — and therefore the text `tokens` must count, and what the
/// context basket's "Copy Basket as Context" must be byte-identical to. ONE definition:
/// `ContextBundle.assemble`, declared in `ChuteCore/ContextBuffer.swift` so the basket can reach
/// it too. This is a thin wrapper picking the format out of `Args`, not a second copy of it.
func assembledBundle(_ paths: [String], _ a: Args)
    -> (text: String, files: [BundleFile], skipped: [String]) {
    ContextBundle.assemble(paths, format: a.value("format", or: "xml"))
}

// MARK: - FR-02 bundle

func cmdBundle(_ a: Args) {
    let expanded = FileScan.expand(a.paths(defaultToCWD: true))
    guard !expanded.isEmpty else { Out.fail("no readable files in the selection") }
    let (text, files, skipped) = assembledBundle(expanded, a)
    guard !files.isEmpty else { Out.fail("every selected file is binary or unreadable") }
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
    // TOTAL is the ASSEMBLED-BUNDLE count, not the sum of the rows above: the wrapper markup is
    // real text the user pastes, and this command exists to say how big the paste will be. The
    // rows are still correct and no longer add up to it — that gap IS the markup.
    let bundleTokens = TokenEstimate.tokens(in: assembledBundle(expanded, a).text)
    Out.line(String(format: "%8d  TOTAL — as pasted, bundle markup included (%@)",
                    bundleTokens, TokenEstimate.badge(bundleTokens)))
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

// MARK: - FR-22 context basket

/// `chute buf` → `chute basket`, 2026-08-31 — the ICP decision. A basket entry is a FILE PATH
/// now, not a copy of its content (see `ChuteCore/ContextBuffer.swift`), and the only way in is
/// explicit: `add`. Nothing auto-files any more.
///
/// `cmdBuf` below stays as a one-line alias — `Sources/chute/main.swift`'s switch still reads
/// `case "buf": cmdBuf(args)`, and that file is not owned here; the parent adds `case "basket":
/// cmdBasket(args)` and the `help` text, see FINDINGS.
func cmdBasket(_ a: Args) {
    // The store is ChuteCore.ContextBuffer, shared with the menu bar's Basket section.
    let buf = ContextBuffer()
    let action = a.positional.first ?? "list"

    switch action {
    case "add":
        let paths = a.paths(dropping: 1)
        guard !paths.isEmpty else { Out.fail("usage: chute basket add <files…>") }
        paths.forEach { buf.add($0) }
        Out.info("→ added \(paths.count) — \(buf.entries().count) in the basket")
    case "list":
        let entries = buf.entries()
        guard !entries.isEmpty else { Out.info("basket is empty"); return }
        for (i, e) in entries.enumerated() { Out.line("\(i + 1). \(e.preview)") }
    // Two formats, the ICP decision: @-mentions for the Claude Code / Cursor user who has
    // filesystem access and just needs paths pointed at; `--format context` for the chat-UI
    // persona `chute unpack` still serves, carrying its own token count.
    case "copy":
        guard !buf.entries().isEmpty else { Out.fail("basket is empty") }
        if a.value("format", or: "mentions") == "context" {
            let text = buf.bundleText() ?? ""
            Out.deliver(text, a,
                        badge: "\(buf.entries().count) file(s) · \(TokenEstimate.badge(TokenEstimate.tokens(in: text)))",
                        label: "Basket as Context")
        } else {
            let text = buf.mentionText() ?? ""
            Out.deliver(text, a, badge: "\(buf.entries().count) file(s) as @mentions",
                        label: "Basket as @mentions")
        }
    case "clear":
        let n = buf.entries().count
        buf.clear()
        Out.info("→ basket cleared (\(n) entries)")
    default:
        Out.fail("usage: chute basket add|list|copy|clear")
    }
}

/// Kept exactly as `flush` was kept as an undocumented alias for `all`: muscle memory and scripts
/// cost more to break than the old name is worth.
func cmdBuf(_ a: Args) { cmdBasket(a) }

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
