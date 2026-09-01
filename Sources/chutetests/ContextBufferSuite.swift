import Foundation
import ChuteCore

func contextBufferSuite() {
    T.suite("ContextBuffer") {
        let dir = NSTemporaryDirectory() + "chute-buf-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let buf = ContextBuffer(directory: dir)

        // Real files on disk — a basket entry is a path now, and reading its content at flush
        // time (for the @mention and bundle formats below) needs something real to read.
        let filesDir = NSTemporaryDirectory() + "chute-buf-files-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: filesDir) }
        let fm = FileManager.default
        try? fm.createDirectory(atPath: filesDir + "/auth", withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: filesDir + "/lib", withIntermediateDirectories: true)
        let authIndex = filesDir + "/auth/index.ts"
        let libIndex = filesDir + "/lib/index.ts"
        let readme = filesDir + "/README.md"
        try? "export const a = 1;\n".write(toFile: authIndex, atomically: true, encoding: .utf8)
        try? "export const b = 2;\n".write(toFile: libIndex, atomically: true, encoding: .utf8)
        try? "# hello\n".write(toFile: readme, atomically: true, encoding: .utf8)

        T.eq(buf.entries().count, 0, "a basket that has never been used is empty, not an error")
        T.eq(buf.mentionText(), nil, "and there is nothing to render as @mentions")
        T.eq(buf.bundleText(), nil, "or as a bundle")

        buf.add(authIndex)
        buf.add(libIndex)
        buf.add(readme)
        T.eq(buf.entries().count, 3, "three added, three held")
        T.eq(buf.entries().map(\.path), [authIndex, libIndex, readme],
             "and they come back in the order they were added")

        // ── A PATH, NOT A BLOB ──────────────────────────────────────────────────────────────
        //
        // 2026-08-31, the ICP decision: an entry is a FILE PATH now. `PathFormat.render` already
        // renders @-mentions and is already tested — this asserts REUSE, not a second formatter.
        T.eq(buf.mentionText(), PathFormat.render([authIndex, libIndex, readme],
                                                   style: .at, separator: .space),
             "the @mention output is exactly what PathFormat already renders for these paths")

        // THE DRY ASSERTION THAT MATTERS. `chute bundle` assembles files through
        // `FileScan.bundleFiles` + `ProjectRoot.of` + `ContextBundle.xml`; this computes that same
        // sequence independently and checks the basket produces byte-identical output — so the
        // two can never quietly drift into two different bundle formats.
        let (expectedFiles, _) = FileScan.bundleFiles([authIndex, libIndex, readme])
        let expectedBundle = ContextBundle.xml(expectedFiles, root: ProjectRoot.of(expectedFiles.map(\.path)))
        T.eq(buf.bundleText(), expectedBundle,
             "the basket's bundle text is byte-identical to ContextBundle.xml over the same files")

        // ── DISAMBIGUATION IS THE WHOLE JOB ─────────────────────────────────────────────────
        //
        // Two `index.ts` in different folders must not read as the same row.
        let previews = buf.entries().map(\.preview)
        T.eq(previews.first ?? "", "auth/index.ts", "a row names its file and its folder")
        T.eq(previews.count > 1 ? previews[1] : "", "lib/index.ts",
             "and a same-named file in another folder is distinguishable")
        T.ok(Set(previews).count == previews.count, "no two rows are ever the same string")

        // ── A DEAD PATH IS SHOWN, NOT DROPPED ───────────────────────────────────────────────
        //
        // Rule 4: a refusal is not a zero. `entries()` must not silently filter a path that no
        // longer exists on disk — it must still be there, saying so.
        // TWO CONTRACTS, and this assertion used to conflate them. It said "a path that was never
        // on disk is still a held entry" — and that is precisely what let
        // `chute basket add /tmp/typo.ts` answer "→ added 1 — 1 in the basket" and exit 0.
        // Rule 4 is about `entries()`, which must never silently drop a row; it is not a licence
        // for `add()` to accept a path that does not exist. Split, 2026-09-02:
        buf.clear()
        let gone = filesDir + "/vanishes.ts"
        fm.createFile(atPath: gone, contents: Data("x".utf8))
        _ = buf.add(gone)
        try? fm.removeItem(atPath: gone)
        T.eq(buf.entries().count, 1, "a file that vanishes after it was added is still a held entry")
        T.ok(buf.entries().first?.preview.hasSuffix("— missing") == true, "and its row says it is gone")
        T.eq(buf.add(filesDir + "/never-existed.ts") == nil, true,
             "but a path that was NEVER on disk is refused at the door")
        T.eq(buf.entries().count, 1, "and does not become a row")

        // ── OLD-FORMAT AND MALFORMED FILES: IGNORED, NOT CRASHED ON ────────────────────────
        //
        // Before this move an entry was `{ts, label, text}`. No migration — four stale fixtures
        // are worth nothing — but `entries()` must not choke on one it finds sitting there.
        buf.clear()
        let oldFormat = (dir as NSString).appendingPathComponent("oldformat.json")
        let oldPayload = try! JSONSerialization.data(withJSONObject:
            ["ts": Date().timeIntervalSince1970, "label": "old", "text": "some content"])
        fm.createFile(atPath: oldFormat, contents: oldPayload)
        let garbage = (dir as NSString).appendingPathComponent("garbage.json")
        fm.createFile(atPath: garbage, contents: Data("not even json".utf8))
        T.noThrow("entries() does not crash on an old-format or malformed file") { _ = buf.entries() }
        T.eq(buf.entries().count, 0, "and neither file is treated as a valid basket entry")

        // ── DEDUPLICATED ON THE PATH ────────────────────────────────────────────────────────
        //
        // Adding the same file twice is not collecting a second thing.
        buf.clear()
        buf.add(authIndex)
        buf.add(authIndex)
        T.eq(buf.entries().count, 1, "adding the same path twice leaves one entry")

        // Removing one entry does not disturb the others, and a fresh add afterwards does not
        // collide with a survivor's name.
        buf.clear()
        buf.add(authIndex)
        buf.add(libIndex)
        buf.remove(buf.entries()[0])
        T.eq(buf.entries().map(\.path), [libIndex], "removing one leaves the other untouched")
        buf.add(readme)
        T.eq(buf.entries().map(\.path), [libIndex, readme], "and a new add does not overwrite it")

        buf.clear()
        T.eq(buf.entries().count, 0, "clear empties it")

        // ── BOUNDED ──────────────────────────────────────────────────────────────────────────
        //
        // A path costs nothing to store, but a basket that never forgets is a junk drawer, not
        // an active collection.
        // Real files, because `add` validates existence now. Twenty of them, deleted straight
        // after, so the cap is exercised without leaving litter in /tmp.
        let bounded = (0..<20).map { filesDir + "/bounded-\($0).txt" }
        for f in bounded { fm.createFile(atPath: f, contents: Data("x".utf8)) }
        for f in bounded { _ = buf.add(f) }
        for f in bounded { try? fm.removeItem(atPath: f) }
        T.eq(buf.entries().count, ContextBuffer.keep, "it keeps the last \(ContextBuffer.keep), not everything")

        // ── NOT WORLD-READABLE ──────────────────────────────────────────────────────────────
        //
        // Every sensitive path in this codebase locks itself down — ActionRequest 0700,
        // RequestInbox 0600, the env file 0600 — and this one must keep doing the same now that
        // it stores paths instead of text.
        let dirMode = (try? fm.attributesOfItem(atPath: dir)[.posixPermissions] as? NSNumber)??.intValue
        T.eq(dirMode, 0o700, "the basket directory is ours alone")
        if let first = buf.entries().first {
            let file = (dir as NSString).appendingPathComponent(first.name)
            let mode = (try? fm.attributesOfItem(atPath: file)[.posixPermissions] as? NSNumber)??.intValue
            T.eq(mode, 0o600, "and so is every file in it")
        } else {
            T.ok(false, "there is an entry to check the mode of")
        }

        // CHUTE_BUFFER_DIR IS A GUARD, NOT A COMMENT. It shipped saying "tests only" and enforcing
        // nothing — the CLI, the app and the Finder extension all read it, so anyone able to set
        // an environment variable could point the basket anywhere. Security review caught that a
        // comment is not a guard. Constrained to NSTemporaryDirectory(), which every `mktemp -d`
        // satisfies, so the tests keep working and the promise is now true.
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).resolvingSymlinksInPath().path
        T.ok(ContextBuffer.defaultDirectory == ContextBuffer.home
                || ContextBuffer.defaultDirectory.hasPrefix(tmp),
             "the basket is the real one, or somewhere under the temp directory — never elsewhere")
        T.ok(ContextBuffer.home.hasPrefix(NSHomeDirectory()),
             "and the real one is inside this user's home")
    
        // BOUNDARY VALIDATION, added 2026-09-02 after the acceptance run. A basket entry is a
        // PATH, so a file that vanishes AFTER being added is legitimately "— missing" at
        // hand-over — but a path that NEVER existed is a different thing, and
        // `chute basket add /tmp/typo.ts` used to answer "→ added 1 — 1 in the basket", exit 0.
        // ISOLATED, like every other buffer in this file. The first version of this block used a
        // bare `ContextBuffer()` and called `.clear()` on it — which is the OWNER'S REAL BASKET.
        // The handoff already carries this exact trap ("the basket tests cleared his real basket
        // until CHUTE_BUFFER_DIR was added") and it was walked into again anyway, so
        // `Scripts/check-untested-logic.sh --tests` now refuses a no-argument ContextBuffer
        // anywhere under Sources/chutetests.
        let ghostDir = NSTemporaryDirectory() + "chute-buf-ghost-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: ghostDir) }
        let ghostBuf = ContextBuffer(directory: ghostDir)
        T.eq(ghostBuf.add("/tmp/chute-no-such-file-\(UUID().uuidString).ts") == nil, true,
             "a path that does not exist is refused rather than stored")
        T.eq(ghostBuf.entries().count, 0, "and nothing lands in the basket")
        let realFile = NSTemporaryDirectory() + "chute-basket-real-\(UUID().uuidString).ts"
        FileManager.default.createFile(atPath: realFile, contents: Data("x".utf8))
        T.eq(ghostBuf.add(realFile) != nil, true, "a file that exists still goes in")
        // And once it is gone, the entry stays — that is the design — but the text is empty,
        // which is what `basket copy` now refuses to report as success.
        try? FileManager.default.removeItem(atPath: realFile)
        T.eq(ghostBuf.entries().count, 1, "the entry survives the file, by design")
        T.eq(ghostBuf.bundleText()?.isEmpty, true, "and yields no content to hand over")
}
}
