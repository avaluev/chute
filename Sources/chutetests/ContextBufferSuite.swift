import Foundation
import ChuteCore

func contextBufferSuite() {
    T.suite("ContextBuffer") {
        let dir = NSTemporaryDirectory() + "chute-buf-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let buf = ContextBuffer(directory: dir)

        T.eq(buf.entries().count, 0, "a buffer that has never been used is empty, not an error")
        T.eq(buf.flushText(), nil, "and flushing it yields nothing")

        buf.add("first")
        buf.add("second")
        buf.add("third")
        T.eq(buf.entries().count, 3, "three added, three held")
        T.eq(buf.entries().map(\.text), ["first", "second", "third"],
             "and they come back in the order they were copied")

        // THE OVERWRITE. Names were "%03d" of the CURRENT COUNT + 1, so removing one entry made
        // the next add reuse a name that was still in use: with 001/002/003 held and 002 removed,
        // count is 2 and the next entry writes 003 — silently destroying it. The buffer exists so
        // that copying four things does not lose the first one.
        buf.remove(buf.entries()[1])
        T.eq(buf.entries().count, 2, "one removed")
        buf.add("fourth")
        T.eq(buf.entries().map(\.text), ["first", "third", "fourth"],
             "and the new entry does not overwrite a surviving one")

        let flushed = buf.flushText()
        T.ok(flushed?.contains("--- context 1 ---\nfirst") == true, "flush numbers the pieces")
        T.ok(flushed?.contains("fourth") == true, "and includes the last one")
        T.eq(buf.entries().count, 3, "flushText does NOT empty the buffer — clearing is separate")

        buf.clear()
        T.eq(buf.entries().count, 0, "clear empties it")

        // A preview is for a menu row: one line, bounded, and it must not be the whole file.
        buf.add("a line\nand another line that goes on and on and on and on and on and on and on")
        let p = buf.entries()[0].preview
        T.no(p.contains("\n"), "a preview is one line")
        T.ok(p.count <= 60, "and short enough for a menu row: \(p.count)")

        // ── ZERO LEARNING CURVE ─────────────────────────────────────────────────────────────
        //
        // The first design made you press "Add Clipboard to Buffer" AFTER copying something.
        // That is a ritual you have to know about, remember, and perform at the one moment you
        // are least likely to be thinking about it — and if you forget, the thing you wanted is
        // already gone. Owner's verdict, 2026-08-28: not comprehensible.
        //
        // So Chute records what CHUTE ITSELF hands you. Right-click, bundle, copy paths, copy a
        // tree — each one already puts something on your clipboard at your request, and each one
        // is now also remembered. Nothing to learn, nothing to press, and still nothing watching
        // the pasteboard: it can only ever contain output this app produced when you asked it to.
        buf.clear()
        buf.record("<file path=…>", label: "src/auth · 2 files · ~176 tokens")
        buf.record("/a/b.ts\n/a/c.ts", label: "2 full paths")
        let recent = buf.entries()
        T.eq(recent.count, 2, "what Chute copied for you is remembered")
        T.eq(recent.last?.label, "2 full paths", "with the label it was delivered under")
        T.ok(recent.last!.date.timeIntervalSinceNow > -5, "and when")

        // BOUNDED. This holds real content — a bundle is a hundred kilobytes — and it lives in
        // the user's home directory. It keeps the last few and forgets the rest, so it can never
        // become a thing that quietly grows forever.
        for i in 0..<20 { buf.record("body \(i)", label: "entry \(i)") }
        T.eq(buf.entries().count, ContextBuffer.keep, "it keeps the last \(ContextBuffer.keep), not everything")
        T.eq(buf.entries().last?.label, "entry 19", "and the newest survives")
        T.no(buf.entries().contains { $0.label == "entry 0" }, "while the oldest is dropped")

        // Nothing enormous. A 5 MB paste is not a thing anyone scrolls back to from a menu, and
        // writing it to disk on every copy is a cost with no matching benefit.
        buf.clear()
        buf.record(String(repeating: "x", count: ContextBuffer.maxEntryBytes + 1), label: "huge")
        T.eq(buf.entries().count, 0, "an oversized entry is not recorded at all")

        // A label is for a menu row, so it is never allowed to be missing: an untitled row tells
        // the reader nothing and they have to copy it to find out what it was.
        buf.clear()
        buf.record("some text", label: "")
        T.eq(buf.entries().first?.label, "some text", "an empty label falls back to the content")

        // ── USING THE LIST MUST NOT DESTROY THE LIST ────────────────────────────────────────
        //
        // Owner's report, 2026-08-28: "Recent Copies — it is a shit hardcode. It never works."
        // It was both, and one caused the other. Clicking a row called AppDelegate.deliver, which
        // recorded the replay as a NEW entry under the HUD's confirmation wording. So the list
        // filled with identical rows reading "Copied", and because `keep` is 10, each of those
        // rows evicted one of the real things the list existed to hold. Ten clicks emptied it of
        // everything worth keeping and left ten copies of the same verb.
        //
        // A replay is not a new copy. Deduplicated on the TEXT — the content is the thing being
        // collected, and the same content handed over under two confirmations is still one thing.
        buf.clear()
        buf.record("the patch", label: "Diff · what the agent changed")
        buf.record("the patch", label: "Copied")          // ← clicking the row in Recent Copies
        buf.record("the patch", label: "Copied")
        T.eq(buf.entries().count, 1, "putting a held entry back on the clipboard files nothing new")
        T.eq(buf.entries().first?.label, "Diff · what the agent changed",
             "and the row keeps the words it was delivered under, not the confirmation's")

        // The eviction that followed from it, stated as the thing a user would notice: ten real
        // entries, then ten replays, and everything real is still there.
        buf.clear()
        for i in 0..<ContextBuffer.keep { buf.record("body \(i)", label: "real \(i)") }
        for i in 0..<ContextBuffer.keep { buf.record("body \(i)", label: "Copied") }
        T.eq(buf.entries().count, ContextBuffer.keep, "replaying every row adds no rows")
        T.no(buf.entries().contains { $0.label == "Copied" }, "and none of them is a bare 'Copied'")
        T.eq(buf.entries().first?.label, "real 0", "the oldest real entry was never evicted")

        // Genuinely different content is still recorded — the dedupe must not become a mute.
        buf.record("something else", label: "new thing")
        T.ok(buf.entries().contains { $0.label == "new thing" }, "a new copy is still recorded")

        // ── NOT WORLD-READABLE ──────────────────────────────────────────────────────────────
        //
        // Security review, 2026-08-28: these were landing at 755/644 under the standard umask,
        // readable by every local account on the machine. What is in here is a git diff, a secret
        // gist URL from `chute gist`, or whatever `chute buf add` was pointed at. Every other
        // sensitive path in this codebase already restricts its mode — ActionRequest 0700,
        // RequestInbox 0600, the env file 0600 — and this one was simply missed.
        let fm2 = FileManager.default
        let dirMode = (try? fm2.attributesOfItem(atPath: dir)[.posixPermissions] as? NSNumber)??.intValue
        T.eq(dirMode, 0o700, "the buffer directory is ours alone")
        if let first = buf.entries().first {
            let file = (dir as NSString).appendingPathComponent(first.name)
            let mode = (try? fm2.attributesOfItem(atPath: file)[.posixPermissions] as? NSNumber)??.intValue
            T.eq(mode, 0o600, "and so is every file in it")
        } else {
            T.ok(false, "there is an entry to check the mode of")
        }
    }
}
