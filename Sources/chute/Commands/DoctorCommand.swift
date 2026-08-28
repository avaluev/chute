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
            // NOT FIXED FROM HERE ANY MORE. This used to symlink the bundled binary into
            // ~/.local/bin, which put `chute` on PATH twice at the same version — a collision
            // the app created and then diagnosed, offering to recreate it as the remedy.
            // Homebrew owns the CLI; installing it is a decision for the user's package manager,
            // not something an app writes into their home directory behind a --fix flag.
            Out.info("→ the CLI comes from Homebrew: brew install avaluev/tap/chute")
        case "ext-started":
            // A sandboxed extension's container pins the code identity that created it, so after
            // a rebuild macOS silently refuses to start the new one. The remedy is the sequence
            // Scripts/install.sh has always run, and it needs NO PASSWORD: Finder moves the
            // container to the Trash on request. The old advice was `sudo rm -rf`, which is a
            // root delete a customer cannot verify, for a fault the product caused.
            //
            // Order matters, and it was measured: drop the container, DEREGISTER (macOS will not
            // recreate a container for a registration it still holds), relaunch the host app —
            // which is what actually registers an appex — then restart Finder.
            let app = Diagnostics.resolvedAppPath(Bundle.main.bundlePath)
            let container = (NSHomeDirectory() as NSString)
                .appendingPathComponent("Library/Containers/dev.valuev.chute.finder")
            _ = Shell.run("osascript", ["-e",
                "tell application \"Finder\" to delete POSIX file \"\(container)\""])
            _ = Shell.run("pluginkit", ["-r", app + "/Contents/PlugIns/ChuteFinder.appex"])
            _ = Shell.run("pkill", ["-x", "ChuteApp"])
            _ = Shell.run("open", [app])
            _ = Shell.run("pluginkit", ["-a", app + "/Contents/PlugIns/ChuteFinder.appex"])
            _ = Shell.run("pluginkit", ["-e", "use", "-i", "dev.valuev.chute.finder"])
            _ = Shell.run("killall", ["Finder"])
            Out.info("→ cleared the stale extension container and restarted Finder")
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
