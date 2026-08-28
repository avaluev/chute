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

    // DELETED 2026-08-28: busiest, machineLine, batteryCelsius, temperature, fahrenheit,
    // temperatureLabel, thermalPressure.
    //
    // The menu carried "This Mac — using 0.4 of 16 cores · battery at 31 °C · 87 °F". Two of
    // those three claims were worthless to the person reading them:
    //
    //   · The BATTERY temperature is not the machine's temperature. It is a sensor in the battery
    //     pack, and on a laptop under an agent workload it does not track how hot the chassis
    //     actually gets — the owner of this Mac bought a cooling pad while this line said
    //     "running cool". A number that disagrees with the hand on the keyboard teaches the reader
    //     to disbelieve the whole menu. The real CPU die sensors need administrator access, which
    //     Chute will not ask for, so the honest move is to say nothing rather than to say the one
    //     number we can get for free.
    //   · "using 0.4 of 16 cores" is a whole-machine instantaneous average. It moved every two
    //     seconds, it was never the reason anything was slow, and no decision followed from it.
    //
    // `load(forTTY:in:)` survives because a SINGLE session that has gone runaway is still worth
    // saying — that is a fact about the agent you are running, not about the weather inside the
    // case. See SessionMenu for where that threshold lives.

    public static func sample() -> [ProcessSample] {
        attribute(parse(ps: Shell.run("ps", ["-Axo", "pid=,ppid=,tty=,pcpu=,rss=,comm="]).out))
    }

    public static func bytes(_ count: UInt64) -> String {
        let gb = Double(count) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        return "\(count / 1_048_576) MB"
    }
}
