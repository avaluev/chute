import Foundation
import ChuteCore

func actionRequestSuite() {
    T.suite("ActionRequest") {
        let root = NSTemporaryDirectory() + "chute-inbox-\(UInt32.random(in: 0...99999))"
        defer { try? FileManager.default.removeItem(atPath: root) }
        let now = Date(timeIntervalSince1970: 1_756_219_200)

        // Round trip.
        let req = ActionRequest(id: "copy-paths", dir: "/tmp", files: ["/a.ts", "/b.ts"], createdAt: now)
        T.noThrow("writes a request") { _ = try ActionInbox.write(req, root: root) }
        let pending = ActionInbox.drain(root: root, now: now.addingTimeInterval(1))
        T.eq(pending.count, 1, "one request is pending")
        T.eq(pending.first?.request, req, "it round-trips unchanged, selection included")

        // Two clicks in the same millisecond must not overwrite each other.
        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp", files: [], createdAt: now), root: root)
        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp", files: [], createdAt: now), root: root)
        T.eq(ActionInbox.drain(root: root, now: now.addingTimeInterval(1)).count, 3,
             "requests never collide — every click is its own file")

        // Stale and skewed requests are dropped, not carried out later.
        T.eq(ActionInbox.drain(root: root, now: now.addingTimeInterval(3600)).count, 0,
             "an hour-old click is not carried out on the next right-click")
        T.eq(ActionInbox.drain(root: root, now: now).count, 0, "and the stale files are cleaned up")

        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp", files: [], createdAt: now), root: root)
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

        // SECURITY. The inbox is a privilege boundary: an unsandboxed app executes whatever lands
        // here, on behalf of a SANDBOXED extension. Everything below is about not executing
        // something the user did not ask for.
        let secure = NSTemporaryDirectory() + "chute-inbox-sec-\(UInt32.random(in: 0...99999))"
        defer { try? FileManager.default.removeItem(atPath: secure) }
        _ = try? ActionInbox.write(ActionRequest(id: "copy-paths", dir: "/tmp", files: [], createdAt: now),
                                   root: secure)
        let mode = (try? FileManager.default.attributesOfItem(atPath: secure))?[.posixPermissions] as? NSNumber
        T.eq(mode?.int16Value, 0o700, "the inbox is owner-only — nobody else can queue work")

        // A world-writable request is one anybody could have replaced between write and read.
        let planted = (secure as NSString).appendingPathComponent("planted.json")
        try? #"{"id":"terminal","dir":"/tmp","ts":\#(now.timeIntervalSince1970)}"#
            .write(toFile: planted, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o666)],
                                               ofItemAtPath: planted)
        T.ok(!ActionInbox.isTrustworthy(planted), "a group/other-writable request is not trusted")
        T.eq(ActionInbox.drain(root: secure, now: now.addingTimeInterval(1))
                .filter { $0.request.id == "terminal" }.count, 0,
             "and it is never carried out")
        T.ok(!FileManager.default.fileExists(atPath: planted), "it is removed rather than left to retry")

        // A directory, or a file owned by someone else, is not a request either.
        let asDir = (secure as NSString).appendingPathComponent("notafile.json")
        try? FileManager.default.createDirectory(atPath: asDir, withIntermediateDirectories: true)
        T.ok(!ActionInbox.isTrustworthy(asDir), "a directory is not a request")
        T.ok(!ActionInbox.isTrustworthy((secure as NSString).appendingPathComponent("ghost.json")),
             "and neither is a path that does not exist")
        T.ok(!ActionInbox.isTrustworthy("/tmp/x", attributes: [
                .type: FileAttributeType.typeRegular,
                .ownerAccountID: NSNumber(value: getuid() &+ 1),
                .posixPermissions: NSNumber(value: 0o600)]),
             "a request owned by another account is refused")

        // The command runs against `dir`. Relative paths would resolve against wherever the app
        // happens to be, and a path that is not a directory is a malformed request.
        T.ok(ActionInbox.parse(Data(#"{"id":"copy-paths","dir":"relative/path","ts":1}"#.utf8)) == nil,
             "a relative dir is refused")
        T.ok(ActionInbox.parse(Data(#"{"id":"copy-paths","dir":"/no/such/place","ts":1}"#.utf8)) == nil,
             "a dir that is not a directory is refused")
        let mixed = ActionInbox.parse(Data(#"{"id":"copy-paths","dir":"/tmp","files":["/tmp/a","relative"],"ts":1}"#.utf8))
        T.eq(mixed?.files, ["/tmp/a"], "relative file paths are dropped, not resolved against a guess")

        // ── WHAT A FINDER CLICK MEANS ─────────────────────────────────────────────────────
        //
        // Four questions that used to be answered inside `ChuteFinderSync.run`, in a target no
        // test can link — including three sentences the user reads.
        let all = ChuteActions.all
        let selectionTag = all.firstIndex { $0.scope == .selection }!
        let folderTag = all.firstIndex { $0.scope == .folder }!
        func plan(_ tag: Int, _ selection: [String], _ folder: String?) -> ActionRequest.Dispatch {
            ActionRequest.plan(tag: tag, selection: selection, folder: folder, now: now)
        }

        T.eq(plan(-1, [], "/tmp"), .ignore, "a negative tag addresses no action")
        T.eq(plan(all.count, [], "/tmp"), .ignore,
             "and neither does one past the end — a menu built by a build that is gone")
        T.ok(plan(all.count - 1, ["/tmp/a"], "/tmp").sending != nil, "the last tag is still valid")

        T.eq(plan(selectionTag, [], "/tmp").refusal?.message, "Nothing is selected.",
             "an action that works on a selection says so when there is none")
        T.eq(plan(selectionTag, [], "/tmp").refusal?.action.id, all[selectionTag].id,
             "and the refusal names the action, so the banner has a subtitle")
        T.eq(plan(folderTag, [], "/tmp").sending?.request.id, all[folderTag].id,
             "a folder action needs no selection — that refusal is scoped, not universal")

        T.eq(plan(selectionTag, ["/tmp/a"], nil).refusal?.message,
             "Could not tell which folder this is.",
             "not 'no folder': the user is looking at one, we failed to read which")
        T.ok(plan(folderTag, [], nil).refusal != nil, "and a folder action cannot proceed either")

        let sent = plan(selectionTag, ["/tmp/a", "/tmp/b"], "/tmp")
        T.eq(sent.sending?.request,
             ActionRequest(id: all[selectionTag].id, dir: "/tmp", files: ["/tmp/a", "/tmp/b"],
                           createdAt: now),
             "the request carries the folder and the whole selection")
        T.eq(sent.sending?.action.id, all[selectionTag].id,
             "and the action alongside it — the caller never looks it up a second time")
        T.eq(plan(folderTag, ["/tmp/a"], "/tmp").sending?.request.files, ["/tmp/a"],
             "a folder action still carries the selection: clean on three selected files means those three")

        T.ok(plan(selectionTag, [], "/tmp").sending == nil, "a refusal sends nothing")
        T.ok(sent.refusal == nil, "and a send refuses nothing")
    }
}
