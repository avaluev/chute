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
        let first = NameDerive.uniquePath(dir: dir, base: "Shot", ext: "png") {
            FileManager.default.fileExists(atPath: $0)
        }
        try? Data("x".utf8).write(to: URL(fileURLWithPath: first))
        let second = NameDerive.uniquePath(dir: dir, base: "Shot", ext: "png") {
            FileManager.default.fileExists(atPath: $0)
        }
        T.ok(first != second, "a second paste in the same second gets its own name")

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
