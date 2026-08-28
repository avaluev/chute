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
        public let name: String       // "1787923488-a1b2.json"
        public let label: String      // what it was, in the words it was delivered under
        public let date: Date
        public let text: String

        /// One bounded line for a menu row. The LABEL, not the content: "src/auth · 8 files ·
        /// ~4.1k tokens" is what someone is looking for; the first sixty characters of an XML
        /// bundle is not.
        public var preview: String {
            let flat = label.replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return flat.count <= 60 ? flat : String(flat.prefix(59)) + "…"
        }
    }

    /// How many are kept. This holds real content — a bundle is a hundred kilobytes — in the
    /// user's home directory, so it forgets rather than grows.
    public static let keep = 10

    /// Anything larger is not recorded. A five-megabyte paste is not something anyone scrolls
    /// back to from a menu, and writing it on every copy is a cost with no matching benefit.
    public static let maxEntryBytes = 2 * 1024 * 1024

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
        // ORDERED BY THE RECORDED TIME, not by filename. The name starts with a millisecond
        // timestamp, which looks like time order until two copies land inside the same
        // millisecond — then the random tail that keeps them from colliding decides the order
        // instead, and the buffer hands back "third, first, second". `ts` is a Date, so it
        // separates them; the name breaks the remaining tie so the result is at least stable.
        let names = ((try? fm.contentsOfDirectory(atPath: directory)) ?? [])
            .filter { $0.hasSuffix(".json") }
        return names.compactMap { name in
            guard let data = fm.contents(atPath: path(name)),
                  let o = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let text = o["text"] as? String else { return nil }
            return Entry(name: name,
                         label: (o["label"] as? String) ?? text,
                         date: Date(timeIntervalSince1970: (o["ts"] as? Double) ?? 0),
                         text: text)
        }
        .sorted { ($0.date, $0.name) < ($1.date, $1.name) }
    }

    /// EVERYTHING CHUTE HANDS YOU IS REMEMBERED. No ritual, nothing to press, nothing to learn:
    /// you right-click or run a command, it copies something for you, and it is here afterwards.
    ///
    /// AND STILL NOTHING IS WATCHED. This records what this app WROTE to the clipboard at your
    /// request — it never reads the pasteboard, so it cannot contain a password you copied from
    /// a manager, a message from a chat window, or anything else you did not ask Chute for.
    /// That distinction is the whole reason this is not a clipboard-history feature.
    ///
    /// A REPLAY IS NOT A NEW COPY. Putting something back on the clipboard that is already in
    /// here does not record a second row. Without that, the feature destroyed itself by being
    /// used: clicking a Recent Copies row called `deliver`, which recorded a fresh entry under
    /// the HUD's confirmation wording — so ten clicks left ten rows reading "Copied" and evicted,
    /// via `keep`, the ten real things the list existed to hold. The same held for the CLI, where
    /// running `chute diff` twice filed the identical patch twice.
    ///
    /// Deduplicated on the TEXT, not the label: the text is the thing the user is collecting, and
    /// the same content handed over under two different confirmations is still one thing.
    public func record(_ text: String, label: String) {
        guard !text.isEmpty, text.utf8.count <= Self.maxEntryBytes else { return }
        guard !entries().contains(where: { $0.text == text }) else { return }
        try? fm.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let now = Date()
        // Timestamp then a random tail: two copies inside the same second must not collide, and
        // sorting by name has to stay sorting by time.
        let name = String(format: "%012.0f-%@.json", now.timeIntervalSince1970 * 1000,
                          String(UUID().uuidString.prefix(4)))
        let payload: [String: Any] = ["ts": now.timeIntervalSince1970,
                                      "label": label.isEmpty ? text : label,
                                      "text": text]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        try? data.write(to: URL(fileURLWithPath: path(name)))

        let all = entries()
        if all.count > Self.keep { all.prefix(all.count - Self.keep).forEach(remove) }
    }

    /// The explicit path, still there for `chute buf add` — something on the clipboard that
    /// Chute did not produce. The menu no longer offers it: an item you must remember to press
    /// AFTER copying is a ritual, and the moment you need it is the moment you have forgotten.
    @discardableResult
    public func add(_ text: String) -> Entry? {
        record(text, label: text)
        return entries().last
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
