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
///   MEMORY. `proc_pid_rusage(pid, RUSAGE_INFO_V4).ri_phys_footprint` — the same number Activity
///           Monitor's "Memory" column shows, which is what a user will compare against. It
///           counts compressed pages and IOKit mappings and does not double-count clean shared
///           file pages.
///
///   CPU.    `proc_pidinfo(PROC_PIDTASKINFO)` gives cumulative user+system nanoseconds. Two
///           samples and the interval between them give the real current figure — the same
///           method `top` and `htop` use. 100% is ONE core, as in Activity Monitor.
///
/// ── AND WHY IT IS AFFORDABLE ────────────────────────────────────────────────────────────────
///
/// No root. No `task_for_pid`, which is restricted on modern macOS and would need an entitlement
/// this app will not ask for. Measured: **1.4 ms to sample all 639 processes on this machine**,
/// of which 362 were readable and 277 refused — the refusals are other users' and root's, which
/// were never ours to report. A refusal returns nil and is treated as "not ours", never as zero.
public enum ProcessMetrics {
    /// Physical footprint in bytes, or nil when the process is gone or not ours to inspect.
    public static func footprint(_ pid: Int32) -> UInt64? { usage(pid)?.ri_phys_footprint }

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

    private static func nanos(_ info: rusage_info_v4) -> UInt64 {
        UInt64(Double(info.ri_user_time &+ info.ri_system_time) * nanosPerTick)
    }

    private static func usage(_ pid: Int32) -> rusage_info_v4? {
        var info = rusage_info_v4()
        let rc = withUnsafeMutablePointer(to: &info) { p -> Int32 in
            p.withMemoryRebound(to: Optional<UnsafeMutableRawPointer>.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
            }
        }
        return rc == 0 ? info : nil
    }

    public struct Sample: Sendable, Equatable {
        public let footprintBytes: UInt64
        public let cpuNanos: UInt64
        public init(footprintBytes: UInt64, cpuNanos: UInt64) {
            self.footprintBytes = footprintBytes; self.cpuNanos = cpuNanos
        }
    }

    /// Every process this user may inspect, in one pass. Processes that refuse are simply absent:
    /// a map that says nothing about a pid is honest, a map that says 0 is not.
    public static func snapshot(pids: [Int32]? = nil) -> [Int32: Sample] {
        let list = pids ?? allPIDs()
        var out: [Int32: Sample] = [:]
        out.reserveCapacity(list.count)
        for pid in list {
            guard let u = usage(pid) else { continue }   // one syscall, both numbers
            out[pid] = Sample(footprintBytes: u.ri_phys_footprint, cpuNanos: nanos(u))
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
    public static func cpuPercent(pid: Int32, from: [Int32: Sample], to: [Int32: Sample],
                                  seconds: Double) -> Double? {
        guard seconds > 0, let a = from[pid], let b = to[pid], b.cpuNanos >= a.cpuNanos else { return nil }
        return Double(b.cpuNanos - a.cpuNanos) / 1_000_000_000 / seconds * 100
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
