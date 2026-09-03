import Foundation

/// A check that fails either blocks the product from working, or merely describes a state that
/// is fine to be in. Two cases, no scale between them — see `Diagnostics.all` for which is which.
public enum Severity: Sendable, Equatable {
    case blocker
    case note
}

/// One thing that must be true for Chute to work.
/// `why` and `fix` are non-optional by design: a check that cannot explain itself or state its
/// remedy is a dead end, and a test in the suite mechanically forbids adding one.
public struct Check: Sendable, Equatable {
    public let id: String
    public let title: String
    public let why: String
    public let fix: String
    /// Defaults to `.blocker` so every check written before this existed keeps its old meaning
    /// without being touched. Only `cli` and `terminal` — and the read-only `hooks` check below —
    /// are marked `.note`.
    public let severity: Severity

    public init(id: String, title: String, why: String, fix: String, severity: Severity = .blocker) {
        self.id = id; self.title = title; self.why = why; self.fix = fix; self.severity = severity
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
    public var endToEndPassed: Bool?   // nil: the probe was not run
    /// Whether the extension's sandbox container still accepts the installed build's code
    /// identity. nil when there is no container yet, which is a healthy first install.
    public var containerAccepts: Bool?
    /// Are Claude Code's agent-status hooks wired into `~/.claude/settings.json`? Read-only —
    /// `HookInstaller.status` only reads that file, Chute never writes it. Defaults to false,
    /// which is the common case: most machines never ran `chute hooks snippet`.
    public var hooksWired: Bool
    /// Is there actually a bundle at `appPath`? `appPath` can be a GUESS — see `resolvedAppPath`
    /// — and a check that reads a guess back to the user is a check that passes on nothing.
    public var appExists: Bool

    public init(osMajor: Int, appPath: String, cliPath: String?, pluginkitList: String,
                extensionID: String, automationOK: Bool, processList: String,
                endToEndPassed: Bool?, containerAccepts: Bool? = nil, hooksWired: Bool = false,
                appExists: Bool = true) {
        self.osMajor = osMajor; self.appPath = appPath; self.cliPath = cliPath
        self.pluginkitList = pluginkitList; self.extensionID = extensionID
        self.automationOK = automationOK; self.processList = processList
        self.endToEndPassed = endToEndPassed
        self.containerAccepts = containerAccepts
        self.hooksWired = hooksWired
        self.appExists = appExists
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
        // .note: a missing CLI does not block the app. FirstRunWindow used to title a clean
        // app-only install "2 things need your permission" over this and `terminal` — neither
        // is a permission, and Scripts/install.sh says the app does not need the CLI at all.
        Check(id: "cli", title: "Command line tool",
              why: "Every menu item and Finder action runs through the chute binary.",
              fix: "brew install avaluev/tap/chute", severity: .note),
        Check(id: "ext-registered", title: "Finder extension registered",
              why: "macOS cannot show the right-click menu for an extension it does not know about.",
              fix: "chute doctor --fix   (runs pluginkit -a on the bundled extension)"),
        Check(id: "ext-enabled", title: "Finder extension enabled",
              why: "The extension is installed but switched off, so the right-click menu stays hidden. This is the single most common reason Chute appears to do nothing.",
              fix: "chute doctor --fix   (or System Settings → Privacy & Security → Extensions → Finder)"),
        Check(id: "ext-started", title: "Finder extension actually starts",
              why: "Registered and enabled is not the same as running. A sandboxed extension's container remembers the exact build that created it, so after a rebuild macOS silently refuses to start the new one and the Chute menu simply stops appearing.",
              fix: "chute doctor --fix   (moves the stale container to the Trash and restarts Finder — no password needed)"),
        Check(id: "automation", title: "Automation permission",
              why: "Chute asks Finder and Terminal what you have selected. Without this the session list is empty.",
              fix: "chute doctor --fix triggers the prompt. If you denied it: System Settings → Privacy & Security → Automation."),
        Check(id: "terminal", title: "A terminal is running",
              why: "The session switcher lists terminal windows. With none open there is nothing to show.",
              fix: "Open Terminal. Informational only — nothing is broken.", severity: .note),
        // .note, and read-only: reporting whether the hooks are wired is not the same as nudging
        // anyone to wire them. That principle stays — Chute never writes ~/.claude/settings.json,
        // here or anywhere. What changed is that "no hooks check" made a permanently dark badge
        // look identical to a healthy install with nothing to report; this says which one it is.
        Check(id: "hooks", title: "Agent status hooks",
              why: "The badge on the menu bar icon, and each session's blocked/waiting/working "
                + "state, come entirely from hooks Claude Code calls. Without them the badge stays "
                + "dark and every session looks idle, even a busy one.",
              fix: "agent status hooks are not wired — the badge will stay dark. "
                + "chute hooks snippet prints what to paste; Chute never edits that file itself.",
              severity: .note),
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
        // The app must sit DIRECTLY in an Applications folder; a nested path will not load.
        // `contains` would pass /Users/x/Applications/Sub/Chute.app, which does not work.
        let appParent = (env.appPath as NSString).deletingLastPathComponent
        // AND it must EXIST. This check used to ask only whether the parent folder was called
        // Applications, and `resolvedAppPath` hands it a guess when the CLI is not inside a
        // bundle — so `chute doctor` from the Homebrew CLI printed "all 10 checks passed" and an
        // app path that was not on the disk. Everything downstream inherited the guess: the
        // extension-health probe read a bundle that is not there, got nil, and nil auto-passes.
        add("app-location",
            (appParent as NSString).lastPathComponent == "Applications" && env.appExists,
            env.appExists ? env.appPath
                          : "not found — looked in \(appCandidates.joined(separator: " and "))")
        add("cli", env.cliPath != nil, env.cliPath ?? "not found")

        // pluginkit prints one line per extension, prefixed "+" (enabled) or "-" (disabled).
        let line = env.pluginkitList
            .split(separator: "\n")
            .first { $0.contains(env.extensionID) }
            .map(String.init)
        add("ext-registered", line != nil, line == nil ? "not registered" : env.extensionID)
        // Registered-but-disabled is a DIFFERENT failure with a different fix, so it is its own
        // check. Collapsing the two is what makes "it's installed but nothing happens" unfixable.
        // The flag column has THREE states: "+" enabled, "-" explicitly disabled, and BLANK for
        // freshly registered. Blank is the state a user is in right after install, so it must read
        // as its own thing — reporting "enabled" on a failing check is worse than saying nothing.
        let flag = line?.trimmingCharacters(in: .whitespaces) ?? ""
        let enabledDetail: String
        if line == nil { enabledDetail = "not registered" }
        else if flag.hasPrefix("+") { enabledDetail = "enabled" }
        else if flag.hasPrefix("-") { enabledDetail = "disabled by macOS" }
        else { enabledDetail = "registered, not yet enabled" }
        add("ext-enabled", flag.hasPrefix("+"), enabledDetail)

        // nil means the extension is not installed — ext-registered already reports that.
        add("ext-started", env.containerAccepts ?? true,
            env.containerAccepts == false
                ? "this build has never run — a stale sandbox container is blocking it"
                : (env.containerAccepts == nil ? "not installed" : "has run since the last install"))

        add("automation", env.automationOK, env.automationOK ? "Finder responds" : "denied or not yet granted")
        add("terminal",
            env.processList.contains("Terminal.app/Contents/MacOS/Terminal"),
            env.processList.isEmpty ? "none detected" : "running")
        add("hooks", env.hooksWired, env.hooksWired ? "wired" : "not wired — badge stays dark")
        add("end-to-end", env.endToEndPassed ?? true,
            env.endToEndPassed.map { $0 ? "verified" : "failed" } ?? "not run here — `chute doctor` runs it")
        return out
    }

    /// The real environment. Every probe here is one that `docs/08-MACOS-COMPATIBILITY.md`
    /// records as VERIFIED — notably `ps -Ao comm` rather than pgrep, which never matches
    /// a bundled app.
    /// Where Chute.app actually is. `Bundle.main.bundlePath` answers this for the app, but the CLI
    /// is a symlink in ~/.local/bin pointing INTO the bundle, so from there it reports
    /// "/Users/x/.local/bin" and the app-location check fails on a perfectly good install.
    public static func resolvedAppPath(_ appPath: String,
                                       exists: (String) -> Bool = {
                                           FileManager.default.fileExists(atPath: $0)
                                       }) -> String {
        if appPath.hasSuffix(".app") { return appPath }
        let exe = URL(fileURLWithPath: Bundle.main.executablePath ?? "")
            .resolvingSymlinksInPath().path
        if let r = exe.range(of: ".app/") { return String(exe[..<r.lowerBound]) + ".app" }
        // A GUESS IS NOT AN ANSWER. This returned ~/Applications/Chute.app unconditionally, so a
        // customer who followed the DMG and dragged Chute to /Applications — which is what the DMG
        // says to do — got a report about a folder they had never used. Same candidate list, same
        // order, as Scripts/build-app.sh:289 and Scripts/install.sh.
        return appCandidates.first(where: exists) ?? appCandidates[0]
    }

    /// The two places an install can be. Order matters only when both exist, and then the per-user
    /// one wins, because that is the one `install.sh` writes by default.
    public static let appCandidates = [
        (NSHomeDirectory() as NSString).appendingPathComponent("Applications/Chute.app"),
        "/Applications/Chute.app",
    ]

    /// WHICH BUILD IS ACTUALLY INSTALLED, read back from the bundle `Scripts/build-app.sh` stamped.
    ///
    /// `ChuteVersion.current` is hand-bumped and answers "which release is this". It cannot answer
    /// "is the app on this Mac the app in the tree", and on 2026-08-28 that cost a session: Recent
    /// Copies was fixed at 21:09, the running app had been built at 20:14, and every test passed
    /// because the tests read the SOURCE. A stamp that changes on every build is the only thing
    /// that can tell those two apart — for a maintainer now, and inside a stranger's bug report
    /// later, which has to answer the same question with nobody around to ask.
    ///
    /// Nil when the key is absent: a bundle built before this existed, or a `swift run` with no
    /// bundle at all. Absent is not "current" and must not read as it.
    public static func installedBuild(appPath: String? = nil) -> String? {
        let app = resolvedAppPath(appPath ?? Bundle.main.bundlePath)
        let plist = (app as NSString).appendingPathComponent("Contents/Info.plist")
        guard let dict = NSDictionary(contentsOfFile: plist),
              let build = dict["ChuteBuild"] as? String,
              !build.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return build
    }

    /// Where the CLI is looked for, in order. Homebrew owns it: `brew install avaluev/tap/chute`
    /// is the free top of funnel and what the site advertises, and the app no longer writes
    /// `~/.local/bin/chute`. It used to — and then diagnosed the resulting two-copies-on-PATH
    /// collision it had created itself, offering to recreate it as the fix.
    ///
    /// Both Homebrew prefixes are named because there is no one answer: `/opt/homebrew` on Apple
    /// Silicon, `/usr/local` on Intel. `~/.local/bin` is LAST rather than absent, so anyone who
    /// installed before this change keeps a working `chute` until they run `uninstall.sh`.
    public static var cliCandidates: [String] {
        ["/opt/homebrew/bin/chute",
         "/usr/local/bin/chute",
         "\(NSHomeDirectory())/.local/bin/chute"]
    }

    /// `endToEnd` is opt-in because the probe WRITES THE CLIPBOARD, and `Clipboard.read` is
    /// `pbpaste` — empty for an image or a file promise — so the "restore" after the probe wrote
    /// "" over whatever non-text the user had copied. ChuteApp ran it on every launch, with no
    /// window and no action. `chute doctor` asks for it; the launch check does not.
    public static func liveEnv(extensionID: String = "dev.valuev.chute.finder",
                               appPath: String = Bundle.main.bundlePath,
                               endToEnd: Bool = false) -> DiagnosticsEnv {
        let appPath = resolvedAppPath(appPath)
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let cli = cliCandidates.first { FileManager.default.isExecutableFile(atPath: $0) }
        let probe = Shell.run("osascript", ["-e", "tell application \"Finder\" to return 1"])
        return DiagnosticsEnv(
            osMajor: v.majorVersion,
            appPath: appPath,
            cliPath: cli,
            pluginkitList: Shell.run("pluginkit", ["-mA", "-p", "com.apple.FinderSync"]).out,
            extensionID: extensionID,
            automationOK: probe.ok,
            processList: Shell.run("ps", ["-Ao", "comm"]).out,
            endToEndPassed: endToEnd ? endToEndProbe() : nil,
            containerAccepts: extensionHasStarted(extensionID: extensionID, appPath: appPath),
            hooksWired: HookInstaller.status(settingsPath: claudeSettingsPath).values.allSatisfy { $0 },
            appExists: FileManager.default.fileExists(atPath: appPath))
    }

    /// Where Claude Code keeps its settings. THE one definition — `chute hooks` and the menu
    /// bar's snippet row both read it from here, because three hand-written copies of a path is
    /// how one of them ends up checking a file nothing writes.
    /// Read-only, always: Chute never writes this file.
    public static let claudeSettingsPath =
        (NSHomeDirectory() as NSString).appendingPathComponent(".claude/settings.json")

    /// Has the INSTALLED extension actually started? Proved by the extension itself: it writes
    /// `~/.chute/extension-loaded.txt` on load, so a marker older than the installed binary means
    /// the current build has never run.
    ///
    /// This is the check that turns "the Chute menu just disappeared" into one sentence with a
    /// command under it. The failure is invisible everywhere else — pluginkit still reports the
    /// extension registered and enabled, the process still launches — and the only trace is a
    /// system log line: "code identity <cdhash …> not in ACL for container". It happens because a
    /// sandboxed extension's container pins the exact code identity that created it, and an
    /// ad-hoc rebuild is a new identity every time.
    ///
    /// nil when the extension is not installed at all; that is a different check's job.
    public static func extensionHasStarted(extensionID: String, appPath: String,
                                           markerPath: String? = nil) -> Bool? {
        let bundle = appPath.hasSuffix(".app")
            ? appPath
            : (NSHomeDirectory() as NSString).appendingPathComponent("Applications/Chute.app")
        let appex = (bundle as NSString)
            .appendingPathComponent("Contents/PlugIns/ChuteFinder.appex/Contents/MacOS/ChuteFinder")
        let marker = markerPath
            ?? (NSHomeDirectory() as NSString).appendingPathComponent(".chute/extension-loaded.txt")

        let fm = FileManager.default
        guard let appexDate = (try? fm.attributesOfItem(atPath: appex))?[.modificationDate] as? Date
        else { return nil }
        guard let markerDate = (try? fm.attributesOfItem(atPath: marker))?[.modificationDate] as? Date
        else { return false }
        // A second of slack: the installer copies the bundle and restarts Finder back to back.
        return markerDate.addingTimeInterval(1) >= appexDate
    }

    /// Runs the product, not its parts: writes a temp file, asks chute for its path, reads the
    /// clipboard back. Component checks passing while THIS fails is the exact state this project
    /// spent a day in.
    static func endToEndProbe() -> Bool {
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
