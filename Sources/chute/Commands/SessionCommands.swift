import Foundation
import ChuteCore

/// `.notRunning` means "nothing to show" — Terminal simply isn't open, not an error.
/// Any other failure (almost always Automation permission denied) is actionable, so it
/// gets a message naming the fix rather than a silent empty list that reads as broken.
func discoverSessions() -> [Session] {
    let hooks = HookState.readAll()
    do {
        return try TerminalAppAdapter().discover(hooks: hooks, now: Date())
            .sorted { ($0.state, $0.project) < ($1.state, $1.project) }
    } catch TerminalError.notRunning {
        return []
    } catch {
        Out.info("chute: \(error) — grant Terminal access under System Settings → "
            + "Privacy & Security → Automation, then run `chute sessions` again")
        return []
    }
}

func cmdSessions(_ a: Args) {
    let sessions = discoverSessions()
    guard !sessions.isEmpty else { Out.info("no terminal sessions"); return }

    if a.has("json") {
        let rows = sessions.map { s -> [String: Any] in
            ["key": s.key, "project": s.project, "title": s.title, "tty": s.tty,
             "state": HookState.stateName(s.state), "isAgent": s.isAgent,
             "windowID": s.windowID, "tabIndex": s.tabIndex,
             "color": SessionColor.hex(forProject: s.project)]
        }
        let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted])
        Out.line(String(decoding: data ?? Data("[]".utf8), as: UTF8.self))
        return
    }

    func pad(_ s: String, _ n: Int) -> String {
        s.count >= n ? String(s.prefix(n)) : s + String(repeating: " ", count: n - s.count)
    }
    for s in sessions {
        Out.line(pad(s.state.label, 9) + pad(s.project, 18) + pad(s.title, 40) + s.tty)
    }
    let needs = sessions.filter { $0.state == .blocked || $0.state == .waiting }.count
    Out.info("→ \(sessions.count) session(s), \(needs) need you")
}

func cmdFocus(_ a: Args) {
    guard let target = a.positional.first else {
        Out.fail("usage: chute focus <key|project>   (see `chute sessions`)")
    }
    let sessions = discoverSessions()
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
    case "install":
        do {
            let r = try HookInstaller.install(settingsPath: path)
            Out.info("→ backup: \(r.backupPath ?? "none")")
            Out.line("wired: \(r.changed.sorted().joined(separator: ", "))")
            if !r.skipped.isEmpty {
                Out.line("already present: \(r.skipped.sorted().joined(separator: ", "))")
            }
        } catch { Out.fail("\(error)") }
    case "uninstall":
        do {
            let r = try HookInstaller.uninstall(settingsPath: path)
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
