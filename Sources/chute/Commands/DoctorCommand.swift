import Foundation
import ChuteCore

func cmdDoctor(_ a: Args) {
    var outcomes = Diagnostics.run(Diagnostics.liveEnv())

    if a.has("fix") {
        applyFixes(outcomes)
        // Never claim success without re-verifying. Reporting a fix that was not re-checked is
        // the failure mode this whole module exists to prevent.
        Out.info("→ re-running every check")
        outcomes = Diagnostics.run(Diagnostics.liveEnv())
    }

    let prerequisites = outcomes.filter { $0.check.id != "end-to-end" }
    let endToEnd = outcomes.first { $0.check.id == "end-to-end" }
    let blocked = prerequisites.contains { !$0.passed }

    if a.has("json") {
        let rows = outcomes.map { o -> [String: Any] in
            let skipped = (o.check.id == "end-to-end" && blocked)
            return ["id": o.check.id, "title": o.check.title,
                    "passed": skipped ? false : o.passed,
                    "skipped": skipped,
                    "detail": skipped ? "skipped — earlier checks failed" : o.detail,
                    "why": o.check.why, "fix": o.check.fix]
        }
        let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
    } else {
        for o in prerequisites {
            let mark = o.passed ? "✓" : "✗"
            let title = o.check.title.padding(toLength: 34, withPad: " ", startingAt: 0)
            Out.line("\(mark) \(title)\(o.detail)")
            if !o.passed {
                Out.line("    Why: \(o.check.why)")
                Out.line("    Fix: \(o.check.fix)")
            }
        }

        if blocked {
            Out.line("— end-to-end test skipped: fix the above first")
        } else if let e = endToEnd {
            let mark = e.passed ? "✓" : "✗"
            let title = e.check.title.padding(toLength: 34, withPad: " ", startingAt: 0)
            Out.line("\(mark) \(title)\(e.detail)")
            if !e.passed {
                Out.line("    Why: \(e.check.why)")
                Out.line("    Fix: \(e.check.fix)")
            }
        }

        let failed = prerequisites.filter { !$0.passed }.count
        let runCount = blocked ? prerequisites.count : outcomes.count
        Out.info(failed == 0
            ? "→ all \(runCount) checks passed"
            : "→ \(failed) of \(runCount) checks failed")
    }

    let failed = prerequisites.filter { !$0.passed }
    if failed.isEmpty && !blocked { exit(0) }
    exit(failed.contains { $0.check.id == "os" } ? 2 : 1)
}

private func applyFixes(_ outcomes: [CheckOutcome]) {
    for o in outcomes where !o.passed {
        switch o.check.id {
        case "cli":
            let target = (NSHomeDirectory() as NSString).appendingPathComponent(".local/bin")
            try? FileManager.default.createDirectory(atPath: target, withIntermediateDirectories: true)
            let src = Bundle.main.bundlePath + "/Contents/MacOS/chute"
            try? FileManager.default.createSymbolicLink(
                atPath: (target as NSString).appendingPathComponent("chute"), withDestinationPath: src)
            Out.info("→ linked chute into ~/.local/bin")
        case "ext-registered":
            let appex = Bundle.main.bundlePath + "/Contents/PlugIns/ChuteFinder.appex"
            _ = Shell.run("pluginkit", ["-a", appex])
            Out.info("→ registered the Finder extension")
        case "ext-enabled":
            _ = Shell.run("pluginkit", ["-e", "use", "-i", "dev.valuev.chute.finder"])
            Out.info("→ asked macOS to enable the Finder extension")
        case "automation":
            _ = Shell.run("osascript", ["-e", "tell application \"Finder\" to return 1"])
            Out.info("→ triggered the Automation prompt")
        case "hooks":
            do {
                let r = try HookInstaller.install(settingsPath:
                    (NSHomeDirectory() as NSString).appendingPathComponent(".claude/settings.json"))
                Out.info("→ wired hooks: \(r.changed.sorted().joined(separator: ", ")) · backup \(r.backupPath ?? "none")")
            } catch { Out.info("→ hooks not installed: \(error)") }
        default:
            break   // os, app-location, terminal and end-to-end have no safe automatic fix
        }
    }
}
