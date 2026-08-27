import Foundation
import ChuteCore

func actionRequestSuite() {
    T.suite("ActionRequest") {
        let root = NSTemporaryDirectory() + "chute-inbox-\(UInt32.random(in: 0...99999))"
        defer { try? FileManager.default.removeItem(atPath: root) }
        let now = Date(timeIntervalSince1970: 1_756_219_200)

        // Round trip.
        let req = ActionRequest(id: "copy-paths", dir: "/tmp/p", files: ["/a.ts", "/b.ts"], createdAt: now)
        T.noThrow("writes a request") { _ = try ActionInbox.write(req, root: root) }
        let pending = ActionInbox.drain(root: root, now: now.addingTimeInterval(1))
        T.eq(pending.count, 1, "one request is pending")
        T.eq(pending.first?.request, req, "it round-trips unchanged, selection included")

        // Two clicks in the same millisecond must not overwrite each other.
        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp/p", files: [], createdAt: now), root: root)
        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp/p", files: [], createdAt: now), root: root)
        T.eq(ActionInbox.drain(root: root, now: now.addingTimeInterval(1)).count, 3,
             "requests never collide — every click is its own file")

        // Stale and skewed requests are dropped, not carried out later.
        T.eq(ActionInbox.drain(root: root, now: now.addingTimeInterval(3600)).count, 0,
             "an hour-old click is not carried out on the next right-click")
        T.eq(ActionInbox.drain(root: root, now: now).count, 0, "and the stale files are cleaned up")

        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp/p", files: [], createdAt: now), root: root)
        T.eq(ActionInbox.drain(root: root, now: now.addingTimeInterval(-3600)).count, 0,
             "a request from the future is a clock skew, not a fresh click")

        // Garbage is discarded, never retried forever.
        let junk = (root as NSString).appendingPathComponent("junk.json")
        try? "not json".write(toFile: junk, atomically: true, encoding: .utf8)
        _ = ActionInbox.drain(root: root, now: now)
        T.ok(!FileManager.default.fileExists(atPath: junk), "an unparseable request is deleted, not retried")

        let unknown = (root as NSString).appendingPathComponent("unknown.json")
        try? #"{"id":"no-such-action","dir":"/tmp","ts":1756219200}"#
            .write(toFile: unknown, atomically: true, encoding: .utf8)
        T.eq(ActionInbox.drain(root: root, now: now.addingTimeInterval(1)).count, 0,
             "a request naming an action that does not exist is refused")

        T.eq(ActionInbox.drain(root: root + "-missing", now: now).count, 0,
             "a missing inbox is empty, not an error")

        // The inbox must live in the REAL home. Inside the sandboxed extension NSHomeDirectory()
        // is the container, and a request written there is one nobody ever reads.
        T.ok(ActionInbox.directory().hasPrefix("/Users/"), "the inbox path is anchored to the real home")
        T.ok(!ActionInbox.directory().contains("Containers"), "never the sandbox container")
    }
}
