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

        // ── THE MERGE, COMPUTED BUT NEVER WRITTEN ──────────────────────────────────────────
        //
        // `merged` returns the user's settings with Chute's four blocks APPENDED into whatever
        // arrays are already there. Chute still does not write ~/.claude/settings.json — the
        // founder's rule of 2026-08-27 stands — it prints, and the user's own shell does the
        // write. That is the difference between "here is some JSON, good luck" and one command.
        // A SETTINGS FILE WITH FOREIGN HOOKS AND NO CHUTE — the state every new customer is in,
        // and the only one that exercises the append. The `legacy` fixture above already carries
        // Chute's blocks on all four events, so `merged` skips every one of them and the append
        // is never reached: a test written against it passes whatever the append does. Proved by
        // perturbation 2026-09-03 — replacing `blocks.append(…)` with `blocks = […]`, the exact
        // bug this guards, left the suite green.
        let virgin = (dir as NSString).appendingPathComponent("virgin.json")
        try? """
        {"model":"opus","permissions":{"allow":["Bash"]},
         "hooks":{
           "Stop":[{"hooks":[{"type":"command","command":"other-tool-stop"}]}],
           "PermissionRequest":[{"matcher":"Bash","hooks":[{"type":"command","command":"other-perm"}]}],
           "UserPromptSubmit":[{"hooks":[{"type":"command","command":"other-prompt"}]}],
           "SessionStart":[{"hooks":[{"type":"command","command":"other-start"}]}],
           "PreCompact":[{"hooks":[{"type":"command","command":"other-precompact"}]}]}}
        """.write(toFile: virgin, atomically: true, encoding: .utf8)

        let vText = try! HookInstaller.merged(settingsPath: virgin)
        let vObj = (try! JSONSerialization.jsonObject(with: Data(vText.utf8))) as! [String: Any]
        func cmds(_ d: [String: Any]) -> [String] {
            (d["hooks"] as! [String: Any]).values.flatMap { blocks in
                ((blocks as? [[String: Any]]) ?? []).flatMap { b in
                    ((b["hooks"] as? [[String: Any]]) ?? []).compactMap { $0["command"] as? String }
                }
            }
        }
        let vForeign = cmds(vObj).filter { !HookInstaller.isChuteCommand($0) }
        T.eq(Set(vForeign), Set(["other-tool-stop", "other-perm", "other-prompt",
                                 "other-start", "other-precompact"]),
             "every foreign hook survives the merge — the whole reason this is not a paste")
        T.eq(cmds(vObj).filter { HookInstaller.isChuteCommand($0) }.count, 4,
             "and Chute's four are added")
        T.eq(entries(vObj, "Stop"), 2, "APPENDED beside the other tool's block, not over it")
        T.eq(HookInstaller.status(settingsPath: virgin).values.filter { $0 }.count, 0,
             "and the file on disk is untouched — merged() computes, it never writes")

        let mergedText = try! HookInstaller.merged(settingsPath: path)
        let mergedObj = (try! JSONSerialization.jsonObject(with: Data(mergedText.utf8))) as! [String: Any]
        let mergedHooks = mergedObj["hooks"] as! [String: Any]

        func commands(_ d: [String: Any]) -> [String] {
            (d["hooks"] as! [String: Any]).values.flatMap { blocks in
                ((blocks as? [[String: Any]]) ?? []).flatMap { b in
                    ((b["hooks"] as? [[String: Any]]) ?? []).compactMap { $0["command"] as? String }
                }
            }
        }
        let originalForeign = commands(load(path)).filter { !HookInstaller.isChuteCommand($0) }
        let mergedForeign  = commands(mergedObj).filter { !HookInstaller.isChuteCommand($0) }
        T.eq(Set(mergedForeign), Set(originalForeign),
             "NOT ONE foreign hook is lost — the whole reason this exists rather than a paste")
        T.eq(mergedHooks.count, (load(path)["hooks"] as! [String: Any]).count,
             "and no event disappears either")
        T.ok(mergedObj["permissions"] != nil && mergedObj["model"] != nil,
             "settings that have nothing to do with hooks survive untouched")
        T.eq(entries(mergedObj, "PreCompact"), 1, "an event Chute does not use is left alone")

        // Idempotent: the fixture already carries Chute's blocks, so a merge adds nothing.
        T.eq(entries(mergedObj, "Stop"), entries(load(path), "Stop"),
             "merging twice does not stack a second copy of Chute's block")

        // The command it prints has to be safe to paste. Never a redirect straight onto the
        // settings file — `> settings.json` truncates it BEFORE chute runs, so a failure there
        // leaves the user with an empty agent config.
        let applyCmd = HookInstaller.applyCommand(cli: "chute", settingsPath: "/tmp/s.json")
        T.no(applyCmd.contains("> /tmp/s.json"), "never redirects onto the settings file itself")
        T.ok(applyCmd.contains("mktemp"), "stages through a temp file")
        T.ok(applyCmd.contains("cp \"/tmp/s.json\" \"/tmp/s.json.bak-"), "backs up first, quoted")
        T.ok(applyCmd.contains("&&"), "chained so a failure stops the sequence")
        T.ok(applyCmd.contains("--settings \"/tmp/s.json\""),
             "names the file it rewrites rather than trusting a default")
        // A path with a space is the case an unquoted backup destination silently mangles.
        let spaced = HookInstaller.applyCommand(cli: "chute", settingsPath: "/a b/s.json")
        T.eq(spaced.components(separatedBy: "\"/a b/s.json\"").count - 1, 4,
             "all four occurrences of a spaced path are quoted (merged, cp, mv, status)")
        T.ok(spaced.contains("cp \"/a b/s.json\" \"/a b/s.json.bak-"),
             "including the backup destination, which is where an unquoted path loses the backup")

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
