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
    }
}
