import Foundation
import ChuteCore

func cmdDoctor(_ a: Args) {
    // --report builds something a user can paste into a public issue: the same checks, plus
    // versions and the extension's own load marker, redacted. It never repairs anything.
    if a.has("report") {
        let outcomes = Diagnostics.run(Diagnostics.liveEnv(endToEnd: true))
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let marker = (try? String(contentsOfFile:
            (NSHomeDirectory() as NSString).appendingPathComponent(".chute/extension-loaded.txt"),
            encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
        Out.line(SupportReport.build(
            outcomes: outcomes,
            version: ChuteVersion.current,
            osVersion: "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)",
            extras: ["build": Diagnostics.installedBuild()
                        ?? "not stamped — built before the stamp existed, or run from source",
                     "finder extension": marker ?? "never loaded",
                     "notifications": (try? String(contentsOfFile:
                        (NSHomeDirectory() as NSString).appendingPathComponent(".chute/notifications.txt"),
                        encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? "unknown"]))
        return
    }

    // WHICH BUILD IS ANSWERING. Nine checks can all pass on an app that is older than the fix the
    // user is asking about — that is exactly how "Recent Copies never works" survived a shipped
    // fix and a passing test for ninety minutes. One line, printed before any of them.
    if !a.has("json") {
        Out.info("chute \(ChuteVersion.current) · app build "
                 + (Diagnostics.installedBuild() ?? "not stamped — rebuild with ./Scripts/build-app.sh"))
    }

    var outcomes = Diagnostics.run(Diagnostics.liveEnv())

    if a.has("fix") {
        // Only checks that actually HAVE a repair. Counting every failure would promise repairs
        // for `terminal` and `end-to-end`, which have none — the same "plausible number answering
        // a different question" this command exists to stop telling.
        let toFix = outcomes.filter { !$0.passed }
            .compactMap { o in repair(o.check.id, dryRun: true).map { (id: o.check.id, what: $0) } }
        // NFR-05 — preview by default, fix only with --force. `--fix` is already an opt-in flag,
        // so a second one on top could read as nagging — but this is still the most destructive
        // thing in the product (Trashes a container, kills two processes), and consistency is the
        // entire point of this move: a convention with one exception is not a convention. Decided
        // 2026-08-29: `--fix` gets the same gate as the other four, no carve-out for being opt-in
        // already. Nothing to fix → nothing to gate: `applyFixes` below is a no-op on an empty
        // list, same as before this change.
        if !toFix.isEmpty {
            guard a.has("force") else {
                Out.info("dry run — --fix would attempt \(toFix.count) repair(s):")
                toFix.forEach { Out.line("  \($0.id): \($0.what)") }
                Out.info("→ re-run with --force to fix")
                return
            }
        }
        toFix.forEach { repair($0.id, dryRun: false) }
        // Never claim success without re-verifying. Reporting a fix that was not re-checked is
        // the failure mode this whole module exists to prevent.
        Out.info("→ re-running every check")
        outcomes = Diagnostics.run(Diagnostics.liveEnv())
    }

    let prerequisites = outcomes.filter { $0.check.id != "end-to-end" }
    let endToEnd = outcomes.first { $0.check.id == "end-to-end" }
    // ONLY A BLOCKER BLOCKS. `blocked` used to mean "any prerequisite failed", which was already
    // slightly wrong for `cli` and `terminal` and became actively harmful the moment `hooks`
    // joined them: hooks are unwired on most machines BY DESIGN, so the end-to-end proof — the
    // one check that runs a real command and reads the result back, and the only one that can
    // say the product works — would have been skipped on almost every install. Its probe writes
    // a temp file and round-trips the clipboard; it needs no Homebrew CLI, no terminal and no
    // hook. Skipping it over an optional note is the false all-clear wearing the other face.
    let blocked = prerequisites.contains { !$0.passed && $0.check.severity == .blocker }

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
    // THE EXIT CODE IS LOAD-BEARING. A failing `.note` (cli, terminal, hooks) prints above like
    // any other failure, but must never flip a script or CI run red — hooks in particular is
    // unwired on most machines by design, and a doctor that exits non-zero for that would make
    // every script reading this exit code fail on a perfectly working install.
    let blockerFailures = failures.filter { $0.check.severity == .blocker }
    if blockerFailures.isEmpty { exit(0) }
    exit(blockerFailures.contains { $0.check.id == "os" } ? 2 : 1)
}

/// ONE SWITCH, describing and doing. The preview arrived as a second switch mirroring this one,
/// "kept in sync by hand" — which is the same shape as the row that titled itself "New Scratch
/// Folder" and then toasted "Clean room ready.", and as the four hand-kept copies of the version
/// number. Two places for one truth drift, and here the drift would preview a repair that does
/// not happen, or hide one that does, for the most destructive command in the product.
///
/// Returns the one-line description, or nil when this check has no automatic fix at all — which
/// is also what keeps the preview from counting repairs it will not attempt.
@discardableResult
private func repair(_ id: String, dryRun: Bool) -> String? {
    let container = (NSHomeDirectory() as NSString)
        .appendingPathComponent("Library/Containers/dev.valuev.chute.finder")
    switch id {
    case "cli":
        // NOT FIXED FROM HERE ANY MORE. This used to symlink the bundled binary into
        // ~/.local/bin, which put `chute` on PATH twice at the same version — a collision
        // the app created and then diagnosed, offering to recreate it as the remedy.
        // Homebrew owns the CLI; installing it is a decision for the user's package manager,
        // not something an app writes into their home directory behind a --fix flag.
        if !dryRun { Out.info("→ the CLI comes from Homebrew: brew install avaluev/tap/chute") }
        return "print the Homebrew install command — no files touched"

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
        if !dryRun {
            let app = Diagnostics.resolvedAppPath(Bundle.main.bundlePath)
            _ = Shell.run("osascript", ["-e",
                "tell application \"Finder\" to delete POSIX file \"\(container)\""])
            _ = Shell.run("pluginkit", ["-r", app + "/Contents/PlugIns/ChuteFinder.appex"])
            _ = Shell.run("pkill", ["-x", "ChuteApp"])
            _ = Shell.run("open", [app])
            _ = Shell.run("pluginkit", ["-a", app + "/Contents/PlugIns/ChuteFinder.appex"])
            _ = Shell.run("pluginkit", ["-e", "use", "-i", "dev.valuev.chute.finder"])
            _ = Shell.run("killall", ["Finder"])
            Out.info("→ cleared the stale extension container and restarted Finder")
        }
        return "Trash \(container), then kill ChuteApp and Finder to reload the extension"

    case "ext-registered":
        if !dryRun {
            let appex = Bundle.main.bundlePath + "/Contents/PlugIns/ChuteFinder.appex"
            _ = Shell.run("pluginkit", ["-a", appex])
            Out.info("→ registered the Finder extension")
        }
        return "register the Finder extension with pluginkit"

    case "ext-enabled":
        if !dryRun {
            _ = Shell.run("pluginkit", ["-e", "use", "-i", "dev.valuev.chute.finder"])
            Out.info("→ asked macOS to enable the Finder extension")
        }
        return "ask macOS to enable the Finder extension"

    case "automation":
        if !dryRun {
            _ = Shell.run("osascript", ["-e", "tell application \"Finder\" to return 1"])
            Out.info("→ triggered the Automation prompt")
        }
        return "trigger the Automation permission prompt"

    default:
        // os, app-location, terminal and end-to-end have no safe automatic fix. hooks
        // deliberately has none either: Chute never writes to ~/.claude/settings.json.
        return nil
    }
}
