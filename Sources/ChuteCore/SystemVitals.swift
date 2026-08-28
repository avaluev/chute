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
    /// The real one, from ProcessMetrics. `residentKB` is what `ps` said and is kept only so the
    /// tree-attribution tests can work from a fixture string; every figure a user sees comes from
    /// here. Falls back to rss when the process refused inspection.
    public var footprintBytes: UInt64 = 0
    /// The worst this process ever held. 0 when unknown — see `ProcessMetrics.peakFootprint`.
    public var peakFootprintBytes: UInt64 = 0
    /// The Unix session id, which every descendant of a login shell inherits and which
    /// reparenting does not change. 0 means unknown — see `attribute`.
    public var sid: Int = 0

    /// WHICH browser instance this belongs to, when it is a browser and we could tell.
    /// "Chrome (mcp-chrome-9ebcc11)". nil for everything else — see `ProcessIdentity`.
    public var instance: String?

    /// The program a process belongs to, for grouping. "Google Chrome Helper (Renderer)" and
    /// "Google Chrome Helper (GPU)" are Google Chrome; six of them are still one program, which is
    /// how a person thinks about it and how they will act on it.
    ///
    /// AND WHICH ONE, for browsers. Grouping every Chromium process under "Google Chrome" put the
    /// user's own browser, a Playwright shell and an anti-detect browser in one bucket, so the row
    /// said `mostly Google Chrome` and pointed at nothing you could act on. When the instance is
    /// known it IS the family: two Chromes with different `--user-data-dir` are two programs as
    /// far as any decision the reader makes is concerned.
    public var family: String { instance ?? SystemVitals.commandFamily(command) }

    /// What this process actually holds. `footprintBytes` when we could read it, and the `ps`
    /// figure when the process refused us — a refusal must not read as zero bytes.
    public var bytes: UInt64 { footprintBytes > 0 ? footprintBytes : residentKB * 1024 }

    public init(pid: Int, ppid: Int, command: String, tty: String,
                cpuPercent: Double, residentKB: UInt64) {
        self.pid = pid; self.ppid = ppid; self.command = command
        self.tty = tty; self.cpuPercent = cpuPercent; self.residentKB = residentKB
    }
}

public struct SessionLoad: Sendable, Equatable {
    public let cpuPercent: Double
    public let residentBytes: UInt64
    /// The sum of every process's high-water mark. See `peakNote` for when it is worth saying.
    public let peakBytes: UInt64
    public let processes: Int
    /// The program holding most of the memory, when one clearly does. This is the actionable
    /// half: "5.0 GB" cannot tell you whether to restart a dev server or quit a browser, and
    /// those are different problems with different fixes.
    public let top: (command: String, bytes: UInt64)?

    public init(cpuPercent: Double, residentBytes: UInt64, processes: Int,
                top: (command: String, bytes: UInt64)? = nil, peakBytes: UInt64 = 0) {
        self.cpuPercent = cpuPercent
        self.residentBytes = residentBytes
        self.peakBytes = peakBytes
        self.processes = processes
        self.top = top
    }

    public static func == (a: SessionLoad, b: SessionLoad) -> Bool {
        a.cpuPercent == b.cpuPercent && a.residentBytes == b.residentBytes
            && a.peakBytes == b.peakBytes
            && a.processes == b.processes && a.top?.command == b.top?.command
            && a.top?.bytes == b.top?.bytes
    }

    /// Above this share of the session's memory, one program IS the story and gets named.
    /// Below it, nothing dominates and naming the largest of five similar things points at
    /// nothing — a menu row that always ends in a name is a name nobody reads.
    public static let dominantShare = 0.5

    /// A PEAK EQUAL TO THE PRESENT IS NOT INFORMATION. Every process's high-water mark is at
    /// least its current size, so a naive "(peaked …)" would appear on every row, always, saying
    /// nothing — which is precisely how the old "1% CPU · 974 MB" suffix earned its deletion.
    ///
    /// Two conditions, and both are needed. The RATIO catches the shape that matters: something
    /// held far more than it holds now. The FLOOR stops the ratio firing on trivia — a 4 MB shell
    /// that once touched 8 MB doubles, and nobody has ever cared. Below half a gigabyte a spike
    /// is not the reason anything on this machine was slow.
    public static let peakWorthShowing = 1.5
    public static let peakFloorBytes: UInt64 = 512 * 1_048_576

    /// "(peaked 6.1 GB)", or nothing at all.
    ///
    /// THIS IS THE ANSWER TO "why did you eat 9 GB?" — a question the owner asked about a session
    /// that, by the time anyone looked, held 800 MB. `ri_phys_footprint` is an instant; the spike
    /// that made someone open the menu is already over, and every other tool on the machine
    /// agrees nothing happened. The kernel kept the record. This shows it.
    public var peakNote: String? {
        guard peakBytes >= Self.peakFloorBytes, residentBytes > 0,
              Double(peakBytes) / Double(residentBytes) >= Self.peakWorthShowing else { return nil }
        return " (peaked \(SystemVitals.bytes(peakBytes)))"
    }

    /// "12% CPU · 1.2 GB memory", for EVERY session that has a process in it, plus what is
    /// holding it when one program holds most of it.
    ///
    /// This used to go empty below 1% CPU and 200 MB, on the argument that "0% CPU · 4 MB memory"
    /// was noise in a list you scan for the busy one. Owner's call, 2026-08-28: the numbers are
    /// the useful part. Someone running five agents is comparing them, and a blank where a figure
    /// belongs reads as "not measured" rather than "small".
    ///
    /// Still empty when there is no process at all: that is genuinely nothing to report, not zero.
    public var label: String {
        guard processes > 0 else { return "" }
        var out = "\(Int(cpuPercent.rounded()))% CPU · \(SystemVitals.bytes(residentBytes)) memory"
        if let peakNote { out += peakNote }
        if let top, residentBytes > 0,
           Double(top.bytes) / Double(residentBytes) >= Self.dominantShare {
            out += " · mostly \(top.command)"
        }
        return out
    }
}

public enum SystemVitals {
    /// Parse `ps -Axo pid=,ppid=,tty=,pcpu=,rss=,comm=`. Pure, so the column handling is
    /// testable without ps. "??" — no controlling terminal — becomes an empty tty; the process
    /// is KEPT, because `attribute` may hand it to the session it descends from.
    public static func parse(ps output: String, sids: [Int: Int] = [:]) -> [ProcessSample] {
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
            var sample = ProcessSample(pid: pid, ppid: ppid, command: command,
                                       tty: attached ? Session.normalise(tty: rawTTY) : "",
                                       cpuPercent: cpu, residentKB: rss)
            sample.sid = sids[pid] ?? 0
            out.append(sample)
        }
        return out
    }

    /// THE HOT-MAC FIX, and the reparenting fix on top of it.
    ///
    /// An agent's real work happens in spawned children that DROP the tty — claude (ttys004) →
    /// zsh (??) → npm (??) → chrome-headless-shell (??) at 120% — so summing only tty-attached
    /// processes showed "0% CPU" on a session cooking the chassis.
    ///
    /// TWO ROUTES, IN ORDER OF HOW MUCH THEY SURVIVE:
    ///
    ///   1. THE SESSION ID. Every descendant of a login shell inherits its sid, and being
    ///      reparented to launchd does not change it. This is the route that keeps working when
    ///      a process is double-forked or its parent exits first — the case a ppid walk cannot
    ///      see, and the one `pstree` and htop's tree view also lose.
    ///   2. THE PARENT CHAIN. Used when the sid is unknown (0) or its session owns no terminal.
    ///
    /// A session whose leader has no tty belongs to nobody: a launchd daemon must not be billed
    /// to whichever terminal happens to sort first. Pure — the sids are read once by `sample()`,
    /// because `ps -o sess=` cannot supply them (kp_eproc.e_sess is NULL for non-root, so ps
    /// prints 0 for every process on the machine).
    public static func attribute(_ samples: [ProcessSample]) -> [ProcessSample] {
        var ttyByPid: [Int: String] = [:]
        var ppidByPid: [Int: Int] = [:]
        var ttyBySID: [Int: String] = [:]
        for s in samples {
            if !s.tty.isEmpty {
                ttyByPid[s.pid] = s.tty
                if s.sid != 0, ttyBySID[s.sid] == nil { ttyBySID[s.sid] = s.tty }
            }
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
            guard s.tty.isEmpty else { return s }
            guard let tty = (s.sid != 0 ? ttyBySID[s.sid] : nil) ?? owner(s.pid) else { return s }
            var out = ProcessSample(pid: s.pid, ppid: s.ppid, command: s.command, tty: tty,
                                    cpuPercent: s.cpuPercent, residentKB: s.residentKB)
            out.footprintBytes = s.footprintBytes
            out.peakFootprintBytes = s.peakFootprintBytes
            out.instance = s.instance
            out.sid = s.sid
            return out
        }
    }

    /// The PROGRAM a process belongs to. A path becomes its last component; a Chrome helper
    /// becomes Chrome. Six renderers are still one browser, which is how a person thinks about it
    /// and, more to the point, how they will act on it.
    public static func commandFamily(_ command: String) -> String {
        var name = (command as NSString).lastPathComponent
        // "Google Chrome Helper (Renderer)" / "…(GPU)" / "…(Plugin)" are all Chrome. So is
        // "Google Chrome Helper" on its own.
        if let r = name.range(of: " Helper") { name = String(name[..<r.lowerBound]) }
        return name.isEmpty ? command : name
    }

    /// Everything a terminal is running, added up: the agent, its node processes, and the
    /// detached children `attribute` handed back to it — plus WHICH program holds most of it.
    ///
    /// Memory is `footprintBytes`, not summed rss. Summing rss counts every shared page once per
    /// process and a session is a tree of twenty-four of them; measured across four live sessions
    /// on 2026-08-28 it overstated by ×1.78 to ×1.93. See ProcessMetrics.
    public static func load(forTTY tty: String, in samples: [ProcessSample]) -> SessionLoad {
        let mine = samples.filter { !$0.tty.isEmpty && $0.tty == Session.normalise(tty: tty) }
        guard !mine.isEmpty else { return SessionLoad(cpuPercent: 0, residentBytes: 0, processes: 0) }

        let bytes = mine.reduce(UInt64(0)) { $0 + $1.bytes }
        var byFamily: [String: UInt64] = [:]
        for p in mine { byFamily[p.family, default: 0] += p.bytes }
        let top = byFamily.max { $0.value < $1.value }.map { (command: $0.key, bytes: $0.value) }

        // Peaks are SUMMED, not maxed, for the same reason the footprints are: a session is a
        // tree, and what the reader wants to know is what the tree cost at its worst. It is an
        // upper bound — the twenty-four processes did not necessarily peak at the same instant —
        // and that is the honest direction to be wrong in for a "this is why your Mac stalled"
        // figure, which is also why `peakNote` refuses to print it unless it dwarfs the present.
        return SessionLoad(cpuPercent: mine.reduce(0) { $0 + $1.cpuPercent },
                           residentBytes: bytes,
                           processes: mine.count,
                           top: top,
                           peakBytes: mine.reduce(UInt64(0)) { $0 &+ $1.peakFootprintBytes })
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

    /// The previous snapshot, so CPU can be a RATE rather than a lifetime average. Held here
    /// because it is state about the machine, not about any one menu.
    nonisolated(unsafe) private static var previous: (at: Date, samples: [Int32: ProcessMetrics.Sample])?

    /// One `ps` for the process TREE — pid, ppid, tty and command, which libproc does not give
    /// conveniently — then real numbers from `ProcessMetrics` for everything a user will read.
    ///
    /// CPU is the average since the LAST call to this function, which is every two seconds while
    /// the menu is open. On the very first call there is no previous snapshot and therefore no
    /// rate: the row shows memory and no CPU figure, which is the honest answer to "how busy has
    /// this been since a moment ago" when there has not been a moment yet. It fills in two
    /// seconds later. `ps -o pcpu`, which is what this replaced, always had an answer and it was
    /// the average since the process started — it read Google Chrome at 21.4% while a real
    /// measurement put it at 0.5%.
    /// How long to wait for a first reading when there is no previous snapshot to diff against.
    ///
    /// A CPU rate needs two points in time. The menu-bar app has them for free — it re-samples
    /// every two seconds while open — but `chute sessions` runs once and exits, so without this
    /// it would print "0% CPU" for everything, every time. 150 ms is long enough for a real
    /// reading and short against the AppleScript round-trip to Terminal that the same command
    /// already pays for.
    public static let settleSeconds = 0.15

    /// NO SUBPROCESS. This used to fork `ps` — measured at **117 ms**, on the path a user is
    /// waiting on, every time the menu opened. `ProcessMetrics.listing()` gets the same tree from
    /// the kernel in about 1.5 ms; see the note there for why it takes three calls and why
    /// `p_comm` is not one of them.
    ///
    /// `parse(ps:)` is deliberately kept. It is pure, it is what the fixture tests in
    /// `SystemVitalsSuite` exercise, and a pure column parser costs nothing to leave standing.
    public static func sample() -> [ProcessSample] {
        // The sids come from getsid(2), one call each, because `ps -o sess=` could not supply
        // them either: kp_eproc.e_sess is NULL for a non-root reader, so ps prints 0 for every
        // process on the machine. That is a hole in ps, not in us, and it survives the rewrite.
        var rows: [ProcessSample] = []
        rows.reserveCapacity(64)
        for row in ProcessMetrics.listing() {
            var s = ProcessSample(pid: Int(row.pid), ppid: Int(row.ppid), command: row.command,
                                  tty: row.tty, cpuPercent: 0, residentKB: 0)
            let sid = getsid(pid_t(row.pid))
            if sid > 0 { s.sid = Int(sid) }
            rows.append(s)
        }
        let tree = attribute(rows)
        let pids = tree.map { Int32($0.pid) }
        if previous == nil {
            previous = (Date(), ProcessMetrics.snapshot(pids: pids))
            Thread.sleep(forTimeInterval: settleSeconds)
        }
        let now = Date()
        let live = ProcessMetrics.snapshot(pids: pids)
        let last = previous
        previous = (now, live)

        let seconds = last.map { now.timeIntervalSince($0.at) } ?? 0
        // Built once, not per process: a browser helper has to be walked up its parent chain to
        // find the process that carries --user-data-dir, and rebuilding the map for each of three
        // hundred processes would be quadratic on the path a user is waiting on.
        var ppidByPid: [Int: Int] = [:]
        for p in tree { ppidByPid[p.pid] = p.ppid }

        return tree.map { p in
            let pid = Int32(p.pid)
            let cpu = last.flatMap {
                ProcessMetrics.cpuPercent(pid: pid, from: $0.samples, to: live, seconds: seconds)
            }
            var out = ProcessSample(pid: p.pid, ppid: p.ppid, command: p.command, tty: p.tty,
                                    cpuPercent: cpu ?? 0, residentKB: p.residentKB)
            out.footprintBytes = live[pid]?.footprintBytes ?? 0
            out.peakFootprintBytes = live[pid]?.peakFootprintBytes ?? 0
            out.sid = p.sid
            out.instance = browserInstance(pid: pid, named: p.command, ppid: ppidByPid)
            return out
        }
    }

    /// Names the browser INSTANCE a process belongs to, and only for processes that could have
    /// one. See `ProcessIdentity` for how, and for what it deliberately will not claim.
    ///
    /// GATED ON THE NAME FIRST, because the answer is not free: reading argv costs 0.371 ms per
    /// process the first time (it is cached afterwards, and argv cannot change). Paying that
    /// across a three-hundred-process tree to discover that `zsh` is not a browser would put back
    /// most of the 117 ms this file just finished removing. A handful of Chromium processes is
    /// worth it; everything else is not asked.
    ///
    /// ponytail: substring match on the program name rather than a registry of browsers. Add the
    /// name when someone runs a Chromium fork this misses — a list of every Electron app on earth
    /// is not the cheaper thing.
    private static func browserInstance(pid: Int32, named name: String,
                                        ppid: [Int: Int]) -> String? {
        let lower = name.lowercased()
        guard lower.contains("chrome") || lower.contains("chromium") || lower.contains("brave")
                || lower.contains("edge") else { return nil }
        return ProcessIdentity.label(
            forPID: pid,
            ppidOf: { ppid[Int($0)].map(Int32.init) },
            argvOf: { ProcessIdentity.arguments($0) },
            pathOf: { ProcessIdentity.executablePath($0) })
    }

    public static func bytes(_ count: UInt64) -> String {
        let gb = Double(count) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        return "\(count / 1_048_576) MB"
    }
}
