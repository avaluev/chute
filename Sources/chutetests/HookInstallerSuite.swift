import Foundation
import ChuteCore

func hookInstallerSuite() {
    T.suite("HookInstaller") {
        let dir = NSTemporaryDirectory() + "chute-hooks-\(UInt32.random(in: 0...99999))"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let path = (dir as NSString).appendingPathComponent("settings.json")

        let original = """
        {"permissions":{"allow":["Bash"]},"model":"opus","statusLine":{"type":"command"},
         "hooks":{
           "Stop":[{"hooks":[{"type":"command","command":"existing-plugin-command --flag"}]}],
           "PermissionRequest":[{"hooks":[{"type":"command","command":"another-one"}]}],
           "UserPromptSubmit":[{"hooks":[{"type":"command","command":"third"}]}],
           "SessionStart":[{"hooks":[{"type":"command","command":"fourth"}]}],
           "PreCompact":[{"hooks":[{"type":"command","command":"untouched"}]}]}}
        """
        func reset() { try? original.write(toFile: path, atomically: true, encoding: .utf8) }
        func load() -> [String: Any] {
            (try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))))
                as? [String: Any] ?? [:]
        }
        func entries(_ d: [String: Any], _ event: String) -> Int {
            ((d["hooks"] as? [String: Any])?[event] as? [Any])?.count ?? 0
        }

        reset()
        T.noThrow("install succeeds") { _ = try HookInstaller.install(settingsPath: path) }
        var d = load()

        T.eq(entries(d, "Stop"), 2, "appended to Stop, original entry kept")
        T.eq(entries(d, "PermissionRequest"), 2, "appended to PermissionRequest")
        T.eq(entries(d, "UserPromptSubmit"), 2, "appended to UserPromptSubmit")
        T.eq(entries(d, "SessionStart"), 2, "appended to SessionStart")
        T.eq(entries(d, "PreCompact"), 1, "an unrelated event is untouched")
        T.ok(d["permissions"] != nil && d["model"] != nil && d["statusLine"] != nil,
             "every unrelated top-level key survives")

        let text = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
        T.ok(text.contains("existing-plugin-command --flag"), "the pre-existing command is intact")
        T.ok(text.contains(HookInstaller.marker), "our entries carry the marker")

        // Idempotence.
        T.noThrow("second install succeeds") { _ = try HookInstaller.install(settingsPath: path) }
        d = load()
        T.eq(entries(d, "Stop"), 2, "installing twice adds nothing")

        // A backup exists.
        let backups = ((try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? [])
            .filter { $0.contains("chute-backup") }
        T.ok(!backups.isEmpty, "a timestamped backup was written")

        // Status.
        T.eq(HookInstaller.status(settingsPath: path).values.filter { $0 }.count, 4,
             "status reports four wired events")

        // Uninstall restores exactly.
        T.noThrow("uninstall succeeds") { _ = try HookInstaller.uninstall(settingsPath: path) }
        d = load()
        T.eq(entries(d, "Stop"), 1, "our entry removed")
        T.ok(((try? String(contentsOfFile: path, encoding: .utf8)) ?? "")
                .contains("existing-plugin-command --flag"), "theirs still there after uninstall")
        T.eq(HookInstaller.status(settingsPath: path).values.filter { $0 }.count, 0,
             "status reports nothing wired")

        // Malformed input changes nothing.
        let broken = (dir as NSString).appendingPathComponent("broken.json")
        try? "{ this is not json".write(toFile: broken, atomically: true, encoding: .utf8)
        T.throwsError("refuses to touch an unparseable file") {
            _ = try HookInstaller.install(settingsPath: broken)
        }
        T.eq((try? String(contentsOfFile: broken, encoding: .utf8)) ?? "", "{ this is not json",
             "the unparseable file is byte-identical afterwards")

        // A settings file with no hooks key at all.
        let bare = (dir as NSString).appendingPathComponent("bare.json")
        try? #"{"model":"opus"}"#.write(toFile: bare, atomically: true, encoding: .utf8)
        T.noThrow("handles a file with no hooks key") { _ = try HookInstaller.install(settingsPath: bare) }
        T.eq(entries(load2(bare), "Stop"), 1, "creates the event array when absent")
    }
}

private func load2(_ path: String) -> [String: Any] {
    (try? JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))))
        as? [String: Any] ?? [:]
}
