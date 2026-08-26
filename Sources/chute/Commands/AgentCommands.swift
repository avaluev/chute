import Foundation
import ChuteCore

/// Real YOLO flags, verified against the installed CLIs.
let agentFlags = [
    "claude": "--dangerously-skip-permissions",
    "codex":  "--dangerously-bypass-approvals-and-sandbox",
    "gemini": "--yolo",
]

let terminalApps = ["Ghostty", "iTerm", "Warp", "Terminal"]
let editorApps = ["Cursor", "Visual Studio Code", "Zed"]

func installedApp(_ candidates: [String]) -> String? {
    candidates.first { name in
        FileManager.default.fileExists(atPath: "/Applications/\(name).app")
            || FileManager.default.fileExists(atPath: "\(NSHomeDirectory())/Applications/\(name).app")
    }
}

/// Runs `command` in a terminal at `dir`. Terminal.app and iTerm accept a command directly;
/// anything else is opened at the folder with the command printed for the user.
func launchTerminal(dir: String, command: String?) {
    let app = installedApp(terminalApps) ?? "Terminal"
    let full = command.map { "cd \(PathFormat.shellQuote(dir)) && \($0)" }
        ?? "cd \(PathFormat.shellQuote(dir))"

    switch app {
    case "Terminal":
        let escaped = full.replacingOccurrences(of: "\\", with: "\\\\")
                          .replacingOccurrences(of: "\"", with: "\\\"")
        Shell.launch("osascript", ["-e", "tell application \"Terminal\" to do script \"\(escaped)\"",
                                   "-e", "tell application \"Terminal\" to activate"])
    case "iTerm":
        let escaped = full.replacingOccurrences(of: "\\", with: "\\\\")
                          .replacingOccurrences(of: "\"", with: "\\\"")
        Shell.launch("osascript", ["-e", """
            tell application "iTerm"
              activate
              set w to (create window with default profile)
              tell current session of w to write text "\(escaped)"
            end tell
            """])
    default:
        Shell.launch("open", ["-a", app, dir])
        if let command { Out.info("→ \(app) does not accept a command; run: \(command)") }
    }
}

// MARK: - FR-07 open here

func cmdOpen(_ a: Args) {
    let dir = a.paths(defaultToCWD: true)[0]
    let target = FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent
    switch a.value("with", or: "terminal") {
    case "editor":
        guard let app = installedApp(editorApps) else { Out.fail("no supported editor found (Cursor, VS Code, Zed)") }
        Shell.launch("open", ["-a", app, target])
        Out.info("→ opened in \(app)")
    default:
        launchTerminal(dir: target, command: nil)
        Out.info("→ opened terminal at \(target)")
    }
}

// MARK: - FR-08 / FR-21 agent sandbox

func cmdSandbox(_ a: Args) {
    let agent = a.value("agent", or: "claude")
    guard let flag = agentFlags[agent] else {
        Out.fail("unknown agent '\(agent)' — known: \(agentFlags.keys.sorted().joined(separator: ", "))")
    }
    guard Shell.which(agent) != nil else { Out.fail("\(agent) is not on PATH") }
    let command = agent + (a.has("yolo") ? " " + flag : "")

    // FR-21 — one agent per selected folder.
    if a.has("each") {
        let dirs = a.paths().filter { FileScan.isDirectory($0) }
        guard !dirs.isEmpty else { Out.fail("select folders to broadcast into") }
        for d in dirs {
            launchTerminal(dir: d, command: command)
            Out.line("launched \(agent) in \(d)")
        }
        return
    }

    let parent = FileScan.absolute(a.value("dir", or: FileManager.default.currentDirectoryPath))
    let name = a.positional.first.map { NameDerive.slugify($0) } ?? NameDerive.fallbackName()
    let path = (parent as NSString).appendingPathComponent(name)

    if FileManager.default.fileExists(atPath: path) {
        Out.info("folder exists — launching in place")
    } else {
        do { try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true) }
        catch { Out.fail("cannot create \(path): \(error.localizedDescription)") }
        _ = Shell.run("git", ["init", "-q"], cwd: path)
        for rule in ["claude", "gitignore"] {
            if let file = Templates.fileName(for: rule), let body = Templates.body(for: rule, project: name) {
                try? body.write(toFile: (path as NSString).appendingPathComponent(file),
                                atomically: true, encoding: .utf8)
            }
        }
        try? "# \(name)\n".write(toFile: (path as NSString).appendingPathComponent("README.md"),
                                 atomically: true, encoding: .utf8)
    }
    if !a.has("no-launch") { launchTerminal(dir: path, command: command) }
    Out.line(path)
    Out.info("→ \(agent)\(a.has("yolo") ? " (yolo)" : "") in \(path)")
}

// MARK: - FR-15 zombie ports

func cmdPorts(_ a: Args) {
    if let port = a.optional("kill").flatMap({ Int($0) }) {
        let pids = LocalServers.kill(port: port)
        guard !pids.isEmpty else { Out.info("nothing is listening on \(port)"); return }
        Out.info("→ killed \(pids.count) process(es) on port \(port)")
        return
    }
    let servers = LocalServers.discover()
    guard !servers.isEmpty else { Out.info("nothing is listening"); return }

    func pad(_ s: String, _ n: Int) -> String {
        s.count >= n ? s : s + String(repeating: " ", count: n - s.count)
    }
    Out.line(pad("PORT", 8) + pad("WHAT", 12) + pad("PROJECT", 22) + pad("PID", 8) + "REACHABLE FROM")
    for s in servers {
        Out.line(pad(String(s.port), 8) + pad(s.kind, 12) + pad(s.project ?? "—", 22)
                 + pad(String(s.pid), 8) + (s.loopbackOnly ? "this Mac only" : "your network"))
    }
    Out.info("→ \(servers.count) listening · open one with http://localhost:<port> · free one with `chute ports --kill <port>`")
}

// MARK: - FR-24 .env injection (Keychain only)

func cmdEnv(_ a: Args) {
    guard a.positional.first == "inject" else {
        Out.fail("usage: chute env inject [dir] [--keys A,B]\n" +
                 "  store a key first:  security add-generic-password -s chute:OPENAI_API_KEY -a chute -w")
    }
    let dir = FileScan.absolute(a.positional.count > 1 ? a.positional[1] : FileManager.default.currentDirectoryPath)
    let envPath = (dir as NSString).appendingPathComponent(".env")

    // NFR-07 — refuse to create a file that git would track.
    let ignore = (try? String(contentsOfFile: (dir as NSString).appendingPathComponent(".gitignore"), encoding: .utf8)) ?? ""
    guard ignore.split(separator: "\n").contains(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix(".env") }) else {
        Out.fail(".env is not gitignored in \(dir) — add `.env` to .gitignore first (refusing to create a trackable secret file)")
    }

    let keys = a.value("keys", or: "ANTHROPIC_API_KEY,OPENAI_API_KEY,GEMINI_API_KEY,GROQ_API_KEY")
        .split(separator: ",").map(String.init)
    var lines: [String] = []
    var found: [String] = []
    for key in keys {
        let r = Shell.run("security", ["find-generic-password", "-s", "chute:\(key)", "-w"])
        let value = r.out.trimmingCharacters(in: .whitespacesAndNewlines)
        guard r.ok, !value.isEmpty else { continue }
        lines.append("\(key)=\(value)")
        found.append(key)                      // names only — never the value
    }
    guard !lines.isEmpty else {
        Out.fail("no keys in the Keychain. Store one with:\n" +
                 "  security add-generic-password -s chute:OPENAI_API_KEY -a chute -w")
    }
    let existing = (try? String(contentsOfFile: envPath, encoding: .utf8)) ?? ""
    let merged = existing.isEmpty ? lines.joined(separator: "\n") + "\n"
                                  : existing + "\n" + lines.joined(separator: "\n") + "\n"
    do { try merged.write(toFile: envPath, atomically: true, encoding: .utf8) }
    catch { Out.fail("cannot write .env: \(error.localizedDescription)") }
    try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: envPath)
    Out.line(envPath)
    Out.info("→ injected: \(found.joined(separator: ", "))")   // NFR-07: names, not values
}

// MARK: - FR-17 / FR-18 prompts

func cmdPrompt(_ a: Args) {
    let which = a.positional.first ?? ""
    switch which {
    case "decompose":
        var body = Templates.decomposePrompt
        if a.positional.count > 1, let text = FileScan.readText(FileScan.absolute(a.positional[1])) {
            body += "\n\n" + text
        } else {
            let clip = Clipboard.read()
            if !clip.isEmpty { body += "\n\n" + clip }
        }
        Out.deliver(body, a, badge: "decomposition prompt")
    case "ponytail":
        Out.deliver(Templates.ponytailPrompt, a, badge: "anti-bloat prompt")
    default:
        Out.fail("usage: chute prompt decompose|ponytail")
    }
}
