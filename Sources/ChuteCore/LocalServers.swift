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

    /// Kill whatever holds a port. Returns the pids it signalled.
    @discardableResult
    public static func kill(port: Int) -> [Int] {
        let pids = Shell.run("lsof", ["-ti", "tcp:\(port)"]).out
            .split(separator: "\n").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        for pid in pids { _ = Shell.run("kill", ["-9", String(pid)]) }
        return pids
    }
}
