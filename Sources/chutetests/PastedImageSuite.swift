import Foundation
import ChuteCore

func pastedImageSuite() {
    T.suite("PastedImage") {
        // macOS's own format, to the character: a pasted image should sit next to real
        // screenshots in a folder listing, not announce that a different tool made it.
        let when = Date(timeIntervalSince1970: 1_787_000_000)   // fixed instant
        let name = PastedImage.defaultName(at: when, locale: Locale(identifier: "en_US_POSIX"))
        T.ok(name.hasPrefix("Screenshot "), "named like a screenshot")
        T.ok(name.hasSuffix(".png"), "and it is a PNG")
        T.ok(name.contains(" at "), "with macOS's ' at ' between date and time")
        T.ok(name.range(of: #"\d{4}-\d{2}-\d{2} at \d{2}\.\d{2}\.\d{2}"#, options: .regularExpression) != nil,
             "full timestamp to the second: \(name)")

        // Two pastes in the same second must not collide.
        let dir = NSTemporaryDirectory() + "chute-paste-\(UInt32.random(in: 0...99999))"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let first = (try? NameDerive.writeUniquely(dir: dir, base: "Shot", ext: "png", data: Data("x".utf8))) ?? ""
        let second = (try? NameDerive.writeUniquely(dir: dir, base: "Shot", ext: "png", data: Data("y".utf8))) ?? ""
        T.ok(!first.isEmpty && first != second, "a second paste in the same second gets its own name")

        // The write itself is the collision check (O_EXCL) — two concurrent invocations can both
        // pass an exists() probe, and the second must land on -2, never on top of the first.
        let w1 = try? NameDerive.writeUniquely(dir: dir, base: "Race", ext: "png", data: Data("a".utf8))
        let w2 = try? NameDerive.writeUniquely(dir: dir, base: "Race", ext: "png", data: Data("b".utf8))
        T.eq(w1.map { ($0 as NSString).lastPathComponent }, "Race.png", "first exclusive write takes the plain name")
        T.eq(w2.map { ($0 as NSString).lastPathComponent }, "Race-2.png", "second lands beside it, not on it")
        T.eq(w1.flatMap { try? String(contentsOfFile: $0, encoding: .utf8) }, "a",
             "and the first file's bytes are untouched")

        // The rename is tracked by INODE, because tracking by name is precisely what breaks when
        // the thing you are waiting for is a rename.
        let inode = PastedImage.inode(of: first)
        T.ok(inode != nil, "the file has an identity")
        T.eq(PastedImage.path(ofInode: inode!, in: dir), first, "found under its original name")

        let renamed = (dir as NSString).appendingPathComponent("a better name.png")
        try? FileManager.default.moveItem(atPath: first, toPath: renamed)
        T.eq(PastedImage.path(ofInode: inode!, in: dir), renamed,
             "and found again after the user renames it")

        try? FileManager.default.removeItem(atPath: renamed)
        T.ok(PastedImage.path(ofInode: inode!, in: dir) == nil,
             "a file that left the folder is gone, not guessed at")

        // Clipboard ownership: we may replace only what we put there. The user renames for as
        // long as they like, and may copy something else meanwhile — taking that would be theft.
        T.ok(PastedImage.mayReplaceClipboard(current: "/tmp/a.png", weWrote: "/tmp/a.png"),
             "our own path may be replaced")
        T.ok(PastedImage.mayReplaceClipboard(current: "/tmp/a.png\n", weWrote: "/tmp/a.png"),
             "trailing whitespace does not count as a difference")
        T.ok(!PastedImage.mayReplaceClipboard(current: "something the user copied", weWrote: "/tmp/a.png"),
             "anything else is left alone")
        T.ok(!PastedImage.mayReplaceClipboard(current: "", weWrote: "/tmp/a.png"),
             "an emptied clipboard is not ours either")
    }
}
