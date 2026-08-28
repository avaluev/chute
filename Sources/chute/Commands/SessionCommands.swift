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
            // Anything the paid menu bar can show, the free CLI can print. That is the open-core
            // promise, and it is also where discoverability lives for the ⌥ commands.
            let t = s.sessionID.flatMap { AgentTranscript.read(sessionID: $0) }
            var row: [String: Any] = [
                "key": s.key, "project": s.project, "title": s.title, "tty": s.tty,
                "state": HookState.stateName(s.state), "isAgent": s.isAgent,
                "windowID": s.windowID, "tabIndex": s.tabIndex,
                "color": SessionColor.hex(forProject: s.project),
                "cpuPercent": load.cpuPercent, "memoryBytes": load.residentBytes,
                "processes": load.processes]
            // Absent rather than null: a consumer that checks for the key gets a straight answer,
            // and every one of these is genuinely unknown when the hook has not been updated.
            if let a = s.agent { row["agent"] = a }
            if let c = s.cwd { row["cwd"] = c }
            if let id = s.sessionID { row["sessionId"] = id }
            if let m = t?.model { row["model"] = m }
            if let e = t?.effort { row["effort"] = e }
            if let v = t?.version { row["agentVersion"] = v }
            if let b = t?.branch { row["gitBranch"] = b }
            if let t { row["outputTokens"] = t.outputTokens; row["cacheReadTokens"] = t.cacheReadTokens }
            return row
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
        let detail = SessionPhrasing.detail(agent: s.agent,
                                            transcript: s.sessionID.flatMap { AgentTranscript.read(sessionID: $0) })
        Out.line(pad(s.state.label, 9) + pad(s.project, 18) + pad(detail, 34)
                 + " " + pad(s.tty, 9) + load.label)
    }
    let needs = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
    // The machine summary that used to close this line is gone — see the note in SystemVitals.
    // The count is the fact worth printing; "using 0.4 of 16 cores · battery at 31 °C" was not.
    Out.info("→ \(sessions.count) session(s), \(needs) need you")
}

/// `chute resume [key|project|N]` — the command that picks a conversation up somewhere else.
///
/// The menu bar's ⌥ items and this print the same string from the same place (ResumeCommand), so
/// the paid surface and the free one cannot drift. It is the free half of "make a session
/// portable": the app finds the session for you, the CLI is where you learn the commands exist.
func cmdResume(_ a: Args) {
    let (sessions, _) = discoverSessions()
    let target = a.positional.first

    // No argument: the one session that is waiting for you, if exactly one is.
    let candidates = sessions.filter { $0.sessionID != nil }
    guard !candidates.isEmpty else {
        Out.fail("""
        no session carries an id yet.
          Chute learns it from the hook snippet, which has to be pasted into your own
          Claude Code settings — run `chute hooks snippet` and follow it. Until then the
          menu can tell you a session is waiting, but not which conversation it is.
        """)
    }

    let hit: Session?
    if let target {
        hit = candidates.first { $0.key == target }
            ?? candidates.first { $0.project == target }
            ?? Int(target).flatMap { n in n >= 1 && n <= candidates.count ? candidates[n - 1] : nil }
    } else {
        let waiting = candidates.filter { $0.state == .blocked || $0.state == .waiting }
        if waiting.count == 1 { hit = waiting[0] }
        else if candidates.count == 1 { hit = candidates[0] }
        else {
            Out.info("\(candidates.count) sessions can be resumed — name one:")
            for (i, s) in candidates.enumerated() {
                Out.info("  \(i + 1). \(s.project)  \(SessionPhrasing.detail(agent: s.agent, transcript: nil))  (\(s.tty))")
            }
            Out.fail("ambiguous — re-run with a number, e.g. `chute resume 1`")
        }
    }

    guard let s = hit, let id = s.sessionID else {
        Out.fail("no session matches '\(target ?? "")' — see `chute sessions`")
    }

    let command: String?
    if a.has("tmux") {
        command = ResumeCommand.tmux(project: s.project, cwd: s.cwd, agent: s.agent, sessionID: id)
        if command == nil, Shell.which("tmux") == nil { Out.info("note: tmux is not installed") }
    } else {
        command = ResumeCommand.resume(agent: s.agent, sessionID: id)
    }

    guard let command else {
        Out.fail("""
        no resume command is known for \(s.agent.map(SessionPhrasing.agentLabel) ?? "this session").
          Only Claude Code's resume syntax is implemented. Guessing at another agent's would put a
          command on your clipboard that fails when you run it. The session id is \(id).
        """)
    }

    // tmux CONTINUES a session, it does not move one: macOS cannot transplant a running process
    // onto a new tty. The old window keeps running until you close it.
    Out.deliver(command, a, badge: a.has("tmux") ? "the old window keeps running" : nil,
                label: a.has("tmux") ? "Continue \(s.project) in tmux" : "Resume \(s.project)")
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
        let outdated = Set(HookInstaller.outdatedEvents(settingsPath: path))
        for (event, wired) in HookInstaller.status(settingsPath: path).sorted(by: { $0.key < $1.key }) {
            let mark = !wired ? "·" : (outdated.contains(event) ? "!" : "✓")
            Out.line("\(mark) \(event)")
        }
        Out.info("→ settings: \(path)")
        // An older snippet is installed, not broken: the badges and the waiting times work. What
        // it cannot do is say WHICH conversation a session is, so the model, the cost and the
        // resume command are all missing — and nothing on screen would otherwise explain why.
        if !outdated.isEmpty {
            Out.info("""
            → \(outdated.count) hook(s) are an older version of the snippet.
              They still report state, so the badge and the waiting times are correct — but they
              do not record the session id, so the menu cannot show the model, the cost, or
              `chute resume`. Run `chute hooks snippet` and paste it again to fix that.
            """)
        }
    }
}
