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
        // COUNT WHAT HAPPENED, not what was attempted. This reported `paths.count` and discarded
        // `add`'s return, so a write that failed — a full disk, a directory it could not create —
        // still printed "added 3", and re-adding a file already in the basket printed "added 1"
        // when nothing was added. The same rule the metrics work is built on, pointing the other
        // way: a failure is not a success.
        let before = Set(buf.entries().map(\.path))
        // Two different failures, and telling them apart is the whole point of reporting at all.
        // "could not add anything — is the basket writable?" was printed for a path that simply
        // did not exist, which sends the reader to check permissions on a directory that is fine.
        let missing = paths.filter { !FileManager.default.fileExists(atPath: $0) }
        let failed = paths.filter { buf.add($0) == nil }
        let added = buf.entries().filter { !before.contains($0.path) }.count
        let already = paths.count - added - failed.count
        guard failed.count < paths.count else {
            Out.fail(missing.count == paths.count
                ? "no such file: \(missing.joined(separator: ", "))"
                : "could not add anything to the basket — is \(buf.directory) writable?")
        }
        var said = "→ added \(added)"
        if already > 0 { said += " · \(already) already there" }
        if !failed.isEmpty { said += " · \(failed.count) could not be added" }
        Out.info(said + " — \(buf.entries().count) in the basket")
        if !failed.isEmpty { failed.forEach { Out.info("  not added: \($0)") } }
    case "list":
        let entries = buf.entries()
        guard !entries.isEmpty else { Out.info("basket is empty"); return }
        for (i, e) in entries.enumerated() { Out.line("\(i + 1). \(e.preview)") }
    // Two formats, the ICP decision: @-mentions for the Claude Code / Cursor user who has
    // filesystem access and just needs paths pointed at; `--format context` for the chat-UI
    // persona who pastes into a browser, carrying its own token count. (This comment named
    // `chute unpack` until 2026-09-02; that command was deleted on 2026-08-31.)
    case "copy":
        guard !buf.entries().isEmpty else { Out.fail("basket is empty") }
        if a.value("format", or: "mentions") == "context" {
            let text = buf.bundleText() ?? ""
            // EVERY ENTRY GONE IS NOT AN EMPTY BASKET, and it must not read as success. Because a
            // basket holds paths, a file can vanish between `add` and `copy`; `basket list` marks
            // those "— missing", but this branch handed over an empty blob and announced
            // "→ 2 file(s) · ~0 tokens", exit 0. The user pastes nothing and is told it worked.
            guard !text.isEmpty else {
                Out.fail("every file in the basket is gone — `chute basket list` shows which")
            }
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
