import Foundation
import ChuteCore

func processMetricsSuite() {
    T.suite("ProcessMetrics") {
        // These read the LIVE machine — there is no fixture for "how much memory does this
        // process hold". So the assertions are about shape and about the two properties that
        // actually matter: it works for our own processes without privileges, and it refuses
        // rather than lying about processes it cannot see.
        let me = ProcessInfo.processInfo.processIdentifier

        let mem = ProcessMetrics.footprint(me)
        T.ok(mem != nil, "our own footprint is readable with no root and no entitlement")
        T.ok((mem ?? 0) > 1_000_000, "and it is a plausible size for a running test binary")

        T.eq(ProcessMetrics.footprint(999_999), nil, "a pid that does not exist is nil, not zero")
        T.eq(ProcessMetrics.cpuNanos(999_999), nil, "and so is its CPU")

        // launchd is root-owned. We are not root, so this must come back nil — and the code must
        // treat that as "not ours to report", never as 0 bytes.
        T.eq(ProcessMetrics.footprint(1), nil, "a process we may not inspect is refused, not guessed")

        let a = ProcessMetrics.cpuNanos(me)
        T.ok(a != nil, "CPU time is readable for our own process")
        var spin = 0.0
        for i in 0..<2_000_000 { spin += Double(i).squareRoot() }
        T.ok(spin > 0, "the loop is not optimised away")
        let b = ProcessMetrics.cpuNanos(me)
        T.ok((b ?? 0) > (a ?? 0), "and it goes UP after doing work — it is a counter, not a gauge")

        // THE WHOLE POINT OF SAMPLING TWICE. `ps -o pcpu` reports a LIFETIME AVERAGE since the
        // process started: measured 2026-08-28, ps said Google Chrome was at 21.4% while a real
        // one-second measurement put it at 0.5%. For a menu answering "is this agent working
        // RIGHT NOW", that is the wrong question answered to one decimal place.
        let before = ProcessMetrics.snapshot()
        T.ok(before[me] != nil, "a snapshot includes our own process")
        T.ok(before.count > 5, "and the rest of the machine: \(before.count) processes")

        let pct = ProcessMetrics.cpuPercent(pid: me, from: before,
                                            to: ProcessMetrics.snapshot(), seconds: 1.0)
        T.ok(pct != nil, "two snapshots and an interval give a percentage")
        T.ok(pct! >= 0, "which is never negative: \(pct!)")

        T.eq(ProcessMetrics.cpuPercent(pid: me, from: before, to: before, seconds: 0), nil,
             "a zero-length interval is refused rather than dividing by it")

        // THE TIMEBASE, GUARDED. pti_total_user is in MACH ABSOLUTE TIME units, not nanoseconds.
        // On Intel the timebase is 1/1 so they are the same and reading them as nanoseconds is
        // silently correct; this Mac reports 125/3, one tick is 41.67 ns, and the naive reading
        // under-reports CPU by 24×. It was caught by a busy loop that pinned one core and
        // measured 2.4%.
        //
        // So: burn a core on purpose and assert the answer is in the right ORDER OF MAGNITUDE.
        // A loose band on purpose — a shared CI machine is not a quiet one — but 24× wrong falls
        // far outside it in either direction.
        let mark = ProcessMetrics.snapshot(pids: [me])
        let started = Date()
        var burn = 0.0
        while Date().timeIntervalSince(started) < 0.3 { burn += Double.random(in: 0...1).squareRoot() }
        let elapsed = Date().timeIntervalSince(started)
        T.ok(burn > 0, "the burn loop is not optimised away")
        let busy = ProcessMetrics.cpuPercent(pid: me, from: mark,
                                             to: ProcessMetrics.snapshot(pids: [me]),
                                             seconds: elapsed)
        T.ok((busy ?? 0) > 25,
             "a thread spinning flat out reads as real CPU, not as 24× less: \(busy ?? -1)%")
        T.ok((busy ?? 0) < 2000, "and not as 24× more: \(busy ?? -1)%")

        // ── A REFUSAL IS NEVER A ZERO, PINNED ───────────────────────────────────────────────
        //
        // The research this file was written against claimed `proc_pid_rusage` returns rc 0 with
        // a ZEROED struct for another user's process. If that were true, every one of them would
        // read "0 bytes, 0% CPU" — a silent wrong number, which is worse than a gap, because a
        // gap is visible and a zero is not.
        //
        // Measured on this machine 2026-08-28 and it is NOT true: 169 pids scanned, 0 returned
        // rc 0 for a uid that was not ours, 14 refused outright, pid 1 gives EPERM. So the code
        // keeps `rc == 0 ? info : nil` — and this pins it, so a future macOS that starts handing
        // back zeros fails the build instead of quietly halving every figure in the menu.
        // Root's processes, named by the same sysctl the listing uses. `proc_pidinfo` cannot be
        // asked this question — it is refused for another user's pid too, so using it to FIND
        // them returns an empty set and the test would pass by finding nothing to check.
        let others = ProcessMetrics.listing(uid: 0).map(\.pid)
        T.ok(!others.isEmpty, "this machine runs processes owned by root: \(others.count)")
        let leaked = others.filter { ProcessMetrics.footprint($0) != nil }
        T.eq(leaked.count, 0,
             "not one of them returns a reading — a refusal is refused, never zeroed: \(leaked.prefix(3))")

        // ── THE PEAK, WHICH IS THE ONLY ANSWER TO "WHY DID IT EAT 9 GB?" ────────────────────
        //
        // ri_phys_footprint is an instant. By the time anyone opens a menu to look, the spike is
        // over and every tool on the machine agrees nothing happened. The kernel keeps the
        // high-water mark, and it survives the release.
        let peak = ProcessMetrics.peakFootprint(me)
        T.ok(peak != nil, "our own high-water mark is readable")
        T.ok((peak ?? 0) >= (ProcessMetrics.footprint(me) ?? 0),
             "and it is never below what we hold right now: \(peak ?? 0) vs \(mem ?? 0)")
        T.eq(ProcessMetrics.peakFootprint(999_999), nil, "a pid that does not exist has no peak")

        // Prove it actually RECORDS a spike rather than tracking the present. Touch 300 MB, free
        // it, and the peak must remember what the footprint has already forgotten.
        let before300 = ProcessMetrics.peakFootprint(me) ?? 0
        var hog: [UInt8]? = [UInt8](repeating: 7, count: 300 * 1_048_576)
        T.ok(hog?.count == 300 * 1_048_576, "300 MB really allocated")
        hog = nil
        let after300 = ProcessMetrics.peakFootprint(me) ?? 0
        T.ok(after300 >= before300 + 200 * 1_048_576,
             "the peak recorded a spike the footprint has already released: "
           + "\(before300 / 1_048_576) MB → \(after300 / 1_048_576) MB")

        // ── PID RECYCLING ────────────────────────────────────────────────────────────────────
        //
        // Diffing a counter assumes both ends came from the same process. A pid is reused, so
        // between two samples the pid can belong to something else whose counter starts at zero
        // — and the subtraction then reports that new process's entire lifetime as if it had been
        // burned inside our two-second window. Same pid AND same start time, or there is no rate.
        let real = ProcessMetrics.snapshot(pids: [me])
        T.ok((real[me]?.startAbstime ?? 0) > 0, "a sample carries the process's start time")
        let impostor = [me: ProcessMetrics.Sample(
            footprintBytes: 0, cpuNanos: (real[me]?.cpuNanos ?? 0) + 1,
            peakFootprintBytes: 0, startAbstime: (real[me]?.startAbstime ?? 0) &+ 1)]
        T.eq(ProcessMetrics.cpuPercent(pid: me, from: real, to: impostor, seconds: 1.0), nil,
             "a recycled pid yields no rate at all, rather than a plausible invented one")
        T.ok(ProcessMetrics.cpuPercent(pid: me, from: real, to: real, seconds: 1.0) != nil,
             "while the same process across two samples still gives one")

        // ── THE 117 ms `ps` FORK, GONE ──────────────────────────────────────────────────────
        //
        // The tree used to come from `ps -Axo …` — measured at 117 ms on this machine, paid on
        // the path a user is already waiting on. It now comes from sysctl + devname + pidpath.
        let rows = ProcessMetrics.listing()
        T.ok(rows.count > 5, "the listing sees the machine: \(rows.count) processes of ours")
        T.ok(rows.allSatisfy { $0.pid > 0 }, "every row has a real pid")
        T.no(rows.contains { $0.command.isEmpty }, "and every row is named")

        // THE 16-CHARACTER TRAP. kinfo_proc.p_comm is right there in the struct and looks like
        // the answer, but the kernel truncates it: measured, 160 of 383 of our processes sit at
        // the cap and every chrome-headless-shell arrives as "chrome-headless-". commandFamily
        // matches on the name, so a listing built from p_comm stops recognising Chrome — quietly,
        // with a plausible string. Names must come from proc_pidpath.
        //
        // ASSERTED AS "SOMETHING IS LONGER THAN THE CAP", which is the only form of this that
        // actually fires. The first attempt looked for a 16-character name ending in a hyphen —
        // it matched `chrome-headless-` and felt like a test, but swapping the implementation
        // back to `p_comm` left it GREEN, because most truncations do not end in a hyphen. A
        // guard that does not go red when the bug is reintroduced is not a guard.
        //
        // p_comm CANNOT produce a name longer than 16 characters. proc_pidpath does it constantly
        // — every Mac runs something with a long name. So one name over the cap proves, by
        // construction, that the truncating source is not in use.
        let longest = rows.map(\.command).max { $0.count < $1.count } ?? ""
        T.ok(longest.count > 16,
             "names come from the executable path, not the 16-char p_comm: longest is "
           + "\"\(longest)\" (\(longest.count) chars)")

        // ── AND THE TRAP ON THE OTHER SIDE ──────────────────────────────────────────────────
        //
        // Caught in the live menu, not in review: Claude Code installs as
        // ~/.local/share/claude/versions/2.1.250 — the executable file IS the version string —
        // so taking the path's basename made every agent row read "mostly 2.1.250".
        //
        // The first fix was to fall back to p_comm, on the evidence that `ps -o comm=` prints
        // "claude". That fix did NOT change the menu, because ps prints argv[0] and p_comm here
        // is "2.1.250" as well. Every one-string source is wrong; the program's name is in the
        // PATH, one level up. Asserted with comm deliberately set to the WRONG value, so this
        // cannot pass by accident the way the p_comm version did.
        T.eq(ProcessMetrics.programName(path: "/Users/x/.local/share/claude/versions/2.1.250",
                                        comm: "2.1.250"),
             "claude", "a binary named after its version is called by its program name")
        T.eq(ProcessMetrics.programName(path: "/opt/homebrew/Cellar/node/22.1.0/bin/node",
                                        comm: "node"),
             "node", "and a versioned install whose binary IS named keeps that name")
        T.eq(ProcessMetrics.programName(
                path: "/Users/x/Library/Caches/ms-playwright/chromium-1217/chrome-headless-shell",
                comm: "chrome-headless-"),
             "chrome-headless-shell", "and a long name is NOT thrown away for the truncated one")
        T.eq(ProcessMetrics.programName(path: "/bin/zsh", comm: "zsh"), "zsh",
             "an ordinary path is just its basename")
        T.eq(ProcessMetrics.programName(path: nil, comm: "gone"), "gone",
             "a process that died mid-listing still gets the name the kernel had")

        // The version test has to be narrow, or it would discard good names to fix bad ones.
        T.ok(ProcessMetrics.looksLikeAVersion("2.1.250"), "2.1.250 is a version")
        T.ok(ProcessMetrics.looksLikeAVersion("v18.20.4"), "and so is v18.20.4")
        T.no(ProcessMetrics.looksLikeAVersion("python3.11"), "python3.11 is a PROGRAM")
        T.no(ProcessMetrics.looksLikeAVersion("chrome-headless-shell"), "and so is chrome-headless-shell")
        T.no(ProcessMetrics.looksLikeAVersion("node"), "and so is node")

        // The end-to-end form of the same thing: no row in a real listing is a bare version.
        T.no(rows.contains { ProcessMetrics.looksLikeAVersion($0.command) },
             "and nothing on this machine is labelled with a bare version number")

        // THE UNLINKED BINARY. The assertion above went red on 2026-09-03 for a real reason:
        // Claude Code had auto-updated, the running session's binary `versions/2.1.250` was gone
        // from disk, proc_pidpath fails with ENOENT for an unlinked executable, and the row fell
        // back to p_comm — the bare "2.1.250" this whole rule exists to prevent. Reproduced here
        // exactly: a version-named copy of `sleep` under a `versions/` directory, started, then
        // deleted while it runs. The kernel's exec-args block still knows the path.
        let program = FileManager.default.temporaryDirectory
            .appendingPathComponent("chute-unlinked-\(getpid())", isDirectory: true)
            .appendingPathComponent("fakeprog", isDirectory: true)
            .appendingPathComponent("versions", isDirectory: true)
        try? FileManager.default.createDirectory(at: program, withIntermediateDirectories: true)
        let binary = program.appendingPathComponent("9.9.9")
        try? FileManager.default.removeItem(at: binary)
        try? FileManager.default.copyItem(atPath: "/bin/sleep", toPath: binary.path)
        let child = Process()
        child.executableURL = binary
        child.arguments = ["30"]
        if (try? child.run()) != nil {
            try? FileManager.default.removeItem(at: binary)
            let row = ProcessMetrics.listing().first { $0.pid == child.processIdentifier }
            T.eq(row?.command, "fakeprog",
                 "a process whose version-named binary was deleted underneath it (an agent that "
               + "auto-updated) is still named by its program, not its version")
            child.terminate()
            child.waitUntilExit()
        } else {
            T.ok(false, "could not start the unlinked-binary fixture at \(binary.path)")
        }
        try? FileManager.default.removeItem(at: program.deletingLastPathComponent().deletingLastPathComponent())
        T.ok(rows.contains { $0.pid == me }, "our own process is in it")
        T.ok(rows.first(where: { $0.pid == me })?.command.contains("chutetests") == true,
             "under its real name: \(rows.first(where: { $0.pid == me })?.command ?? "-")")

        // Only ever our own. Another user's processes were never ours to report, and carrying
        // them just to drop them later is how a zero ends up standing in for a refusal.
        T.no(rows.contains { other in others.contains(other.pid) },
             "and nothing belonging to another user is in the listing at all")

        // The tty must agree with the kernel's own naming. Cross-checked against `ps -o tty=`
        // when this was written: 658 agreed, 0 disagreed.
        T.ok(rows.allSatisfy { $0.tty.isEmpty || $0.tty.hasPrefix("tty") || $0.tty.hasPrefix("cons") },
             "a tty is named the way the system names it, or is honestly absent")

        // THE BUDGET. 117 ms was the old cost of the `ps` fork, paid on every menu open. This is
        // 0.88 ms measured 2026-08-28 — but it was 17.8 ms until the devname cache went in, and
        // that is exactly the regression this threshold exists to catch: name the five terminals
        // once instead of once per process, or 94% of the win goes back to naming ttys. Five is
        // loose enough for a busy machine and tight enough that losing the cache fails the build.
        var fastest = Double.greatestFiniteMagnitude
        for _ in 0..<5 {
            let t0 = DispatchTime.now().uptimeNanoseconds
            _ = ProcessMetrics.listing()
            fastest = min(fastest, Double(DispatchTime.now().uptimeNanoseconds - t0) / 1_000_000)
        }
        T.ok(fastest < 5, "the listing costs \(String(format: "%.2f", fastest)) ms, against 117 ms for the ps fork it replaced")
    }
}
