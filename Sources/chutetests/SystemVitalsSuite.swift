import Foundation
import ChuteCore

func systemVitalsSuite() {
    T.suite("SystemVitals") {
        // Real `ps -Ao pid=,tty=,pcpu=,rss=` output, including the two shapes that break naive
        // parsing: "??" for no controlling terminal, and multiple processes on one tty.
        let sample = """
            1     ??   0.0  19856
        33176 s001  12.5 512000
        33180 s001   3.5 128000
        54361 s002   0.0   4096
        90588 ttys003  0.7  8192
        garbage line
        """
        let samples = SystemVitals.parse(ps: sample)
        T.eq(samples.count, 4, "the daemon on ?? and the garbage line are both skipped")
        T.ok(!samples.contains { $0.tty == "??" }, "?? is never treated as a terminal")

        // A terminal's cost is everything running on it — the agent, its node processes, its children.
        let busy = SystemVitals.load(forTTY: "s001", in: samples)
        T.eq(busy.processes, 2, "both processes on the tty are counted")
        T.eq(busy.cpuPercent, 16.0, "their CPU adds up")
        T.eq(busy.residentBytes, 640_000 * 1024, "and so does their memory")
        T.ok(busy.label.contains("16%"), "the row reads '16% · …': \(busy.label)")
        T.ok(busy.label.contains("GB") || busy.label.contains("MB"), "with a human size")

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

        T.eq(SystemVitals.thermalPressure(.nominal), "normal", "thermal pressure reads as words")
        T.ok(SystemVitals.thermalPressure(.serious).contains("throttling"),
             "and a serious state says what it means for you")

        T.eq(SystemVitals.bytes(1_610_612_736), "1.5 GB", "gigabytes to one decimal")
        T.eq(SystemVitals.bytes(524_288_000), "500 MB", "megabytes whole")

        // The real machine, so the parsing is proved against live output, not only a fixture.
        let live = SystemVitals.sample()
        T.ok(live.count > 5, "the real process table parses (\(live.count) processes)")
        T.ok(live.allSatisfy { $0.pid > 0 && !$0.tty.isEmpty }, "every live sample is well formed")
    }
}
