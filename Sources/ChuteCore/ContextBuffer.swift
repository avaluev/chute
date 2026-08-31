import Foundation

/// The context basket — JTBD 22, "the files I need are in four different folders and the
/// clipboard holds one thing".
///
/// A BASKET ENTRY IS A FILE PATH, not a blob of text. It shipped as a log of copied strings —
/// "Recent Copies" — so only the 3 of 10 Finder actions that happened to call `Out.deliver` ever
/// wrote to it, the ones the owner uses daily wrote nothing, and the list could not change no
/// matter what he did: indistinguishable, from outside, from a hardcoded one. Storing a path
/// instead collapses the feature: no size limit worth having (a path is 200 bytes), no separate
/// flush format to keep in sync with `chute bundle` (content is read at flush time, through the
/// one function that already renders it), and a row that says exactly what it is.
///
/// NOTHING FILES ITSELF ANY MORE, either. `Out.deliver`'s old auto-record put a copy of every
/// command's output in here on every run — the actual cause of the "hardcoded" complaint. The
/// only way in now is `chute basket add <files…>` or the Finder's "Add to Basket" row.
///
/// Extracted from `cmdBasket` so the menu bar and the CLI read the same store — a second SURFACE,
/// never a second implementation.
public struct ContextBuffer: Sendable {
    public struct Entry: Sendable, Equatable {
        public let name: String       // "1787923488-a1b2.json"
        public let path: String       // the file this entry points at
        public let date: Date

        /// Filename plus immediate parent — enough to tell two `index.ts` apart on sight. Says
        /// so when the file is gone rather than hiding it: a refusal is not a zero, so a dead
        /// path stays visible instead of `entries()` quietly filtering it out.
        public var preview: String {
            let ns = path as NSString
            let file = ns.lastPathComponent
            let parent = (ns.deletingLastPathComponent as NSString).lastPathComponent
            let base = parent.isEmpty ? file : "\(parent)/\(file)"
            return FileManager.default.fileExists(atPath: path) ? base : "\(base) — missing"
        }
    }

    /// How many are kept. A path costs nothing to store, but a basket that never forgets is a
    /// junk drawer, not a collection you are actively assembling.
    public static let keep = 10

    public let directory: String

    public init(directory: String = (NSHomeDirectory() as NSString)
                    .appendingPathComponent(".chute/buffer")) {
        self.directory = directory
    }

    private var fm: FileManager { .default }
    private func path(_ name: String) -> String {
        (directory as NSString).appendingPathComponent(name)
    }

    public func entries() -> [Entry] {
        // OLD-FORMAT AND MALFORMED FILES: IGNORED, NOT CRASHED ON. An entry used to be
        // `{ts, label, text}`; those have no `"path"` key, so they fail the guard below and are
        // skipped like any other garbage file. No migration — four stale fixtures are worth
        // nothing. Ordered by the recorded time, name breaking ties inside the same millisecond.
        let names = ((try? fm.contentsOfDirectory(atPath: directory)) ?? [])
            .filter { $0.hasSuffix(".json") }
        return names.compactMap { name in
            guard let data = fm.contents(atPath: path(name)),
                  let o = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let p = o["path"] as? String else { return nil }
            return Entry(name: name, path: p,
                        date: Date(timeIntervalSince1970: (o["ts"] as? Double) ?? 0))
        }
        .sorted { ($0.date, $0.name) < ($1.date, $1.name) }
    }

    /// The explicit path in. Deduplicated on the PATH — adding the same file twice is not
    /// collecting a second thing.
    @discardableResult
    public func add(_ filePath: String) -> Entry? {
        guard !filePath.isEmpty else { return nil }
        if let existing = entries().first(where: { $0.path == filePath }) { return existing }
        // 0700 / 0600 — every sensitive path here locks itself down the same way (ActionRequest,
        // RequestInbox, the env file); `createDirectory` alone would not fix an install that
        // already exists at the wrong mode, hence the explicit repair on every add.
        try? fm.createDirectory(atPath: directory, withIntermediateDirectories: true,
                                attributes: [.posixPermissions: NSNumber(value: 0o700)])
        try? fm.setAttributes([.posixPermissions: NSNumber(value: 0o700)], ofItemAtPath: directory)
        for stale in (try? fm.contentsOfDirectory(atPath: directory)) ?? [] where stale.hasSuffix(".json") {
            try? fm.setAttributes([.posixPermissions: NSNumber(value: 0o600)],
                                  ofItemAtPath: path(stale))
        }
        let now = Date()
        let name = String(format: "%012.0f-%@.json", now.timeIntervalSince1970 * 1000,
                          String(UUID().uuidString.prefix(4)))
        let payload: [String: Any] = ["ts": now.timeIntervalSince1970, "path": filePath]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        fm.createFile(atPath: path(name), contents: data,
                      attributes: [.posixPermissions: NSNumber(value: 0o600)])

        let all = entries()
        if all.count > Self.keep { all.prefix(all.count - Self.keep).forEach(remove) }
        return entries().first { $0.path == filePath }
    }

    public func remove(_ entry: Entry) { try? fm.removeItem(atPath: path(entry.name)) }

    public func clear() { entries().forEach(remove) }

    /// THE ICP'S FORMAT — Claude Code / Cursor already have filesystem access, so they need
    /// paths pointed at, not content pasted. `PathFormat.render` already renders this; reused,
    /// not reimplemented.
    public func mentionText() -> String? {
        let paths = entries().map(\.path)
        guard !paths.isEmpty else { return nil }
        return PathFormat.render(paths, style: .at, separator: .space)
    }

    /// THE CHAT-UI FORMAT `chute unpack` still serves. Byte-identical to `chute bundle` for the
    /// same files by construction — both call `ContextBundle.assemble` below, never a second
    /// formatter.
    public func bundleText() -> String? {
        let paths = entries().map(\.path)
        guard !paths.isEmpty else { return nil }
        return ContextBundle.assemble(paths).text
    }
}

/// ONE DEFINITION OF "THE BUNDLE", reused rather than copied — `chute bundle`'s `assembledBundle`
/// (`chute`'s `ContextCommands.swift`) and this basket both call this and only this, so they can
/// never drift into two different formats. The precise defect a previous commit already
/// collapsed out of `doctor --fix` once.
extension ContextBundle {
    public static func assemble(_ paths: [String], format: String = "xml")
        -> (text: String, files: [BundleFile], skipped: [String]) {
        let (files, skipped) = FileScan.bundleFiles(paths)
        let root = ProjectRoot.of(files.map(\.path))
        let text = format == "md" ? markdown(files, root: root) : xml(files, root: root)
        return (text, files, skipped)
    }
}
