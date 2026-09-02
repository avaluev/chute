import Darwin
import Foundation

/// "Which browser is that?" — `SystemVitals.commandFamily` collapses every Chrome-shaped helper
/// down to "Google Chrome", so a menu row reads `mostly Google Chrome` whether that is the
/// user's own browser, a Playwright-driven shell, or an anti-detect browser like AdsPower or
/// Dolphin running six renderers under the same roof. `ProcessIdentity` answers the finer
/// question by reading what the OS actually knows about a process: its real (untruncated)
/// executable path, its full argv, and — for anything Chromium-shaped — the `--user-data-dir` it
/// was launched with, which is Chrome's own name for "which instance is this".
///
/// ── THE LIMIT, STATED, NOT GUESSED ──────────────────────────────────────────────────────────
///
/// This can name the INSTANCE (the `--user-data-dir` a browser process was launched with) and
/// nothing finer. It cannot name a PROFILE inside one already-running instance: Chrome renderer
/// processes are spawned per SITE, not per profile, and carry no profile flag on their command
/// line at all — the profile lives in Chrome's own in-process browser state. Chrome's Task
/// Manager can label a tab by profile only because it is running *inside* the browser and reading
/// that state directly; nothing outside the process can. So two profiles opened in one already-
/// running Chrome window are indistinguishable from here, and this code does not pretend
/// otherwise — it names the instance, which is the coarser, honest answer.
public enum ProcessIdentity {

    /// The real executable path, via `proc_pidpath` — untruncated, unlike `kinfo_proc.p_comm`.
    ///
    /// MEASURED on this machine: 1.303 ms to resolve 383 pids, 382 resolved — the one refusal is
    /// a process that exited between listing and lookup, not a permission wall: unlike
    /// `proc_pid_rusage` and `KERN_PROCARGS2` below, `proc_pidpath` crosses the ownership
    /// boundary (verified directly: it resolves root's launchd for this non-root user, while
    /// `arguments(1)` below is refused). Use this for naming a process; do NOT read `p_comm` off
    /// `sysctl(KERN_PROC)` for the same purpose; it is a fixed
    /// 16-byte field and is silently truncated. Measured on this machine: 160 of 383 running
    /// processes sit exactly at that 16-character cap, including every single
    /// `chrome-headless-shell` — the one process this feature most needs to name correctly.
    public static func executablePath(_ pid: Int32) -> String? {
        // `PROC_PIDPATHINFO_MAXSIZE` (4 * MAXPATHLEN) is unavailable to Swift — the macro is
        // marked "structure not supported" by this SDK — so the buffer size it defines is
        // inlined here instead. MAXPATHLEN is 1024 on Darwin and has been for decades.
        var buffer = [Int8](repeating: 0, count: 4 * 1024)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else { return nil }   // gone, or not ours — never guessed at
        return String(cString: buffer)
    }

    // ── ARGV, CACHED ────────────────────────────────────────────────────────────────────────

    /// argv never changes for the life of a process — only `exec` sets it, and a process cannot
    /// re-exec into a different argv without becoming, for every purpose that matters here, a
    /// different process (new pid or not). So a successful read is cached forever, keyed by pid.
    /// A failed read is NOT cached: it is cheap to fail (one syscall returns an error immediately,
    /// it does not pay for the copy-out) and pids get reused, so caching "no" would eventually
    /// cache a wrong answer for a future, unrelated process at the same pid.
    ///
    /// Guarded the way `SystemVitals.previous` is guarded (SystemVitals.swift:220) —
    /// `nonisolated(unsafe)` on a static var — plus an explicit lock on top of it, because unlike
    /// `previous` (written once per menu tick, from one thread) this dictionary can be read by a
    /// background metrics pass and a live label render at the same time, and losing a concurrent
    /// write would mean paying the 0.371 ms cost again for nothing.
    ///
    /// KEYED ON THE PROCESS, NOT THE NUMBER. The paragraph above applied pid reuse only to
    /// failures — a success was cached forever, so once a pid came round again (macOS wraps at
    /// 99999, and this product's own premise is a machine that churns processes) the menu named
    /// a new browser after a dead one's profile. The start time is the kernel's own identity for
    /// a process: same pid, different start, different process. One small sysctl per lookup,
    /// against the 0.371 ms copy-out it saves.
    nonisolated(unsafe) private static var argvCache: [Int32: (start: UInt64, argv: [String])] = [:]
    private static let argvCacheLock = NSLock()

    /// `p_starttime` from `KERN_PROC_PID`, as one number. nil when the process is gone.
    static func startTime(_ pid: Int32) -> UInt64? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var k = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, 4, &k, &size, nil, 0) == 0, size > 0 else { return nil }
        let t = k.kp_proc.p_starttime
        return UInt64(t.tv_sec) &* 1_000_000 &+ UInt64(t.tv_usec)
    }

    /// Full argv, via `sysctl(KERN_PROCARGS2)` — the only source for it that does not truncate
    /// and does not mean shelling out to `ps` once per pid.
    ///
    /// MEASURED on this machine: 0.371 ms/pid. That is a real syscall doing a variable-size
    /// copy-out, not a cheap lookup — fine once, expensive across a 300+ process tree re-sampled
    /// every menu tick, which is why every successful read is cached (see `argvCache` above).
    public static func arguments(_ pid: Int32) -> [String]? {
        guard let start = startTime(pid) else { return nil }
        argvCacheLock.lock()
        let cached = argvCache[pid]
        argvCacheLock.unlock()
        if let cached, cached.start == start { return cached.argv }

        guard let fetched = readProcArgs(pid) else { return nil }

        argvCacheLock.lock()
        argvCache[pid] = (start, fetched)
        argvCacheLock.unlock()
        return fetched
    }

    /// The suite's window into the cache: plant an entry under a pid whose process has a
    /// different start time and prove `arguments` does not serve it.
    public static func plantCachedArgv(_ argv: [String], pid: Int32, start: UInt64) {
        argvCacheLock.lock(); argvCache[pid] = (start, argv); argvCacheLock.unlock()
    }

    /// The raw `KERN_PROCARGS2` layout: argc (4 bytes, little-endian) — the saved exec path
    /// (NUL-terminated, then zero or more padding NULs up to where argv actually starts) — then
    /// argc NUL-terminated argv strings — then envp, which nothing here reads. This is the same
    /// layout `ps` and `top` parse; there is no libproc call that hands back argv already split.
    private static func readProcArgs(_ pid: Int32) -> [String]? {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else {
            return nil   // gone, or not ours — root's and other users' processes refuse here
        }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0 else { return nil }

        let argc = Int(buffer[0]) | (Int(buffer[1]) << 8)
                  | (Int(buffer[2]) << 16) | (Int(buffer[3]) << 24)
        var offset = MemoryLayout<Int32>.size

        // Skip the saved executable path string.
        while offset < size, buffer[offset] != 0 { offset += 1 }
        // Skip the padding NULs the kernel inserts before argv[0] actually starts.
        while offset < size, buffer[offset] == 0 { offset += 1 }

        var args: [String] = []
        args.reserveCapacity(argc)
        var seen = 0
        while seen < argc, offset < size {
            let start = offset
            while offset < size, buffer[offset] != 0 { offset += 1 }
            if let s = String(bytes: buffer[start..<offset], encoding: .utf8) { args.append(s) }
            offset += 1   // step past the NUL
            seen += 1
        }
        return args
    }

    // ── THE PROFILE FLAG, PURE ──────────────────────────────────────────────────────────────

    /// `--user-data-dir` in one argv, or nil when it is not there. PURE — no pid, no syscall — so
    /// this is the one exhaustively tested without touching a live process.
    ///
    /// Chrome (and everything Chromium-shaped: Playwright, AdsPower, Dolphin) accepts the flag
    /// two ways, and both are real, not hypothetical: `--user-data-dir=/path` as one token, and
    /// the space-separated `--user-data-dir /path` as two. An empty value either way is treated
    /// as absent — a refusal, never a fabricated empty-string "profile".
    public static func userDataDir(argv: [String]) -> String? {
        let flag = "--user-data-dir"
        for (i, arg) in argv.enumerated() {
            if arg.hasPrefix(flag + "=") {
                let value = String(arg.dropFirst(flag.count + 1))
                return value.isEmpty ? nil : value
            }
            if arg == flag {
                guard i + 1 < argv.count else { return nil }
                return argv[i + 1].isEmpty ? nil : argv[i + 1]
            }
        }
        return nil
    }

    /// How far up the ppid chain to look for the browser process before giving up. Chrome's own
    /// tree is shallow — browser → renderer/GPU/utility is one hop, a network-service helper is
    /// two — so this is generous headroom, not a tuned figure.
    private static let maxAncestorHops = 32

    /// The composed answer: walk from `pid` up through its parents until one of them carries
    /// `--user-data-dir`, then name it as "<program> (<profile>)" — the directory's BASENAME, so
    /// `/Users/x/Library/Caches/ms-playwright/mcp-chrome-9ebcc11` becomes `mcp-chrome-9ebcc11`.
    ///
    /// The flag lives ONLY on the browser process itself, never on its helpers — a renderer's
    /// argv is a sandbox type and a handful of feature flags, nothing that names the profile — so
    /// a helper is unidentifiable without walking up to find the ancestor that launched it.
    ///
    /// The three lookups are injected as closures rather than called directly, so this composition
    /// is testable with fixture dictionaries and NO live process. Bounded the same way
    /// `SystemVitals.attribute`'s ppid walk is (SystemVitals.swift:146): a `seen` set stops a
    /// cycle, `maxAncestorHops` stops an unrelated, merely-deep tree from being walked to pid 1.
    public static func label(
        forPID pid: Int32,
        ppidOf: (Int32) -> Int32?,
        argvOf: (Int32) -> [String]?,
        pathOf: (Int32) -> String?
    ) -> String? {
        var current = pid
        var seen: Set<Int32> = []
        var hops = 0
        while hops < maxAncestorHops, seen.insert(current).inserted {
            if let argv = argvOf(current), let dir = userDataDir(argv: argv) {
                let base = (dir as NSString).lastPathComponent
                guard !base.isEmpty else { return nil }
                guard let execPath = pathOf(current) else { return base }
                let program = SystemVitals.commandFamily((execPath as NSString).lastPathComponent)
                return program.isEmpty ? base : "\(program) (\(base))"
            }
            guard let parent = ppidOf(current), parent > 1 else { return nil }
            current = parent
            hops += 1
        }
        return nil   // hop limit or cycle — an unattributable process is refused, not guessed
    }
}
