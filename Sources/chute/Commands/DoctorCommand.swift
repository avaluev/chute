import Foundation
import ChuteCore

func cmdDoctor(_ a: Args) {
    // --report builds something a user can paste into a public issue: the same checks, plus
    // versions and the extension's own load marker, redacted. It never repairs anything.
    if a.has("report") {
        let outcomes = Diagnostics.run(Diagnostics.liveEnv())
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let marker = (try? String(contentsOfFile:
            (NSHomeDirectory() as NSString).appendingPathComponent(".chute/extension-loaded.txt"),
            encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
        Out.line(SupportReport.build(
            outcomes: outcomes,
            version: ChuteVersion.current,
            osVersion: "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)",
            extras: ["finder extension": marker ?? "never loaded",
                     "notifications": (try? String(contentsOfFile:
                        (NSHomeDirectory() as NSString).appendingPathComponent(".chute/notifications.txt"),
                        encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? "unknown"]))
        return
    }

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

        // A skipped check is neither a pass nor a failure, so it must not be counted. But a check that
        // RAN and failed must reach BOTH the summary and the exit code — a script reading only the
        // exit code must never be told the product is healthy while the output says otherwise.
        let ran: [CheckOutcome] = blocked ? prerequisites : outcomes
        let failures = ran.filter { !$0.passed }
        Out.info(failures.isEmpty
            ? "→ all \(ran.count) checks passed"
            : "→ \(failures.count) of \(ran.count) checks failed")
    }

    let ran: [CheckOutcome] = blocked ? prerequisites : outcomes
    let failures = ran.filter { !$0.passed }
    if failures.isEmpty && !blocked { exit(0) }
    exit(failures.contains { $0.check.id == "os" } ? 2 : 1)
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
        default:
            break   // os, app-location, terminal and end-to-end have no safe automatic fix
            // hooks deliberately have no --fix: Chute never writes to ~/.claude/settings.json.
        }
    }
}
