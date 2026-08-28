import Foundation
import ChuteCore

func systemVitalsSuite() {
    T.suite("SystemVitals") {
        // Real `ps -Axo pid=,ppid=,tty=,pcpu=,rss=,comm=` output, including the shapes that break
        // naive parsing: "??" for no controlling terminal, multiple processes on one tty, a comm
        // that is a full path, and a comm with spaces in it.
        let sample = """
            1     0   ??   0.0  19856 /sbin/launchd
        33176     1 s001  12.5 512000 /opt/homebrew/bin/node
        33180 33176 s001   3.5 128000 node
        54361     1 s002   0.0   4096 -zsh
        90588     1 ttys003  0.7  8192 next-server (v16.1.1)
        garbage line
        """
        let samples = SystemVitals.parse(ps: sample)
        T.eq(samples.count, 5, "every process parses — detached ones too; only garbage is skipped")
        T.eq(samples.first(where: { $0.pid == 1 })?.tty, "", "?? becomes empty — detached, not a terminal")
        T.eq(samples.first(where: { $0.pid == 33176 })?.command, "node", "a path comm is its basename")
        T.eq(samples.first(where: { $0.pid == 90588 })?.command, "next-server (v16.1.1)",
             "a comm with spaces survives whole")

        // A terminal's cost is everything running on it — the agent, its node processes, its children.
        let busy = SystemVitals.load(forTTY: "s001", in: samples)
        T.eq(busy.processes, 2, "both processes on the tty are counted")
        T.eq(busy.cpuPercent, 16.0, "their CPU adds up")
        T.eq(busy.residentBytes, 640_000 * 1024, "and so does their memory")
        T.ok(busy.label.contains("16%"), "the row reads '16% · …': \(busy.label)")
        T.ok(busy.label.contains("MB memory"), "and the size says what it measures: \(busy.label)")
        T.ok(busy.label.hasSuffix("mostly node"),
             "and when one program holds most of it, the row names it — that is the half you can "
           + "act on: \(busy.label)")

        // THE HOT-MAC BUG. An agent's real work happens in spawned children that DROP the tty:
        // claude (ttys004) → zsh (??) → npm (??) → chrome-headless-shell (??) at 120%. The menu
        // summed only tty-attached processes, so a session running a Playwright suite read
        // "0% CPU" while the chassis burned. Captured from this machine on 2026-08-27.
        let tree = SystemVitals.parse(ps: """
        70180 69994 ttys004  0.5 360000 claude
          772 70180   ??   0.0   4000 /bin/zsh
          776   772   ??   0.0   3000 bash
          894   776   ??   1.0  90000 npm exec playwright test
        16699   894   ??   2.0  80000 node
        16702 16699   ??  120.3 500000 /Users/sxope/Library/Caches/ms-playwright/chrome-headless-shell
          364     1   ??   7.2  60000 /System/Library/WindowServer
        """)
        let attributed = SystemVitals.attribute(tree)
        T.eq(attributed.first(where: { $0.pid == 16702 })?.tty, "ttys004",
             "a detached burner is attributed to the terminal it descends from")
        let session = SystemVitals.load(forTTY: "ttys004", in: attributed)
        T.eq(session.processes, 6, "the whole tree belongs to the session")
        T.ok(session.cpuPercent > 120, "and the session's CPU tells the truth: \(session.cpuPercent)%")
        T.eq(attributed.first(where: { $0.pid == 364 })?.tty, "",
             "a system daemon under launchd is attributed to nobody")

        // A cyclic or self-parenting table must terminate, not hang the menu.
        let cyclic = [ProcessSample(pid: 5, ppid: 5, command: "x", tty: "", cpuPercent: 1, residentKB: 1)]
        T.eq(SystemVitals.attribute(cyclic).first?.tty, "", "a self-parenting pid ends the climb")

        // DELETED WITH THE CODE THEY COVERED: busiest, machineLine, and the whole battery
        // temperature path. The menu line they backed said "This Mac — using 0.4 of 16 cores ·
        // battery at 31 °C · 87 °F", and two of those three claims were not worth reading: the
        // battery sensor does not track how hot the chassis gets under an agent workload, and a
        // whole-machine core average never explained why anything was slow. These tests passed
        // and the feature was still wrong, which is the only kind of test worth deleting.

        // EVERY SESSION REPORTS, INCLUDING THE QUIET ONES. `label` used to go empty below 1% CPU
        // and 200 MB, on the theory that "0% CPU · 4 MB memory" was noise. Owner's call,
        // 2026-08-28: these numbers are the useful part of the row. A blank where a number belongs
        // reads as "not measured", and a reader comparing five agents needs all five figures, not
        // only the ones something decided were interesting.
        T.ok(SystemVitals.load(forTTY: "s002", in: samples).label.hasPrefix("0% CPU · 4 MB memory"),
             "a quiet session still reports")
        T.eq(SystemVitals.load(forTTY: "ttys999", in: samples).label, "",
             "but a tty with no processes at all has nothing to report")
        T.eq(SystemVitals.load(forTTY: "ttys999", in: samples).processes, 0, "an unknown tty is empty")
        T.eq(SystemVitals.load(forTTY: "/dev/s001", in: samples).processes, 2,
             "a /dev-prefixed tty matches the same session")


        T.eq(SystemVitals.bytes(1_610_612_736), "1.5 GB", "gigabytes to one decimal")
        T.eq(SystemVitals.bytes(524_288_000), "500 MB", "megabytes whole")

        // The real machine, so the parsing is proved against live output, not only a fixture.
        let live = SystemVitals.sample()
        T.ok(live.count > 5, "the real process table parses (\(live.count) processes)")
        T.ok(live.allSatisfy { $0.pid >= 0 }, "every live sample is well formed")

        // ── WHAT IS EATING IT, NOT JUST HOW MUCH ────────────────────────────────────────────
        //
        // The menu said "sntz_mockups · 5.0 GB memory" while the actual whale was a Next.js dev
        // server holding every compiled route's module graph. The reader cannot act on 5.0 GB:
        // "the agent is huge" and "your dev server needs restarting" are different problems with
        // different fixes, and the number alone cannot tell them apart.
        let whale = SystemVitals.attribute(SystemVitals.parse(ps: """
            900   1   s009    1.0  700000   /usr/local/bin/claude
            901 900   ??      2.0 6400000   /Users/x/app/node_modules/.bin/next-server
            902 900   ??      0.5  200000   /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
            903 902   ??      0.5  180000   Google Chrome Helper (Renderer)
            904 902   ??      0.5  170000   Google Chrome Helper (GPU)
            """))
        let big = SystemVitals.load(forTTY: "s009", in: whale)
        T.eq(big.top?.command, "next-server", "the dominant process is named")
        T.ok(big.top!.bytes > 6_000_000_000, "with what it is actually holding")
        T.ok(big.label.contains("mostly next-server"),
             "and the row says so, because that is the half you can act on: \(big.label)")

        // GROUPED BY COMMAND FAMILY. Chrome is six processes and one program — the reader's own
        // analysis of this said "Your Google Chrome (6 renderers) ~2.5 GB", because that is how a
        // person thinks about it. Three separate 180 MB rows are three numbers and no answer.
        let chromeOnly = SystemVitals.attribute(SystemVitals.parse(ps: """
            900   1   s010    1.0   50000   /usr/local/bin/claude
            902 900   ??      0.5  900000   /Applications/Google Chrome.app/Contents/MacOS/Google Chrome
            903 902   ??      0.5  800000   Google Chrome Helper (Renderer)
            904 902   ??      0.5  700000   Google Chrome Helper (GPU)
            """))
        T.eq(SystemVitals.load(forTTY: "s010", in: chromeOnly).top?.command, "Google Chrome",
             "helpers are counted as the program they belong to")

        // QUIET WHEN NOTHING DOMINATES. A session split evenly across its processes has no
        // culprit, and naming the largest of five similar things would point at nothing.
        let even = SystemVitals.attribute(SystemVitals.parse(ps: """
            900   1   s011    1.0  300000   /usr/local/bin/claude
            901 900   ??      1.0  280000   node
            902 900   ??      1.0  270000   Python
            903 900   ??      1.0  260000   ruby
            """))
        T.no(SystemVitals.load(forTTY: "s011", in: even).label.contains("mostly"),
             "no single process is the story, so none is named")

        T.eq(SystemVitals.commandFamily("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
             "Google Chrome", "a path becomes the program")
        T.eq(SystemVitals.commandFamily("Google Chrome Helper (Renderer)"), "Google Chrome",
             "and so does a helper")
        T.eq(SystemVitals.commandFamily("/opt/homebrew/bin/node"), "node", "a plain binary is itself")

        // ── ATTRIBUTION SURVIVES REPARENTING ────────────────────────────────────────────────
        //
        // Walking ppid until a tty turns up loses the branch the moment anything is reparented to
        // launchd — a double-forked daemon, or a child whose parent exited first. `pstree` and
        // htop's tree view have the same blind spot.
        //
        // The Unix SESSION ID does not: every descendant of a login shell inherits its sid, and
        // reparenting does not change it. Verified on this machine 2026-08-28 — getsid() answers
        // for another user's process and even for pid 1, unprivileged. `ps -o sess=` is NOT the
        // way to get it: kp_eproc.e_sess is NULL for non-root, so ps prints 0 for everything.
        let orphaned = SystemVitals.attribute(SystemVitals.parse(ps: """
            700   1   s004    1.0  100000   -zsh
            701 700   ??      1.0  200000   claude
            702   1   ??      5.0  900000   next-server
            """, sids: [700: 700, 701: 700, 702: 700]))
        T.eq(orphaned.first { $0.pid == 702 }?.tty, "s004",
             "a process reparented to launchd is still attributed by its session id")
        T.eq(SystemVitals.load(forTTY: "s004", in: orphaned).processes, 3,
             "so the session accounts for everything it started")

        // Without sids it falls back to the ppid walk, which finds 701 and loses 702.
        let ppidOnly = SystemVitals.attribute(SystemVitals.parse(ps: """
            700   1   s004    1.0  100000   -zsh
            701 700   ??      1.0  200000   claude
            702   1   ??      5.0  900000   next-server
            """))
        T.eq(ppidOnly.first { $0.pid == 701 }?.tty, "s004", "the ppid chain still works when it can")
        T.eq(ppidOnly.first { $0.pid == 702 }?.tty, "", "and an orphan is honestly unattributed")

        // A session whose leader has no terminal belongs to nobody — a launchd daemon must not be
        // billed to whichever terminal happens to sort first.
        let daemon = SystemVitals.attribute(SystemVitals.parse(ps: """
            700   1   s004    1.0  100000   -zsh
            800   1   ??      9.0  500000   some-daemon
            """, sids: [700: 700, 800: 800]))
        T.eq(daemon.first { $0.pid == 800 }?.tty, "", "a session with no tty attributes to nothing")
    }
}
