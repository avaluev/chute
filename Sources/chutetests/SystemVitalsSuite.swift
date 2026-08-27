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
        T.ok(busy.label.hasSuffix("memory"), "and the size says what it measures: \(busy.label)")

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

        // The busiest process on the machine, by name — the answer to "why is my Mac hot".
        T.eq(SystemVitals.busiest(tree)?.command, "chrome-headless-shell",
             "the busiest process is found and named by its basename")
        T.eq(SystemVitals.busiest([])?.command, nil, "no processes is no busiest, not a crash")

        // The This-Mac line: every claim is a MEASUREMENT from the same snapshot as the rows.
        // "running cool" next to a 171% row and a hot chassis is why this exists — nominal
        // thermal state now says nothing instead of editorialising "cool".
        let line = SystemVitals.machineLine(samples: tree, cores: 12,
                                            thermal: .nominal, batteryCelsius: 30.72)
        T.ok(line.hasPrefix("This Mac — using 1.3 of 12 cores"),
             "total CPU is the sum of the SAME samples the rows show: \(line)")
        T.ok(line.contains("busiest: chrome-headless-shell at 120% CPU"),
             "the burner is named on the same line: \(line)")
        T.ok(line.contains("battery at 31 °C"), "the battery says it is the battery: \(line)")
        T.ok(!line.contains("cool"), "nominal thermal state claims NOTHING: \(line)")
        T.ok(SystemVitals.machineLine(samples: tree, cores: 12,
                                      thermal: .serious, batteryCelsius: nil)
                .contains("slow down"), "an elevated thermal state IS said, in words")
        let quiet = SystemVitals.machineLine(samples: [], cores: 12,
                                             thermal: .nominal, batteryCelsius: nil)
        T.eq(quiet, "This Mac — using 0.0 of 12 cores", "no burner, no battery: just the number")

        // An idle shell says nothing. A row reading "0% · 4 MB" is noise in a list you are
        // scanning to find the busy one.
        T.eq(SystemVitals.load(forTTY: "s002", in: samples).label, "", "an idle session stays quiet")
        T.eq(SystemVitals.load(forTTY: "ttys999", in: samples).processes, 0, "an unknown tty is empty")
        T.eq(SystemVitals.load(forTTY: "/dev/s001", in: samples).processes, 2,
             "a /dev-prefixed tty matches the same session")

        // Temperature: ioreg reports centi-degrees Celsius.
        let ioreg = #"      "Temperature" = 3072"#
        T.eq(SystemVitals.batteryCelsius(fromIOReg: ioreg), 30.72, "3072 is 30.72 °C")
        T.eq(SystemVitals.fahrenheit(30.0), 86.0, "30 °C is 86 °F")
        T.eq(SystemVitals.temperatureLabel(30.72), "31 °C · 87 °F", "both units, rounded, as asked")

        // A misread is refused rather than reported as a hot Mac.
        T.ok(SystemVitals.batteryCelsius(fromIOReg: #""Temperature" = 999999"#) == nil,
             "an impossible reading is refused")
        T.ok(SystemVitals.batteryCelsius(fromIOReg: "no temperature here") == nil,
             "a missing sensor is nil, not zero")
        T.ok(SystemVitals.batteryCelsius(fromIOReg: #""Temperature" = -500"#) == nil,
             "and so is a negative one")

        T.eq(SystemVitals.thermalPressure(.nominal), "running cool", "thermal pressure reads as words")
        T.ok(SystemVitals.thermalPressure(.serious).contains("slow down"),
             "and a serious state says what it means for your work, not just its severity")

        T.eq(SystemVitals.bytes(1_610_612_736), "1.5 GB", "gigabytes to one decimal")
        T.eq(SystemVitals.bytes(524_288_000), "500 MB", "megabytes whole")

        // The real machine, so the parsing is proved against live output, not only a fixture.
        let live = SystemVitals.sample()
        T.ok(live.count > 5, "the real process table parses (\(live.count) processes)")
        T.ok(live.allSatisfy { $0.pid >= 0 }, "every live sample is well formed")
    }
}
