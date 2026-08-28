import Foundation

/// The context buffer — JTBD 22, "the files I need are in four different folders and the clipboard
/// holds one thing".
///
/// ── WHY THIS IS NOT CLIPBOARD HISTORY ───────────────────────────────────────────────────────
///
/// Nothing here watches the pasteboard. There is no `changeCount` poll, no timer, no background
/// observer, and nothing is captured that the user did not explicitly hand over by running
/// `chute buf add` or picking the menu item. That is a deliberate product decision, not an
/// unfinished one: a passive clipboard history is a permission story, a trust story and a support
/// burden — it silently records passwords, licence keys and private messages — and it is not
/// needed for the job people actually have, which is "I am collecting four things and I do not
/// want the fourth copy to destroy the first".
///
/// Extracted from `cmdBuf` so the menu bar and the CLI read the same store. The menu is a second
/// SURFACE onto this, never a second implementation.
public struct ContextBuffer: Sendable {
    public struct Entry: Sendable, Equatable {
        public let name: String      // "001.txt"
        public let text: String

        /// One bounded line, for a menu row. Never the whole thing: an entry can be a whole file.
        public var preview: String {
            let flat = text.replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return flat.count <= 60 ? flat : String(flat.prefix(59)) + "…"
        }
    }

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
        let names = ((try? fm.contentsOfDirectory(atPath: directory)) ?? [])
            .filter { $0.hasSuffix(".txt") }
            .sorted()
        return names.map { Entry(name: $0, text: (try? String(contentsOfFile: path($0), encoding: .utf8)) ?? "") }
    }

    /// Names are the HIGHEST EXISTING INDEX plus one, not the count plus one.
    ///
    /// Counting was a silent overwrite: with 001, 002 and 003 held and 002 removed, the count is 2
    /// and the next add writes 003 — destroying an entry the user was in the middle of collecting.
    /// The one thing this feature exists to prevent is losing a copy.
    @discardableResult
    public func add(_ text: String) -> Entry? {
        guard !text.isEmpty else { return nil }
        try? fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let highest = entries().compactMap { Int($0.name.prefix(3)) }.max() ?? 0
        let name = String(format: "%03d.txt", highest + 1)
        guard (try? text.write(toFile: path(name), atomically: true, encoding: .utf8)) != nil
        else { return nil }
        return Entry(name: name, text: text)
    }

    public func remove(_ entry: Entry) { try? fm.removeItem(atPath: path(entry.name)) }

    public func clear() { entries().forEach(remove) }

    /// Everything, in order, labelled — the paste that makes the collecting worth it.
    /// It does NOT empty the buffer: throwing away the user's collection is a separate decision
    /// from reading it, and the CLI's `--keep` flag proves that was always two operations.
    public func flushText() -> String? {
        let all = entries()
        guard !all.isEmpty else { return nil }
        return all.enumerated()
            .map { "--- context \($0.offset + 1) ---\n\($0.element.text)" }
            .joined(separator: "\n\n")
    }
}
