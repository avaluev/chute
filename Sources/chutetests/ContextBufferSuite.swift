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
    }
}
