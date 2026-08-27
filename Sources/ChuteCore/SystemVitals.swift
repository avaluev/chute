import Foundation

/// What a terminal session is costing the machine, and how hot the machine is about it.
///
/// TEMPERATURE, honestly: on Apple Silicon the CPU die sensors are behind SMC keys that need root
/// or an entitlement, and `powermetrics` needs sudo. Chute takes no dependencies and asks for no
/// privileges, so it reports what CAN be read: the battery sensor (`ioreg -c AppleSmartBattery`,
/// centi-°C) and the system's own thermal pressure (`ProcessInfo.thermalState`). The battery is a
/// slower, cooler reading than the die — it is labelled as the battery for that reason, rather
/// than being passed off as "CPU temperature" like most menu-bar widgets do.
public struct ProcessSample: Sendable, Equatable {
    public let pid: Int
    public let ppid: Int
    public let command: String    // basename: "node", "chrome-headless-shell"
    public let tty: String        // normalised "ttys004", or "" for no controlling terminal
    public let cpuPercent: Double // as ps reports it: percent of ONE core
    public let residentKB: UInt64

    public init(pid: Int, ppid: Int, command: String, tty: String,
                cpuPercent: Double, residentKB: UInt64) {
        self.pid = pid; self.ppid = ppid; self.command = command
        self.tty = tty; self.cpuPercent = cpuPercent; self.residentKB = residentKB
    }
}

public struct SessionLoad: Sendable, Equatable {
    public let cpuPercent: Double
    public let residentBytes: UInt64
    public let processes: Int

    public init(cpuPercent: Double, residentBytes: UInt64, processes: Int) {
        self.cpuPercent = cpuPercent
        self.residentBytes = residentBytes
        self.processes = processes
    }

    /// "12% CPU · 1.2 GB memory". Empty when the session is doing nothing worth reporting — a row
    /// reading "0% CPU · 4 MB memory" for an idle shell is noise in a menu you scan for the busy one.
    public var label: String {
        guard processes > 0, cpuPercent >= 1.0 || residentBytes >= 200 * 1024 * 1024 else { return "" }
        // Neither number is allowed to make the reader guess: "2%" of what, "551 MB" of what.
        // Activity Monitor calls it Memory, so this does too — not RAM, not RSS.
        return "\(Int(cpuPercent.rounded()))% CPU · \(SystemVitals.bytes(residentBytes)) memory"
    }
}

public enum SystemVitals {
    /// Parse `ps -Axo pid=,ppid=,tty=,pcpu=,rss=,comm=`. Pure, so the column handling is
    /// testable without ps. "??" — no controlling terminal — becomes an empty tty; the process
    /// is KEPT, because `attribute` may hand it to the session it descends from.
    public static func parse(ps output: String) -> [ProcessSample] {
        var out: [ProcessSample] = []
        for line in output.split(separator: "\n") {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard cols.count >= 6,
                  let pid = Int(cols[0]),
                  let ppid = Int(cols[1]),
                  let cpu = Double(cols[3]),
                  let rss = UInt64(cols[4]) else { continue }
            let rawTTY = cols[2]
            let attached = rawTTY.allSatisfy { $0.isLetter || $0.isNumber } && !rawTTY.isEmpty
            // comm is a PATH, possibly with spaces ("next-server (v16.1.1)") — keep the tail
            // whole and take its basename.
            let command = (cols[5...].joined(separator: " ") as NSString).lastPathComponent
            out.append(ProcessSample(pid: pid, ppid: ppid, command: command,
                                     tty: attached ? Session.normalise(tty: rawTTY) : "",
                                     cpuPercent: cpu, residentKB: rss))
        }
        return out
    }

    /// THE HOT-MAC FIX. An agent's real work happens in spawned children that DROP the tty —
    /// claude (ttys004) → zsh (??) → npm (??) → chrome-headless-shell (??) at 120% — so summing
    /// only tty-attached processes showed "0% CPU" on a session cooking the chassis. Every
    /// detached process is walked up its parent chain and attributed to the first terminal
    /// found there; a chain that reaches launchd without one belongs to nobody. Pure.
    public static func attribute(_ samples: [ProcessSample]) -> [ProcessSample] {
        var ttyByPid: [Int: String] = [:]
        var ppidByPid: [Int: Int] = [:]
        for s in samples {
            if !s.tty.isEmpty { ttyByPid[s.pid] = s.tty }
            ppidByPid[s.pid] = s.ppid
        }
        func owner(_ pid: Int) -> String? {
            var p = pid
            var seen: Set<Int> = []
            while let ppid = ppidByPid[p], ppid > 1, seen.insert(p).inserted {
                if let tty = ttyByPid[ppid] { return tty }
                p = ppid
            }
            return nil
        }
        return samples.map { s in
            guard s.tty.isEmpty, let tty = owner(s.pid) else { return s }
            return ProcessSample(pid: s.pid, ppid: s.ppid, command: s.command, tty: tty,
                                 cpuPercent: s.cpuPercent, residentKB: s.residentKB)
        }
    }

    /// Everything a terminal is running, added up: the agent, its node processes, and the
    /// detached children `attribute` handed back to it.
    public static func load(forTTY tty: String, in samples: [ProcessSample]) -> SessionLoad {
        let mine = samples.filter { !$0.tty.isEmpty && $0.tty == Session.normalise(tty: tty) }
        return SessionLoad(cpuPercent: mine.reduce(0) { $0 + $1.cpuPercent },
                           residentBytes: mine.reduce(0) { $0 + $1.residentKB } * 1024,
                           processes: mine.count)
    }

    /// The single hungriest process on the machine — the answer to "why is my Mac hot", which
    /// no thermal average can give.
    public static func busiest(_ samples: [ProcessSample]) -> ProcessSample? {
        samples.max { $0.cpuPercent < $1.cpuPercent }
    }

    public static func sample() -> [ProcessSample] {
        attribute(parse(ps: Shell.run("ps", ["-Axo", "pid=,ppid=,tty=,pcpu=,rss=,comm="]).out))
    }

    // MARK: - Temperature

    /// `ioreg -c AppleSmartBattery -r` reports `"Temperature" = 3072` — centi-degrees Celsius.
    /// Values outside 0–80 °C are a misread, not a hot Mac, so they are refused.
    public static func batteryCelsius(fromIOReg output: String) -> Double? {
        guard let line = output.split(separator: "\n").first(where: {
            $0.contains("\"Temperature\"") && $0.contains("=")
        }) else { return nil }
        let digits = line.split(separator: "=").last?.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"; "))
        guard let raw = digits.flatMap({ Double($0) }) else { return nil }
        let celsius = raw / 100
        return (0...80).contains(celsius) ? celsius : nil
    }

    public static func temperature() -> Double? {
        batteryCelsius(fromIOReg: Shell.run("ioreg", ["-c", "AppleSmartBattery", "-r"]).out)
    }

    public static func fahrenheit(_ celsius: Double) -> Double { celsius * 9 / 5 + 32 }

    /// "31 °C · 88 °F". Both, because you asked for both.
    public static func temperatureLabel(_ celsius: Double) -> String {
        String(format: "%.0f °C · %.0f °F", celsius, fahrenheit(celsius))
    }

    /// The system's own view of how hard it is being pushed. A native API, no privileges, and the
    /// only honest answer to "is my Mac struggling" that does not need root.
    public static func thermalPressure(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:  return "running cool"
        case .fair:     return "running warm"
        case .serious:  return "running hot, about to slow down"
        case .critical: return "too hot, slowing down now"
        @unknown default: return "unknown"
        }
    }

    public static func bytes(_ count: UInt64) -> String {
        let gb = Double(count) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        return "\(count / 1_048_576) MB"
    }
}
