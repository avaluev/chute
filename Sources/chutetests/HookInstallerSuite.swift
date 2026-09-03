import Foundation
import ChuteCore

func hookInstallerSuite() {
    T.suite("HookInstaller") {
        let dir = NSTemporaryDirectory() + "chute-hooks-\(UInt32.random(in: 0...99999))"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let path = (dir as NSString).appendingPathComponent("settings.json")

        // A settings file as an EARLIER Chute version left it: the user's own hooks plus a
        // chute-marked block on each event. Uninstall must take exactly ours and nothing else.
        let chuteBlock = { (state: SessionState) -> String in
            let cmd = HookInstaller.command(for: state)
            let data = try! JSONSerialization.data(withJSONObject:
                ["hooks": [["type": "command", "command": cmd]]])
            return String(decoding: data, as: UTF8.self)
        }
        let legacy = """
        {"permissions":{"allow":["Bash"]},"model":"opus",
         "hooks":{
           "Stop":[{"hooks":[{"type":"command","command":"existing-plugin-command --flag"}]},
                   \(chuteBlock(.waiting))],
           "PermissionRequest":[{"matcher":"Bash","hooks":[{"type":"command","command":"another-one"}]},
                   \(chuteBlock(.blocked))],
           "UserPromptSubmit":[\(chuteBlock(.working))],
           "SessionStart":[\(chuteBlock(.working))],
           "PreCompact":[{"hooks":[{"type":"command","command":"untouched"}]}]}}
        """
        try? legacy.write(toFile: path, atomically: true, encoding: .utf8)
        func load(_ p: String) -> [String: Any] {
            (try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: p))))
                as? [String: Any] ?? [:]
        }
        func entries(_ d: [String: Any], _ event: String) -> Int {
            ((d["hooks"] as? [String: Any])?[event] as? [Any])?.count ?? 0
        }

        // THE SNIPPET IS A COMPLETE `"hooks"` OBJECT, so a user who pastes it OVER their own
        // `hooks` key loses every hook another tool put there. Found on the founder's own machine
        // 2026-09-03: 11 commands across 12 events, none of them Chute's, one careless paste from
        // gone. `foreignCommandCount` is what lets the menu and the CLI say so before it happens.
        T.eq(HookInstaller.foreignCommandCount(settingsPath: path), 3,
             "counts the three non-Chute commands and none of its own")
        T.eq(HookInstaller.foreignCommandCount(settingsPath: dir + "/nope.json"), 0,
             "a settings file that is not there costs nothing and warns about nothing")

        // Status is read-only and sees the legacy wiring.
        T.eq(HookInstaller.status(settingsPath: path).values.filter { $0 }.count, 4,
             "status reports four wired events on a legacy install")

        // THE CONTRACT — decided 2026-08-27: Chute NEVER writes to the user's Claude Code
        // configuration. There is no install() any more; the snippet is generated for the
        // user's own hand.
        let snippet = HookInstaller.manualSnippet()
        let parsed = (try? JSONSerialization.jsonObject(with: Data(snippet.utf8))) as? [String: Any]
        T.ok(parsed != nil, "the manual snippet is valid JSON")
        let snippetHooks = (parsed?["hooks"] as? [String: Any]) ?? [:]
        T.eq(snippetHooks.keys.sorted(),
             ["PermissionRequest", "SessionStart", "Stop", "UserPromptSubmit"],
             "the snippet carries all four events")
        T.ok(snippet.contains(HookInstaller.marker), "snippet commands carry the marker")

        // Uninstall removes exactly ours.
        T.noThrow("uninstall succeeds") { _ = try HookInstaller.uninstall(settingsPath: path) }
        let d = load(path)
        T.eq(entries(d, "Stop"), 1, "our Stop entry removed, theirs kept")
        T.eq(entries(d, "PermissionRequest"), 1, "our PermissionRequest entry removed, theirs kept")
        T.eq(entries(d, "PreCompact"), 1, "an unrelated event is untouched")
        T.ok(((try? String(contentsOfFile: path, encoding: .utf8)) ?? "")
                .contains("existing-plugin-command --flag"), "the user's own command survives")
        T.ok(d["permissions"] != nil && d["model"] != nil, "every unrelated top-level key survives")
        T.eq(HookInstaller.status(settingsPath: path).values.filter { $0 }.count, 0,
             "status reports nothing wired afterwards")
        let permAfter = ((d["hooks"] as? [String: Any])?["PermissionRequest"] as? [[String: Any]]) ?? []
        T.eq((permAfter.first?["matcher"] as? String) ?? "", "Bash",
             "the matcher key survives uninstall untouched")
        // Events that held ONLY our block are dropped, not left as [] husks.
        T.ok((d["hooks"] as? [String: Any])?["UserPromptSubmit"] == nil,
             "an event we emptied is dropped, not left as a [] husk")

        // A backup exists from the uninstall that changed something.
        let backups = ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? [])
            .filter { $0.contains("chute-backup") }
        T.eq(backups.count, 1, "one timestamped backup was written")

        // Idempotence: a second uninstall finds nothing, writes nothing, backs up nothing.
        let before = (try? String(contentsOfFile: path, encoding: .utf8)) ?? "x"
        T.noThrow("second uninstall succeeds") {
            let r = try HookInstaller.uninstall(settingsPath: path)
            T.eq(r.changed, [], "a second uninstall removes nothing")
            T.ok(r.backupPath == nil, "and leaves no backup behind")
        }
        T.eq((try? String(contentsOfFile: path, encoding: .utf8)) ?? "y", before,
             "a no-op uninstall leaves the file byte-identical")

        // Malformed input changes nothing.
        let broken = (dir as NSString).appendingPathComponent("broken.json")
        try? "{ this is not json".write(toFile: broken, atomically: true, encoding: .utf8)
        T.throwsError("refuses to touch an unparseable file") {
            _ = try HookInstaller.uninstall(settingsPath: broken)
        }
        T.eq((try? String(contentsOfFile: broken, encoding: .utf8)) ?? "", "{ this is not json",
             "the unparseable file is byte-identical afterwards")

        // A non-conforming shape must abort, not be overwritten — and leave no backup.
        let oddHooks = (dir as NSString).appendingPathComponent("odd-hooks.json")
        try? #"{"model":"opus","hooks":"not-an-object"}"#.write(toFile: oddHooks, atomically: true, encoding: .utf8)
        T.throwsError("refuses when `hooks` is not an object") { _ = try HookInstaller.uninstall(settingsPath: oddHooks) }
        T.eq((try? String(contentsOfFile: oddHooks, encoding: .utf8)) ?? "",
             #"{"model":"opus","hooks":"not-an-object"}"#, "the odd file is byte-identical afterwards")
        let oddTrace = ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? [])
            .filter { $0.hasPrefix("odd-hooks.json.chute-backup-") }
        T.ok(oddTrace.isEmpty, "a refused uninstall leaves no backup file behind")

        let oddEvent = (dir as NSString).appendingPathComponent("odd-event.json")
        try? #"{"hooks":{"Stop":"not-an-array"}}"#.write(toFile: oddEvent, atomically: true, encoding: .utf8)
        T.throwsError("refuses when an event value is not an array") { _ = try HookInstaller.uninstall(settingsPath: oddEvent) }

        // A user command that merely mentions the marker is not ours.
        T.no(HookInstaller.isChuteCommand("echo reading chute-session-state files"),
             "a command merely mentioning the marker is not treated as ours")
        T.ok(HookInstaller.isChuteCommand(HookInstaller.command(for: .waiting)),
             "our own command is recognised as ours")
        T.no(HookInstaller.isChuteCommand("# chute-session-state-mine\necho hi"),
             "a marker-prefixed but different command is not ours")

        // Pin the shape of the generated command so the next edit has a guard.
        let cmd = HookInstaller.command(for: .blocked)
        T.ok(cmd.hasPrefix("# chute-session-state\n"), "command opens with the marker line")
        T.ok(cmd.contains("case \"$T\" in"), "command carries the tty whitelist")
        T.ok(cmd.contains("exit 0"), "command always exits 0 so it cannot break the user's agent")
        T.ok(cmd.contains("printf '{}"), "command emits {} on stdout")

        // The snippet is deterministic — the docs can quote it verbatim.
        T.eq(HookInstaller.manualSnippet(), HookInstaller.manualSnippet(),
             "two snippets are byte-identical")

        // AN OLD SNIPPET IS INSTALLED, NOT BROKEN. The command gained $CLAUDE_CODE_SESSION_ID on
        // 2026-08-28. Anyone who pasted the earlier one still gets working state badges — they
        // just get no model, no cost and no resume command, and nothing on screen explains why.
        // `hooks status` has to say so, or the answer to "why is the model missing" is a support
        // conversation instead of a line of output.
        let old = "# chute-session-state\nS=\"$HOME/.chute/sessions\"; printf '{}'; exit 0"
        T.ok(HookInstaller.isChuteCommand(old), "an older snippet is still recognised as ours")
        T.no(HookInstaller.isCurrent(old), "but it is not the current one")
        T.ok(HookInstaller.isCurrent(HookInstaller.command(for: .waiting)),
             "and what we generate today is")
    }
}
