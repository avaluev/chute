import Foundation
import ChuteCore

/// `.notRunning` means "nothing to show" — Terminal simply isn't open, not an error.
/// Any other failure (almost always Automation permission denied) is actionable, so it
/// gets a message naming the fix rather than a silent empty list that reads as broken.
/// `hadError` lets callers suppress "no terminal sessions" when the empty list is really an
/// unreported problem the caller already printed — otherwise the two messages contradict
/// each other (permission denied, immediately followed by "nothing to see here").
func discoverSessions() -> (sessions: [Session], hadError: Bool) {
    let hooks = HookState.readAll()
    do {
        let sessions = try TerminalAppAdapter().discover(hooks: hooks, now: Date())
            .sorted { ($0.state, $0.project) < ($1.state, $1.project) }
        return (sessions, false)
    } catch TerminalError.notRunning {
        return ([], false)
    } catch {
        Out.info("chute: \(error) — grant Terminal access under System Settings → "
            + "Privacy & Security → Automation, then run `chute sessions` again")
        return ([], true)
    }
}

func cmdSessions(_ a: Args) {
    let (sessions, hadError) = discoverSessions()
    guard !sessions.isEmpty else {
        if !hadError { Out.info("no terminal sessions") }
        return
    }

    if a.has("json") {
        let jsonSamples = SystemVitals.sample()
        let rows = sessions.map { s -> [String: Any] in
            let load = SystemVitals.load(forTTY: s.tty, in: jsonSamples)
            return ["key": s.key, "project": s.project, "title": s.title, "tty": s.tty,
                    "state": HookState.stateName(s.state), "isAgent": s.isAgent,
                    "windowID": s.windowID, "tabIndex": s.tabIndex,
                    "color": SessionColor.hex(forProject: s.project),
                    "cpuPercent": load.cpuPercent, "memoryBytes": load.residentBytes,
                    "processes": load.processes]
        }
        let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
        return
    }

    func pad(_ s: String, _ n: Int) -> String {
        s.count >= n ? String(s.prefix(n)) : s + String(repeating: " ", count: n - s.count)
    }
    // One `ps` for all sessions, not one per row: the list is drawn while you wait for it.
    let samples = SystemVitals.sample()
    for s in sessions {
        let load = SystemVitals.load(forTTY: s.tty, in: samples)
        Out.line(pad(s.state.label, 9) + pad(s.project, 18) + pad(s.title, 34)
                 + " " + pad(s.tty, 9) + load.label)
    }
    let needs = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
    Out.info("→ \(sessions.count) session(s), \(needs) need you · "
             + SystemVitals.machineLine(samples: samples,
                                        cores: ProcessInfo.processInfo.activeProcessorCount,
                                        thermal: ProcessInfo.processInfo.thermalState,
                                        batteryCelsius: SystemVitals.temperature()))
}

func cmdFocus(_ a: Args) {
    guard let target = a.positional.first else {
        Out.fail("usage: chute focus <key|project>   (see `chute sessions`)")
    }
    let (sessions, _) = discoverSessions()

    // An ambiguous project name must ASK, not guess. Sending the user to an arbitrary one of four
    // studylock windows is worse than refusing: they cannot tell that it happened.
    let byProject = sessions.enumerated().filter { $0.element.project == target }
    if byProject.count > 1 {
        // All three parts go to stderr: this is an error path, and splitting it across streams
        // makes the instruction print BEFORE the options it refers to (stderr is unbuffered,
        // stdout is line-buffered).
        Out.info("\(byProject.count) sessions match '\(target)' — focus one by number:")
        for (index, session) in byProject {
            Out.info("  \(index + 1). \(session.title)  (\(session.tty))")
        }
        Out.fail("ambiguous — re-run with a number, e.g. `chute focus \(byProject[0].offset + 1)`")
    }

    guard let hit = sessions.first(where: { $0.key == target })
            ?? sessions.first(where: { $0.project == target })
            ?? Int(target).flatMap({ n in n >= 1 && n <= sessions.count ? sessions[n - 1] : nil })
    else { Out.fail("no session matching '\(target)'") }

    do { try TerminalAppAdapter().focus(hit) }
    catch { Out.fail("\(error)") }
    Out.info("→ focused \(hit.project) (\(hit.tty))")
}

func cmdHooks(_ a: Args) {
    let path = a.value("settings", or: (NSHomeDirectory() as NSString)
        .appendingPathComponent(".claude/settings.json"))
    switch a.positional.first ?? "status" {
    case "install", "snippet":
        // Chute never edits another tool's settings. The user's hand does the writing.
        Out.line(HookInstaller.manualSnippet())
        Out.info("→ Chute does not modify \(path) — merge the \"hooks\" object above into it "
                 + "yourself (or via Claude Code's /hooks menu), then `chute hooks status`.")
    case "uninstall":
        do {
            let r = try HookInstaller.uninstall(settingsPath: path)
            guard !r.changed.isEmpty else { Out.info("→ nothing of Chute's in \(path)"); break }
            Out.info("→ backup: \(r.backupPath ?? "none")")
            Out.line("removed: \(r.changed.sorted().joined(separator: ", "))")
        } catch { Out.fail("\(error)") }
    default:
        for (event, wired) in HookInstaller.status(settingsPath: path).sorted(by: { $0.key < $1.key }) {
            Out.line("\(wired ? "✓" : "·") \(event)")
        }
        Out.info("→ settings: \(path)")
    }
}
