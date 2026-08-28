import Darwin
import Foundation

/// What a process is ACTUALLY costing, from `libproc` rather than from `ps`.
///
/// ── WHY THIS EXISTS: BOTH NUMBERS IN THE MENU WERE WRONG ────────────────────────────────────
///
/// Measured on this machine, 2026-08-28, not reasoned about:
///
///   CPU.    `ps -o pcpu` on macOS is a LIFETIME AVERAGE since the process started. It reported
///           Google Chrome at 21.4% while a real one-second measurement put it at 0.5% — a
///           forty-fold error on the exact question the menu asks, which is "is this agent
///           working right now". A browser that was busy an hour ago reads busy forever.
///
///   MEMORY. Summing `rss` across a process tree counts every shared page once per process, and
///           an agent session is a tree of twenty-four. Across the four live sessions here,
///           rss-summing overstated the real figure by ×1.78 to ×1.93. The menu was showing
///           roughly double.
///
/// ── WHAT REPLACES THEM ──────────────────────────────────────────────────────────────────────
///
///   MEMORY. `proc_pid_rusage(pid, RUSAGE_INFO_V6).ri_phys_footprint` — the same number Activity
///           Monitor's "Memory" column shows, which is what a user will compare against. It
///           counts compressed pages and IOKit mappings and does not double-count clean shared
///           file pages.
///
///   CPU.    The same call's `ri_user_time` + `ri_system_time`: cumulative CPU, a COUNTER. Two
///           samples and the interval between them give the real current figure — the same method
///           `top` and `htop` use. 100% is ONE core, as in Activity Monitor.
///
///   AND THE THIRD ONE, added 2026-08-28 because the first two still could not answer the
///   question that prompted all of this. "Why did this eat 9 GB?" is unanswerable from a figure
///   sampled after the fact: the spike is over, and every tool on the machine agrees nothing
///   happened. `ri_lifetime_max_phys_footprint` is the kernel's own high-water mark and it
///   survives the release. That is the whole reason this file moved from V4 to V6, and V6 costs
///   the same — measured, 0.019 ms against 0.020 ms per 30 pids.
///
/// ── AND WHY IT IS AFFORDABLE ────────────────────────────────────────────────────────────────
///
/// No root. No `task_for_pid`, which is restricted on modern macOS and would need an entitlement
/// this app will not ask for. No subprocess either, since 2026-08-28: building the process tree
/// used to fork `ps`, measured at **117 ms** on every menu open, and now costs **0.88 ms** — see
/// `listing()` for the three calls that replace it and the two traps that make it three.
///
/// A refusal returns nil and is treated as "not ours", never as zero.
///
/// ── HOW TO EXTRACT A MEANINGFUL NUMBER: SEVEN RULES ─────────────────────────────────────────
///
/// Each one was earned by a bug in this file, not read in a book. They are here rather than in a
/// document because the next person to touch this code is the person who needs them.
///
///   1. PREFER A COUNTER YOU DIFF OVER A GAUGE SOMEBODY ELSE AVERAGED. `pcpu` is an average whose
///      window you did not choose — a lifetime average, as it turned out, which reads a browser
///      that was busy an hour ago as busy forever. Two samples and a measured interval is a
///      number you own.
///
///   2. MEASURE THE INTERVAL; NEVER ASSUME IT. A sleeping menu-bar timer drifts, and a nominal
///      two seconds used as a divisor prints spikes that never happened. `cpuPercent` takes the
///      seconds as an argument for exactly this reason.
///
///   3. PREFER THE NUMBER THE OS USES FOR THE SAME DECISION. `phys_footprint` is what jetsam
///      kills on and what Activity Monitor displays, so a user checking your work sees the same
///      figure. Validated by hand against `footprint(1)` on 2026-08-28 — 383 MB against 384 MB,
///      and the peak matched exactly. See docs/12-CAPABILITY-MAP.md section F.
///
///   4. A REFUSAL IS NOT A ZERO. Every accessor here returns nil for a process it may not read.
///      A gap is visible; a zero is a wrong number wearing the right shape.
///
///   5. EVERY UNIT CONVERSION GETS A TEST THAT FAILS ON A WRONG FACTOR. The 24× mach-tick bug is
///      invisible to review and obvious to a busy loop. `ProcessMetricsSuite` burns a core and
///      asserts the band; `Scripts/check-metrics.sh` does it again against the whole product.
///
///   6. VALIDATE ONCE AGAINST AN INDEPENDENT TOOL, BY HAND, AND WRITE DOWN THE DATE AND DELTA.
///      Done, dated, and reproducible in docs/12-CAPABILITY-MAP.md. A number that agrees with
///      itself proves nothing.
///
///   7. A NUMBER WITH NO DECISION ATTACHED DOES NOT SHIP. This is what killed the battery
///      temperature and the "0.4 of 16 cores" line, and what let the peak in — "826 MB (peaked
///      6.1 GB)" answers "why did my Mac stall an hour ago", which nothing else could. State the
///      decision in the doc comment or delete the number.
public enum ProcessMetrics {
    /// Physical footprint in bytes, or nil when the process is gone or not ours to inspect.
    public static func footprint(_ pid: Int32) -> UInt64? { usage(pid)?.ri_phys_footprint }

    /// THE HIGH-WATER MARK, which is the only thing that can answer "why did this eat 9 GB?"
    ///
    /// `ri_phys_footprint` is what a process holds at the instant you look. By the time anyone
    /// thinks to look, the spike is over and every tool on the machine agrees that nothing
    /// happened. `ri_lifetime_max_phys_footprint` is the kernel's own record of the worst it ever
    /// got, and it survives the release.
    ///
    /// Proved 2026-08-28, not reasoned about: fork a child, allocate 2 GB, touch every page, free
    /// it, then sample. Footprint 2.2 MB. Lifetime max **2.00 GB**.
    public static func peakFootprint(_ pid: Int32) -> UInt64? {
        usage(pid)?.ri_lifetime_max_phys_footprint
    }

    /// MACH ABSOLUTE TIME IS NOT NANOSECONDS, and on Apple Silicon it is not close.
    ///
    /// `ri_user_time` / `ri_system_time` are counted in mach ticks. On Intel the timebase is 1/1
    /// so they happen to BE nanoseconds, which is why reading them as such is a common and
    /// invisible bug — it is correct on the machine most people wrote it on. This Mac reports
    /// 125/3: one tick is 41.67 ns, so the naive reading under-reports CPU by 24×.
    ///
    /// Caught by measurement, not by review: a Python busy-loop pinning one core read as 2.4%,
    /// and 2.4 × 41.67 is 100.
    ///
    /// FROM `hw.tbfrequency`, NOT `mach_timebase_info()`. Rosetta 2 reports the timebase as 1/1
    /// to a translated x86_64 process running on Apple Silicon, which reintroduces the same 41.67×
    /// undercount for anyone running Chute under translation — and it does so silently, on a
    /// machine where the "obvious" API says everything is fine. `hw.tbfrequency` is not
    /// intercepted. (psutil documents the same trap: psutil/arch/osx/proc.c.)
    private static let nanosPerTick: Double = {
        var hz: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        if sysctlbyname("hw.tbfrequency", &hz, &size, nil, 0) == 0, hz > 0 {
            return 1_000_000_000 / Double(hz)
        }
        // Only if the sysctl is unavailable. Wrong under Rosetta, which is better than zero.
        var tb = mach_timebase_info_data_t()
        guard mach_timebase_info(&tb) == KERN_SUCCESS, tb.denom != 0 else { return 1 }
        return Double(tb.numer) / Double(tb.denom)
    }()

    /// Cumulative CPU nanoseconds (user + system). A COUNTER, not a gauge: it only goes up and
    /// is meaningless alone — see `cpuPercent`.
    ///
    /// From `proc_pid_rusage`, not a second `proc_pidinfo(PROC_PIDTASKINFO)` call: measured,
    /// `ri_user_time`/`ri_system_time` are bit-identical to `pti_total_user`/`pti_total_system`,
    /// so one syscall gets both memory and CPU and the second buys only a thread count nobody
    /// displays.
    public static func cpuNanos(_ pid: Int32) -> UInt64? { usage(pid).map(nanos) }

    private static func nanos(_ info: rusage_info_v6) -> UInt64 {
        UInt64(Double(info.ri_user_time &+ info.ri_system_time) * nanosPerTick)
    }

    /// V6, NOT V4, AND IT IS FREE. Measured 2026-08-28 over 30 pids: V4 0.020 ms, V6 0.019 ms —
    /// the difference is noise. V6 carries `ri_lifetime_max_phys_footprint` (the peak this menu
    /// now shows) and `ri_proc_start_abstime` (the pid-recycling guard below), so the older
    /// struct was costing the same and answering less.
    ///
    /// A REFUSAL IS NOT A ZERO, and this is the line that enforces it. The research this was
    /// written against claimed `proc_pid_rusage` returns rc 0 with a ZEROED struct for another
    /// user's process, which would make every one of them read as "0 bytes, 0% CPU" — a silent
    /// wrong number, which is worse than a gap. **Measured on this machine and it does not:**
    /// 169 pids scanned, 0 returned rc 0 for a uid that was not ours, 14 refused outright, and
    /// pid 1 (root's launchd) gives `rc = -1, errno = EPERM`. So `rc == 0 ? info : nil` is
    /// correct here — and `ProcessMetricsSuite` now pins that behaviour, so a future macOS that
    /// starts handing back zeros fails the build instead of quietly halving every figure.
    private static func usage(_ pid: Int32) -> rusage_info_v6? {
        var info = rusage_info_v6()
        let rc = withUnsafeMutablePointer(to: &info) { p -> Int32 in
            p.withMemoryRebound(to: Optional<UnsafeMutableRawPointer>.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V6, $0)
            }
        }
        return rc == 0 ? info : nil
    }

    public struct Sample: Sendable, Equatable {
        public let footprintBytes: UInt64
        /// The worst this process ever held, from `ri_lifetime_max_phys_footprint`.
        public let peakFootprintBytes: UInt64
        public let cpuNanos: UInt64
        /// WHICH process this is, not just which pid. Mach absolute time at exec, so it is
        /// boot-relative and monotonic: unlike a wall-clock start time it cannot be moved by an
        /// NTP step, and unlike the pid alone it is not reused. See `cpuPercent`.
        public let startAbstime: UInt64

        public init(footprintBytes: UInt64, cpuNanos: UInt64,
                    peakFootprintBytes: UInt64 = 0, startAbstime: UInt64 = 0) {
            self.footprintBytes = footprintBytes
            self.peakFootprintBytes = peakFootprintBytes
            self.cpuNanos = cpuNanos
            self.startAbstime = startAbstime
        }
    }

    /// Every process this user may inspect, in one pass. Processes that refuse are simply absent:
    /// a map that says nothing about a pid is honest, a map that says 0 is not.
    public static func snapshot(pids: [Int32]? = nil) -> [Int32: Sample] {
        let list = pids ?? allPIDs()
        var out: [Int32: Sample] = [:]
        out.reserveCapacity(list.count)
        for pid in list {
            guard let u = usage(pid) else { continue }   // one syscall, every number
            out[pid] = Sample(footprintBytes: u.ri_phys_footprint,
                              cpuNanos: nanos(u),
                              peakFootprintBytes: u.ri_lifetime_max_phys_footprint,
                              startAbstime: u.ri_proc_start_abstime)
        }
        return out
    }

    /// Percent of ONE core between two snapshots — the convention `ps`, `top` and Activity
    /// Monitor all use, so 300% means three cores pinned.
    ///
    /// nil when either end is missing (the process started or died inside the window) or the
    /// interval is zero. A process that has just appeared has no rate yet, and inventing one by
    /// dividing its lifetime total by the window would report a brand-new process as pinning
    /// every core on the machine.
    ///
    /// AND NIL WHEN THE PID HAS BEEN REUSED. Diffing a counter assumes both ends came from the
    /// same process; a pid is recycled, so between two samples two seconds apart the pid can
    /// belong to something else entirely. Its counter then starts from zero, and the subtraction
    /// either underflows or — worse, because it looks plausible — reports the new process's whole
    /// lifetime as if it had been burned inside our window. `ri_proc_start_abstime` settles it:
    /// same pid AND same start time, or there is no rate to report.
    ///
    /// Compared, never trusted as a clock. It is mach absolute time, so it is boot-relative and
    /// monotonic — the point is precisely that a clock adjustment cannot make two different
    /// processes look like one.
    public static func cpuPercent(pid: Int32, from: [Int32: Sample], to: [Int32: Sample],
                                  seconds: Double) -> Double? {
        guard seconds > 0, let a = from[pid], let b = to[pid], b.cpuNanos >= a.cpuNanos,
              a.startAbstime == b.startAbstime else { return nil }
        return Double(b.cpuNanos - a.cpuNanos) / 1_000_000_000 / seconds * 100
    }

    /// One row of the process tree, with no subprocess and no text parsing.
    public struct Listing: Sendable, Equatable {
        public let pid: Int32
        public let ppid: Int32
        public let tty: String       // "ttys004", or "" for no controlling terminal
        public let command: String   // basename of the real executable path

        public init(pid: Int32, ppid: Int32, tty: String, command: String) {
            self.pid = pid; self.ppid = ppid; self.tty = tty; self.command = command
        }
    }

    /// THE 117 ms `ps` FORK, DELETED.
    ///
    /// Building the tree used to shell out to `ps -Axo pid=,ppid=,tty=,pcpu=,rss=,comm=` and
    /// parse the columns. Measured on this machine, 2026-08-28: **117 ms**, every time the menu
    /// opened, on the main path a user is already waiting on. The kernel will hand over the same
    /// facts directly.
    ///
    /// THREE CALLS, AND IT HAS TO BE THREE — the obvious one-call version is silently wrong:
    ///
    ///   1. `sysctl KERN_PROC_ALL` — pid, ppid, uid, tdev for every process. **0.136 ms for 659
    ///      processes.** No fork, no parsing, no locale.
    ///   2. `devname(3)` turns `e_tdev` into a name. Cross-checked against `ps -o tty=` across the
    ///      whole machine: **658 agreed, 0 disagreed.**
    ///   3. `proc_pidpath` for the command. **THIS IS THE ONE THAT IS EASY TO MISS.**
    ///      `kinfo_proc.p_comm` is right there in the struct from step 1 and looks like the
    ///      answer, but the kernel truncates it to sixteen characters: measured, 160 of our 383
    ///      processes sit at that cap, and every `chrome-headless-shell` arrives as
    ///      `chrome-headless-`. `SystemVitals.commandFamily` matches on the name, so a listing
    ///      built from `p_comm` stops recognising Chrome — and does it quietly, with a plausible
    ///      string, which is exactly the failure mode this whole file exists to prevent.
    ///      `proc_pidpath` costs 1.303 ms for 383 pids and returns the real path.
    ///
    /// Net: **117 ms → about 1.5 ms**, and the names get BETTER rather than worse.
    ///
    /// FILTERED TO OUR OWN UID, deliberately and before anything is recorded. Another user's
    /// processes were never ours to report, `proc_pid_rusage` refuses them anyway, and carrying
    /// them only to drop them later is how a zero ends up standing in for a refusal.
    public static func listing(uid: uid_t = getuid()) -> [Listing] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0, size > 0 else { return [] }
        // Headroom, then ask again: processes are forking while we count them, and a buffer sized
        // to the first answer can be short by the time the second call fills it.
        var buf = [kinfo_proc](repeating: kinfo_proc(),
                               count: size / MemoryLayout<kinfo_proc>.stride + 64)
        size = buf.count * MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, 4, &buf, &size, nil, 0) == 0 else { return [] }

        var out: [Listing] = []
        out.reserveCapacity(size / MemoryLayout<kinfo_proc>.stride)
        for i in 0..<(size / MemoryLayout<kinfo_proc>.stride) {
            let k = buf[i]
            guard k.kp_eproc.e_ucred.cr_uid == uid, k.kp_proc.p_pid > 0 else { continue }
            out.append(Listing(pid: k.kp_proc.p_pid,
                               ppid: k.kp_eproc.e_ppid,
                               tty: ttyName(k.kp_eproc.e_tdev) ?? "",
                               command: programName(path: path(of: k.kp_proc.p_pid),
                                                    comm: comm(k))))
        }
        return out
    }

    /// `e_tdev` is a `dev_t`. `devname(3)` is the supported way to name one, and it is what `ps`
    /// itself uses — which is why the two agree on every process on this machine.
    ///
    /// CACHED, AND THIS IS WHERE ALL THE TIME WAS. Measured 2026-08-28: `devname` costs about
    /// 0.45 ms **per call**, and calling it once per process meant 36 calls — 16.8 ms of an
    /// 17.8 ms listing, so 94% of the cost of replacing `ps` went straight back into naming
    /// terminals. Those 36 processes sat on **five** distinct terminals. Asking the same question
    /// thirty-one extra times is the whole difference between 17.8 ms and 0.6 ms.
    ///
    /// Safe to hold forever: a tty's device number is fixed for the life of the machine — ttys004
    /// is always the same `dev_t` — so this is memoising an identity, not caching a measurement.
    /// The lock is not decorative: `SystemVitals.sample()` runs both on the main thread when the
    /// menu opens and on a background queue for the two-second refresh.
    nonisolated(unsafe) private static var ttyNames: [Int32: String] = [:]
    private static let ttyNamesLock = NSLock()

    private static func ttyName(_ tdev: Int32) -> String? {
        guard tdev != -1 else { return nil }
        ttyNamesLock.lock()
        defer { ttyNamesLock.unlock() }
        if let hit = ttyNames[tdev] { return hit.isEmpty ? nil : hit }

        var name = ""
        if let c = devname(dev_t(bitPattern: UInt32(bitPattern: tdev)), S_IFCHR) {
            let raw = String(cString: c)
            // "??" is what ps prints for no controlling terminal; devname can also hand back a
            // raw number for a device it cannot name. Neither is a tty, and neither may be
            // treated as one. An empty string is cached as "we asked, there is no name".
            if !raw.isEmpty, raw.allSatisfy({ $0.isLetter || $0.isNumber }) { name = raw }
        }
        ttyNames[tdev] = name
        return name.isEmpty ? nil : name
    }

    /// The real executable path. nil when the process died between the listing and this call —
    /// which is normal, not an error, and is why the caller has a fallback.
    private static func path(of pid: Int32) -> String? {
        var buf = [CChar](repeating: 0, count: 4096)
        guard proc_pidpath(pid, &buf, UInt32(buf.count)) > 0 else { return nil }
        let path = String(cString: buf)
        return path.isEmpty ? nil : path
    }

    /// The kernel's own name for the process. Truncated to sixteen characters — see `listing` —
    /// but it is the name the process was EXEC'd under, which is a different fact from its path
    /// and is sometimes the better one. See `programName`.
    private static func comm(_ k: kinfo_proc) -> String {
        var raw = k.kp_proc.p_comm
        return withUnsafeBytes(of: &raw) {
            String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
    }

    /// WHAT TO CALL A PROCESS, when neither source is right on its own.
    ///
    /// Both of the available names have a blind spot, and each one covers the other's:
    ///
    ///   `p_comm` is the exec name, truncated at sixteen characters — so Playwright's browser
    ///   arrives as `chrome-headless-` and `SystemVitals.commandFamily` stops recognising it.
    ///
    ///   The PATH's last component is untruncated, but it is not always a program name. Caught
    ///   live on this machine, 2026-08-28, in the menu itself: Claude Code installs as
    ///   `~/.local/share/claude/versions/2.1.250` — the executable file IS the version string —
    ///   so every agent row read **"mostly 2.1.250"**. A plausible string in the right place,
    ///   which is exactly the failure this file exists to stop. `ps` never showed it because `ps`
    ///   prints `p_comm`, and `p_comm` here is "claude".
    ///
    /// AND `p_comm` DOES NOT RESCUE IT. That was the first attempt, on the evidence that
    /// `ps -o comm=` prints "claude" — but ps prints argv[0], not `p_comm`, and `p_comm` for
    /// these processes is "2.1.250" too. Measured, after the fix failed to change the menu:
    /// every source that is one flat string is wrong here, because the program's own name is not
    /// in any of them. It is in the PATH, one level up.
    ///
    /// So: walk up past components that cannot be a program name — a bare version, and the
    /// container directories a versioned install puts around it — and take the first real one.
    /// `…/claude/versions/2.1.250` gives "claude". `/bin/zsh` gives "zsh" on the first look,
    /// because the walk only moves when the current candidate is disqualified.
    ///
    /// Pure, and tested on every branch: a version-named binary resolves to its program, a long
    /// name survives intact, an ordinary path is untouched.
    public static func programName(path: String?, comm: String) -> String {
        guard let path, !path.isEmpty else { return comm }
        var parts = path.split(separator: "/").map(String.init)
        while let last = parts.last, parts.count > 1,
              looksLikeAVersion(last) || versionContainers.contains(last.lowercased()) {
            parts.removeLast()
        }
        guard let name = parts.last, !name.isEmpty else { return comm }
        return name
    }

    /// Directories a versioned install wraps its binary in. Only walked past when the component
    /// BELOW them was already disqualified, so a program legitimately called "bin" is unreachable
    /// from here — nothing is named this and then shipped as the thing a user recognises.
    private static let versionContainers: Set<String> = ["versions", "bin", "sbin", "libexec", "current"]

    /// "2.1.250", "v18.20.4", "1.0" — digits, dots and an optional leading v, and nothing else.
    /// Deliberately narrow: `chrome-headless-shell` and `python3.11` must NOT match, or the rule
    /// above would throw away the good name to fix the bad one.
    public static func looksLikeAVersion(_ s: String) -> Bool {
        var body = Substring(s)
        if body.first == "v" || body.first == "V" { body = body.dropFirst() }
        guard let first = body.first, first.isNumber else { return false }
        return body.allSatisfy { $0.isNumber || $0 == "." }
    }

    /// Every pid on the machine, via `proc_listallpids`. Asked twice: once for the count, once
    /// for the data, because the number of processes changes between the two calls.
    public static func allPIDs() -> [Int32] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [Int32](repeating: 0, count: Int(count) + 64)   // headroom for new arrivals
        let bytes = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<Int32>.size))
        guard bytes > 0 else { return [] }
        return Array(pids.prefix(Int(bytes) / MemoryLayout<Int32>.size)).filter { $0 > 0 }
    }
}
