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
    public let tty: String        // normalised: "ttys004"
    public let cpuPercent: Double // as ps reports it: percent of ONE core
    public let residentKB: UInt64

    public init(pid: Int, tty: String, cpuPercent: Double, residentKB: UInt64) {
        self.pid = pid; self.tty = tty; self.cpuPercent = cpuPercent; self.residentKB = residentKB
    }
}

public struct SessionLoad: Sendable, Equatable {
    public let cpuPercent: Double
    public let residentBytes: UInt64
    public let processes: Int

    /// "12% · 1.2 GB". Empty when the session is doing nothing worth reporting — a row that says
    /// "0% · 4 MB" for an idle shell is noise in a menu you are scanning for the busy one.
    public var label: String {
        guard processes > 0, cpuPercent >= 1.0 || residentBytes >= 200 * 1024 * 1024 else { return "" }
        return "\(Int(cpuPercent.rounded()))% · \(SystemVitals.bytes(residentBytes))"
    }
}

public enum SystemVitals {
    /// Parse `ps -Ao pid=,tty=,pcpu=,rss=`. Pure, so the column handling is testable without ps.
    public static func parse(ps output: String) -> [ProcessSample] {
        var out: [ProcessSample] = []
        for line in output.split(separator: "\n") {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard cols.count >= 4,
                  let pid = Int(cols[0]),
                  let cpu = Double(cols[2]),
                  let rss = UInt64(cols[3]) else { continue }
            // "??" is what ps prints for a process with no controlling terminal — never empty.
            let tty = cols[1]
            guard !tty.isEmpty, tty.allSatisfy({ $0.isLetter || $0.isNumber }) else { continue }
            out.append(ProcessSample(pid: pid, tty: Session.normalise(tty: tty),
                                     cpuPercent: cpu, residentKB: rss))
        }
        return out
    }

    /// Everything running on one terminal, added up: the agent, its node processes, its children.
    public static func load(forTTY tty: String, in samples: [ProcessSample]) -> SessionLoad {
        let mine = samples.filter { $0.tty == Session.normalise(tty: tty) }
        return SessionLoad(cpuPercent: mine.reduce(0) { $0 + $1.cpuPercent },
                           residentBytes: mine.reduce(0) { $0 + $1.residentKB } * 1024,
                           processes: mine.count)
    }

    public static func sample() -> [ProcessSample] {
        parse(ps: Shell.run("ps", ["-Ao", "pid=,tty=,pcpu=,rss="]).out)
    }

    // MARK: - Temperature

    /// `ioreg -c AppleSmartBattery -r` reports `"Temperature" = 3072` — centi-degrees Celsius.
    /// Values outside 0–80 °C are a misread, not a hot Mac, so they are refused.
    public static func batteryCelsius(fromIOReg output: String) -> Double? {
        guard let line = output.split(separator: "\n").first(where: {
            $0.contains("\"Temperature\"") && $0.contains("=")
        }) else { return nil }
        let digits = line.split(separator: "=").last?.trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"; "))
        guard let raw = digits.flatMap({ Double($0) }) else { return nil }
        let celsius = raw / 100
        return (0...80).contains(celsius) ? celsius : nil
    }

    public static func temperature() -> Double? {
        batteryCelsius(fromIOReg: Shell.run("ioreg", ["-c", "AppleSmartBattery", "-r"]).out)
    }

    public static func fahrenheit(_ celsius: Double) -> Double { celsius * 9 / 5 + 32 }

    /// "31 °C · 88 °F". Both, because you asked for both.
    public static func temperatureLabel(_ celsius: Double) -> String {
        String(format: "%.0f °C · %.0f °F", celsius, fahrenheit(celsius))
    }

    /// The system's own view of how hard it is being pushed. A native API, no privileges, and the
    /// only honest answer to "is my Mac struggling" that does not need root.
    public static func thermalPressure(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal:  return "normal"
        case .fair:     return "warm"
        case .serious:  return "hot — fans up, throttling soon"
        case .critical: return "critical — throttling now"
        @unknown default: return "unknown"
        }
    }

    public static func bytes(_ count: UInt64) -> String {
        let gb = Double(count) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        return "\(count / 1_048_576) MB"
    }
}
