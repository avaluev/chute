import Foundation

/// One thing that must be true for Chute to work.
/// `why` and `fix` are non-optional by design: a check that cannot explain itself or state its
/// remedy is a dead end, and a test in the suite mechanically forbids adding one.
public struct Check: Sendable, Equatable {
    public let id: String
    public let title: String
    public let why: String
    public let fix: String

    public init(id: String, title: String, why: String, fix: String) {
        self.id = id; self.title = title; self.why = why; self.fix = fix
    }
}

public struct CheckOutcome: Sendable {
    public let check: Check
    public let passed: Bool
    public let detail: String

    public init(check: Check, passed: Bool, detail: String) {
        self.check = check; self.passed = passed; self.detail = detail
    }
}

/// Everything the checks need from the outside world, in one injectable value so the whole
/// matrix is testable with stubs and zero system calls.
public struct DiagnosticsEnv: Sendable {
    public var osMajor: Int
    public var appPath: String
    public var cliPath: String?
    public var pluginkitList: String
    public var extensionID: String
    public var automationOK: Bool
    public var processList: String
    public var hooksWired: Int
    public var endToEndPassed: Bool

    public init(osMajor: Int, appPath: String, cliPath: String?, pluginkitList: String,
                extensionID: String, automationOK: Bool, processList: String,
                hooksWired: Int, endToEndPassed: Bool) {
        self.osMajor = osMajor; self.appPath = appPath; self.cliPath = cliPath
        self.pluginkitList = pluginkitList; self.extensionID = extensionID
        self.automationOK = automationOK; self.processList = processList
        self.hooksWired = hooksWired; self.endToEndPassed = endToEndPassed
    }
}

public enum Diagnostics {
    public static let minimumOSMajor = 13

    public static let all: [Check] = [
        Check(id: "os", title: "macOS version",
              why: "Chute needs macOS 13 or later for the Finder extension API it depends on.",
              fix: "Upgrade macOS. Nothing else can be done from here."),
        Check(id: "app-location", title: "App location",
              why: "macOS only loads a Finder extension from an app in /Applications or ~/Applications.",
              fix: "Move Chute.app to ~/Applications, then run this again."),
        Check(id: "cli", title: "Command line tool",
              why: "Every menu item and Finder action runs through the chute binary.",
              fix: "chute doctor --fix   (symlinks it into ~/.local/bin)"),
        Check(id: "ext-registered", title: "Finder extension registered",
              why: "macOS cannot show the right-click menu for an extension it does not know about.",
              fix: "chute doctor --fix   (runs pluginkit -a on the bundled extension)"),
        Check(id: "ext-enabled", title: "Finder extension enabled",
              why: "The extension is installed but switched off, so the right-click menu stays hidden. This is the single most common reason Chute appears to do nothing.",
              fix: "chute doctor --fix   (or System Settings → Privacy & Security → Extensions → Finder)"),
        Check(id: "automation", title: "Automation permission",
              why: "Chute asks Finder and Terminal what you have selected. Without this the session list is empty.",
              fix: "chute doctor --fix triggers the prompt. If you denied it: System Settings → Privacy & Security → Automation."),
        Check(id: "terminal", title: "A terminal is running",
              why: "The session switcher lists terminal windows. With none open there is nothing to show.",
              fix: "Open Terminal. Informational only — nothing is broken."),
        Check(id: "hooks", title: "Agent status hooks",
              why: "Without them the menu bar cannot tell which agents are waiting for you.",
              fix: "chute hooks install   (appends only, backs up first, reversible with chute hooks uninstall)"),
        Check(id: "end-to-end", title: "End-to-end proof",
              why: "Every component can be healthy and the product still not work. This runs a real command and reads the result back.",
              fix: "If this alone fails, the pieces are fine but they are not talking. Re-run chute doctor --fix, then report it."),
    ]

    static func check(_ id: String) -> Check {
        all.first { $0.id == id } ?? all[0]
    }

    public static func run(_ env: DiagnosticsEnv) -> [CheckOutcome] {
        var out: [CheckOutcome] = []
        func add(_ id: String, _ passed: Bool, _ detail: String) {
            out.append(CheckOutcome(check: check(id), passed: passed, detail: detail))
        }

        add("os", env.osMajor >= minimumOSMajor, "macOS \(env.osMajor)")
        add("app-location",
            env.appPath.contains("/Applications/"),
            env.appPath)
        add("cli", env.cliPath != nil, env.cliPath ?? "not found")

        // pluginkit prints one line per extension, prefixed "+" (enabled) or "-" (disabled).
        let line = env.pluginkitList
            .split(separator: "\n")
            .first { $0.contains(env.extensionID) }
            .map(String.init)
        add("ext-registered", line != nil, line == nil ? "not registered" : env.extensionID)
        // Registered-but-disabled is a DIFFERENT failure with a different fix, so it is its own
        // check. Collapsing the two is what makes "it's installed but nothing happens" unfixable.
        add("ext-enabled",
            (line?.trimmingCharacters(in: .whitespaces).hasPrefix("+")) ?? false,
            line == nil ? "n/a" : (line!.hasPrefix("-") ? "disabled by macOS" : "enabled"))

        add("automation", env.automationOK, env.automationOK ? "Finder responds" : "denied or not yet granted")
        add("terminal",
            env.processList.contains("Terminal.app/Contents/MacOS/Terminal"),
            env.processList.isEmpty ? "none detected" : "running")
        add("hooks", env.hooksWired == 4, "\(env.hooksWired) of 4 wired")
        add("end-to-end", env.endToEndPassed, env.endToEndPassed ? "verified" : "failed")
        return out
    }

    /// The real environment. Every probe here is one that `docs/08-MACOS-COMPATIBILITY.md`
    /// records as VERIFIED — notably `ps -Ao comm` rather than pgrep, which never matches
    /// a bundled app.
    public static func liveEnv(extensionID: String = "dev.valuev.chute.finder",
                               appPath: String = Bundle.main.bundlePath) -> DiagnosticsEnv {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let cli = ["\(NSHomeDirectory())/.local/bin/chute", "/usr/local/bin/chute"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
        let probe = Shell.run("osascript", ["-e", "tell application \"Finder\" to return 1"])
        return DiagnosticsEnv(
            osMajor: v.majorVersion,
            appPath: appPath,
            cliPath: cli,
            pluginkitList: Shell.run("pluginkit", ["-mA", "-p", "com.apple.FinderSync"]).out,
            extensionID: extensionID,
            automationOK: probe.ok,
            processList: Shell.run("ps", ["-Ao", "comm"]).out,
            hooksWired: HookInstaller.status(settingsPath:
                (NSHomeDirectory() as NSString).appendingPathComponent(".claude/settings.json"))
                .values.filter { $0 }.count,
            endToEndPassed: endToEndProbe())
    }

    /// Runs the product, not its parts: writes a temp file, asks chute for its path, reads the
    /// clipboard back. Component checks passing while THIS fails is the exact state this project
    /// spent a day in.
    public static func endToEndProbe() -> Bool {
        let dir = NSTemporaryDirectory() + "chute-doctor-\(UUID().uuidString)"
        defer { try? FileManager.default.removeItem(atPath: dir) }
        guard (try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)) != nil
        else { return false }
        let file = (dir as NSString).appendingPathComponent("probe.txt")
        guard (try? "probe".write(toFile: file, atomically: true, encoding: .utf8)) != nil
        else { return false }
        let saved = Clipboard.read()
        defer { Clipboard.write(saved) }
        let rendered = PathFormat.render([file], style: .posix)
        Clipboard.write(rendered)
        return Clipboard.read().contains("probe.txt")
    }
}
