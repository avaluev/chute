import Foundation

/// Something listening on a TCP port on this machine.
public struct LocalServer: Sendable, Equatable {
    public let port: Int
    public let command: String        // "node", "postgres", "com.docke"
    public let pid: Int
    public let loopbackOnly: Bool     // 127.0.0.1 / ::1 rather than every interface
    public var project: String?       // the folder the process is running in, when we can tell

    public init(port: Int, command: String, pid: Int, loopbackOnly: Bool, project: String? = nil) {
        self.port = port; self.command = command; self.pid = pid
        self.loopbackOnly = loopbackOnly; self.project = project
    }

    /// What the process most likely is, in words. Unknown commands keep their own name rather
    /// than being labelled with a guess.
    public var kind: String {
        LocalServers.kinds.first { command.lowercased().hasPrefix($0.key) }?.value ?? command
    }

    public var url: String { "http://localhost:\(port)" }

    /// One line for a menu: ":3000 · node · studylock".
    public var label: String {
        let tail = project.map { " · \($0)" } ?? ""
        return ":\(port) · \(kind)\(tail)"
    }
}

public enum LocalServers {
    static let kinds: [String: String] = [
        "node": "node", "next": "next", "vite": "vite", "bun": "bun", "deno": "deno",
        "python": "python", "uvicorn": "uvicorn", "gunicorn": "gunicorn", "flask": "flask",
        "ruby": "ruby", "rails": "rails", "php": "php", "java": "java", "dotnet": "dotnet",
        "postgres": "postgres", "mysqld": "mysql", "redis-ser": "redis", "mongod": "mongodb",
        "com.docke": "docker", "docker": "docker", "ollama": "ollama", "caddy": "caddy",
        "nginx": "nginx", "esbuild": "esbuild", "webpack": "webpack", "rustc": "rust", "cargo": "rust",
    ]

    /// macOS's own background listeners. They are not what "what is running locally" means to
    /// anyone, and a menu full of them is a menu nobody reads.
    static let systemNoise: Set<String> = [
        "rapportd", "ControlCe", "sharingd", "AirPlayXP", "identityse", "remoted",
        "launchd", "netbiosd", "cupsd", "Mail", "iTunes", "Music", "Spotify",
    ]

    /// Ports the kernel hands out for outgoing-style listeners; never something you typed into a
    /// browser, and they change on every restart.
    static let ephemeralFloor = 32768

    /// Parse `lsof -nP -iTCP -sTCP:LISTEN`. Pure, so the parsing is testable without lsof.
    /// Columns: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME — NAME is `*:8080`,
    /// `127.0.0.1:3000` or `[::1]:5432`, with `(LISTEN)` after it.
    public static func parse(lsof output: String) -> [LocalServer] {
        var byKey: [String: LocalServer] = [:]
        for line in output.split(separator: "\n").dropFirst() {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard cols.count >= 9, let pid = Int(cols[1]) else { continue }
            let command = cols[0]
            // NAME is the column before "(LISTEN)"; addresses never contain spaces.
            guard let addressIndex = cols.firstIndex(where: { $0.contains(":") && $0 != "TCP" }),
                  let portText = cols[addressIndex].split(separator: ":").last,
                  let port = Int(portText) else { continue }
            let address = cols[addressIndex]
            let loopback = address.hasPrefix("127.0.0.1") || address.hasPrefix("[::1]")

            guard port < ephemeralFloor, !systemNoise.contains(command) else { continue }

            // IPv4 and IPv6 rows are the same server twice. Keep one, and let "listening on every
            // interface" win over "loopback only" — that is the more exposed truth.
            let key = "\(pid):\(port)"
            if let existing = byKey[key] {
                byKey[key] = LocalServer(port: port, command: command, pid: pid,
                                         loopbackOnly: existing.loopbackOnly && loopback)
            } else {
                byKey[key] = LocalServer(port: port, command: command, pid: pid, loopbackOnly: loopback)
            }
        }
        return byKey.values.sorted { ($0.port, $0.pid) < ($1.port, $1.pid) }
    }

    /// Parse `lsof -a -p <pids> -d cwd -Fpn` into pid → working directory.
    /// The field format is one letter per line: `p<pid>`, `fcwd`, `n<path>`.
    public static func parseWorkingDirs(_ output: String) -> [Int: String] {
        var out: [Int: String] = [:]
        var pid: Int?
        for line in output.split(separator: "\n") {
            switch line.first {
            case "p": pid = Int(line.dropFirst())
            case "n":
                let path = String(line.dropFirst())
                // A daemon's working directory is /private/var or /usr — that is not a project,
                // and printing it as one makes the list read like nonsense ("ollama · var").
                let systemDirs = ["/private/var", "/var", "/usr", "/opt", "/Library", "/System", "/"]
                if let p = pid, !systemDirs.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) {
                    out[p] = path
                }
            default: break
            }
        }
        return out
    }

    /// Everything listening, each row labelled with the project it is running in when that can be
    /// determined. Two `lsof` calls total — one for the ports, one for every pid's directory —
    /// because a call per process would make the menu visibly slow.
    public static func discover() -> [LocalServer] {
        let listeners = parse(lsof: Shell.run("lsof", ["-nP", "-iTCP", "-sTCP:LISTEN"]).out)
        guard !listeners.isEmpty else { return [] }

        let pids = Set(listeners.map(\.pid)).map(String.init).joined(separator: ",")
        let dirs = parseWorkingDirs(Shell.run("lsof", ["-a", "-p", pids, "-d", "cwd", "-Fpn"]).out)

        return listeners.map { server in
            var copy = server
            copy.project = dirs[server.pid].map { (($0 as NSString).lastPathComponent) }
            return copy
        }
    }

    /// The whole list as plain text, one line per server — built to be PASTED at an agent
    /// ("what are these and which can I kill?"), so every line carries port, what it is, where
    /// it runs, its pid, its reach and its URL. No header: a header is noise in a prompt.
    public static func report(_ servers: [LocalServer]) -> String {
        servers.map { s in
            let parts = [
                "port \(s.port)",
                s.kind,
                s.project.map { "project \($0)" },
                "pid \(s.pid)",
                s.loopbackOnly ? "this Mac only" : "reachable from your network",
                s.url,
            ]
            return parts.compactMap { $0 }.joined(separator: " · ")
        }.joined(separator: "\n")
    }

    // ─── Killing a port, and why the obvious version does not work ──────────
    //
    // This used to be `lsof -ti tcp:<port>` + `kill -9` on everything it
    // returned. It looked right and failed in two directions at once.
    //
    // TOO WIDE: bare `-ti` returns every socket on the port, CLIENTS included.
    // A browser tab open on localhost:3477 is in that list, so "Stop It" would
    // `kill -9` a Google Chrome renderer. `discover()` above already gets this
    // right with `-sTCP:LISTEN`; the kill path never did.
    //
    // TOO NARROW, and this is the one the user actually hits: a dev server is
    // not one process. `npm run dev` gives you
    //
    //     npm exec next dev  →  node  →  next-server   ← the ONLY pid lsof returns
    //
    // lsof returns the LEAF. Kill it and the npm parent is still alive and
    // still supervising, so it respawns the child and the port comes straight
    // back — from the menu it reads as "I clicked Stop It and nothing
    // happened", which is exactly the report. Verified 2026-08-27 against three
    // live servers: :3400 leaf 33176 under `npm exec next start -p 3400`,
    // :3401 leaf 54361 under its own npm, :3477 leaf 90588 under
    // `node` under `npm exec next dev -p 3477`.
    //
    // So: find the LISTENER, climb to the top of its runner tree, and signal
    // the whole subtree — TERM first so Next can flush, KILL only what
    // survives. This is the algorithm `scripts/dev-server.sh` in the
    // sntz_mockups repo already had to write for the same reason; its own
    // docblock names the three-process chain.

    /// Processes we are willing to climb THROUGH when looking for the root of a
    /// server's tree.
    ///
    /// The climb must stop somewhere, and "keep going until pid 1" is how you
    /// kill the user's terminal: a server started in a shell has that shell as
    /// an ancestor, and Terminal.app above it. Anything not named here ends the
    /// climb, so the worst case is that we kill a subtree that is too SMALL —
    /// recoverable — rather than one that closes the window you typed in.
    static let runnerCommands: Set<String> = [
        // `next` and `next-server` are BOTH here and both are load-bearing: a
        // Next tree is `npm` -> `.bin/next` -> `next-server`, so omitting the
        // middle name stops the climb at the leaf and reintroduces the exact
        // bug this function exists to fix. The test at LocalServersSuite caught
        // precisely that when only `next-server` was listed.
        "npm", "npx", "pnpm", "yarn", "bun", "node", "deno", "next", "next-server",
        "python", "python3", "uvicorn", "gunicorn", "flask", "ruby", "rails",
        "php", "java", "dotnet", "cargo", "vite", "esbuild", "webpack", "nodemon",
        "tsx", "ts-node", "rollup", "parcel",
        // NOT `turbo` or `concurrently`. They are multiplexers, not supervisors: neither
        // restarts a child that exits, so climbing through one buys nothing — and costs every
        // sibling. "Stop It" on :3001 in a Turborepo took :3000 and :3002 with it.
    ]

    /// Parse `ps -axo pid=,ppid=,comm=` into pid → (ppid, command). Pure.
    ///
    /// `comm` is a PATH, and macOS paths routinely contain spaces —
    /// `/Applications/Sublime Text.app/Contents/MacOS/sublime_text`, anything under
    /// `Application Support`, `Google Drive` or `iCloud Drive`. This used to cut the field at the
    /// FIRST space and take the basename of what was left, which turned that path into `Sublime`.
    /// A mis-identified command is not cosmetic here: `killSet` climbs to the highest ancestor
    /// still in `runnerCommands`, so a name that matches nothing stops the climb early and
    /// "Stop It" leaves the supervising `npm` alive to respawn the server it just killed.
    ///
    /// The slash decides. A field containing one is a path, and its basename is the whole tail
    /// after the last `/` — spaces included, exactly as `SystemVitals.parse` already does. A
    /// field with no slash is a bare name that may carry an argument tail, and there the first
    /// word is right. `ps -axo comm=` prints the executable and not the argument list, so the
    /// two shapes never overlap in practice.
    public static func parseProcessTable(_ output: String) -> [Int: (ppid: Int, command: String)] {
        var table: [Int: (ppid: Int, command: String)] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3, let pid = Int(parts[0]), let ppid = Int(parts[1]) else { continue }
            let full = parts[2...].joined(separator: " ")
            let name = full.contains("/")
                ? (full as NSString).lastPathComponent
                : (full.split(separator: " ").first.map(String.init) ?? full)
            table[pid] = (ppid, name)
        }
        return table
    }

    /// Every pid that must die for `listener` to stay dead. Pure, so the tree
    /// walk is testable without spawning anything.
    ///
    /// Climbs to the highest ancestor still in `runnerCommands`, then returns
    /// that root plus all of its descendants. Guards against a cyclic or
    /// self-parenting table by refusing to visit a pid twice.
    public static func killSet(listener: Int, table: [Int: (ppid: Int, command: String)]) -> [Int] {
        var root = listener
        var seen: Set<Int> = [listener]
        while let entry = table[root], entry.ppid > 1, let parent = table[entry.ppid],
              runnerCommands.contains(parent.command), !seen.contains(entry.ppid) {
            seen.insert(entry.ppid)
            root = entry.ppid
        }

        var children: [Int: [Int]] = [:]
        for (pid, entry) in table { children[entry.ppid, default: []].append(pid) }

        var out: [Int] = []
        var stack = [root]
        var visited: Set<Int> = []
        while let pid = stack.popLast() {
            guard visited.insert(pid).inserted else { continue }
            out.append(pid)
            stack.append(contentsOf: children[pid] ?? [])
        }
        return out.sorted()
    }

    /// Parse `launchctl list` into pid → job label. The columns are
    /// `PID\tStatus\tLabel`; a PID of `-` is a job that is loaded but not
    /// running, which nothing here needs to stop. Pure.
    public static func parseLaunchdJobs(_ output: String) -> [Int: String] {
        var out: [Int: String] = [:]
        for line in output.split(separator: "\n") {
            let cols = line.split(separator: "\t", omittingEmptySubsequences: true)
            guard cols.count >= 3, let pid = Int(cols[0]) else { continue }
            out[pid] = String(cols[2])
        }
        return out
    }

    /// Split "what must stop" into launchd jobs and free processes. Pure.
    ///
    /// A `brew services` daemon (postgres, redis, ollama) is a launchd agent
    /// with KeepAlive=true: signal ANY pid under it and launchd respawns it
    /// before the port check even runs, so from the menu "Stop It" reads as
    /// doing nothing — the exact report this fixes. The only stop launchd
    /// respects is `launchctl bootout` addressed by label, so if any pid in a
    /// listener's kill tree belongs to a launchd job, the whole tree becomes a
    /// bootout and none of it is signalled.
    public static func killPlan(listeners: [Int], jobs: [Int: String],
                                table: [Int: (ppid: Int, command: String)])
        -> (bootout: [(pid: Int, label: String)], signal: [Int]) {
        var bootout: [(pid: Int, label: String)] = []
        var signal: Set<Int> = []
        var bootedPids: Set<Int> = []
        for listener in listeners {
            let tree = killSet(listener: listener, table: table)
            if let owned = tree.first(where: { jobs[$0] != nil }), let label = jobs[owned] {
                if bootedPids.insert(owned).inserted { bootout.append((owned, label)) }
            } else {
                signal.formUnion(tree)
            }
        }
        return (bootout, signal.sorted())
    }

    /// Kill whatever holds a port, tree and all. Returns the pids it stopped.
    ///
    /// launchd-owned listeners are booted out by label (anything less is
    /// respawned — see `killPlan`); the rest get TERM, a wait for the listener
    /// to actually go, then KILL for the remainder. The return value is what
    /// was acted on — the caller reports it, so it must not claim a stop it
    /// did not perform.
    @discardableResult
    public static func kill(port: Int) -> [Int] {
        // LISTEN only. A client socket on this port belongs to somebody else.
        let listeners = Shell.run("lsof", ["-tnP", "-iTCP:\(port)", "-sTCP:LISTEN"]).out
            .split(separator: "\n").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard !listeners.isEmpty else { return [] }

        let table = parseProcessTable(Shell.run("ps", ["-axo", "pid=,ppid=,comm="]).out)
        let jobs = parseLaunchdJobs(Shell.run("launchctl", ["list"]).out)
        let plan = killPlan(listeners: listeners, jobs: jobs, table: table)

        // ponytail: bootout stops the service until next login or `brew services
        // start` — that is what "Stop It" promises, and re-enabling is brew's job.
        for (_, label) in plan.bootout {
            _ = Shell.run("launchctl", ["bootout", "gui/\(getuid())/\(label)"])
        }
        let doomed = (plan.signal + plan.bootout.map(\.pid)).sorted()
        for pid in plan.signal { _ = Shell.run("kill", ["-TERM", String(pid)]) }

        // Up to ~3s for a graceful exit, then force what is left. Polling the
        // LISTENER is the honest check: the port being free is the thing the
        // user asked for, not the pid table being empty.
        for _ in 0..<15 {
            let still = Shell.run("lsof", ["-tnP", "-iTCP:\(port)", "-sTCP:LISTEN"]).out
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if still.isEmpty { return doomed }
            Thread.sleep(forTimeInterval: 0.2)
        }
        // Only the signalled pids: kill -9 on a booted-out job's pid would be a
        // no-op at best and, if launchd already reused the pid, a wrong kill.
        for pid in plan.signal { _ = Shell.run("kill", ["-9", String(pid)]) }
        return doomed
    }
}
