import Foundation
import ChuteCore

func diagnosticsSuite() {
    T.suite("Diagnostics") {
        // The dead-end guard: this is the rule the whole module exists to enforce.
        for check in Diagnostics.all {
            T.no(check.why.isEmpty, "check '\(check.id)' explains why it matters")
            T.no(check.fix.isEmpty, "check '\(check.id)' states how to fix it")
            T.no(check.title.isEmpty, "check '\(check.id)' has a title")
        }
        T.eq(Set(Diagnostics.all.map(\.id)).count, Diagnostics.all.count, "check ids are unique")
        T.eq(Diagnostics.all.count, 9, "nine checks — hooks left deliberately, see Diagnostics.all")

        let good = DiagnosticsEnv(
            osMajor: 14, appPath: "/Users/x/Applications/Chute.app",
            cliPath: "/Users/x/.local/bin/chute",
            pluginkitList: "+    dev.valuev.chute.finder(0.1.0)",
            extensionID: "dev.valuev.chute.finder",
            automationOK: true,
            processList: "/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal",
            endToEndPassed: true)

        T.eq(Diagnostics.run(good).filter { !$0.passed }.count, 0, "a healthy environment passes them all")

        // Each failure must be isolated: break one thing, exactly one check fails, and it names it.
        var old = good; old.osMajor = 12
        let oldOut = Diagnostics.run(old).filter { !$0.passed }
        T.eq(oldOut.count, 1, "an old OS fails exactly one check")
        T.eq(oldOut.first?.check.id ?? "", "os", "and it is the os check")

        var unreg = good; unreg.pluginkitList = ""
        T.eq(Diagnostics.run(unreg).first(where: { !$0.passed })?.check.id ?? "", "ext-registered",
             "an unregistered extension is named")

        // A registered-but-DISABLED extension is the exact state that wasted a day: the minus flag.
        var disabled = good; disabled.pluginkitList = "-    dev.valuev.chute.finder(0.1.0)"
        let disOut = Diagnostics.run(disabled).filter { !$0.passed }
        T.eq(disOut.count, 1, "registered-but-disabled fails exactly one check")
        T.eq(disOut.first?.check.id ?? "", "ext-enabled", "and it is the enabled check, not registered")

        var noAuto = good; noAuto.automationOK = false
        T.eq(Diagnostics.run(noAuto).first(where: { !$0.passed })?.check.id ?? "", "automation",
             "missing automation permission is named")

        // No "hooks" check by design: doctor must never nudge anyone toward editing
        // ~/.claude/settings.json, the one file Chute promises not to touch.
        T.ok(!Diagnostics.all.contains { $0.id == "hooks" },
             "there is no hooks check to fail")

        var broken = good; broken.endToEndPassed = false
        T.eq(Diagnostics.run(broken).first(where: { !$0.passed })?.check.id ?? "", "end-to-end",
             "a failing end-to-end proof is named even when every component passes")

        T.eq(Diagnostics.run(good).count, Diagnostics.all.count,
             "run reports an outcome per check, passed or not")

        // The blank flag column is the state a user is in immediately after install.
        var blank = good
        blank.pluginkitList = "     dev.valuev.chute.finder(0.1.0)\t8B1E-UUID\t/path"
        blank.extensionID = "dev.valuev.chute.finder"
        let blankOut = Diagnostics.run(blank).first { $0.check.id == "ext-enabled" }
        T.no(blankOut?.passed ?? true, "a blank flag column is NOT enabled")
        T.eq(blankOut?.detail ?? "", "registered, not yet enabled",
             "and its detail says so rather than claiming 'enabled'")

        var disabledDetail = good
        disabledDetail.pluginkitList = "-    dev.valuev.chute.finder(0.1.0)"
        disabledDetail.extensionID = "dev.valuev.chute.finder"
        T.eq(Diagnostics.run(disabledDetail).first { $0.check.id == "ext-enabled" }?.detail ?? "",
             "disabled by macOS", "an explicit minus reads as disabled")

        var nested = good; nested.appPath = "/Users/x/Applications/Sub/Chute.app"
        T.eq(Diagnostics.run(nested).first(where: { !$0.passed })?.check.id ?? "", "app-location",
             "an app nested below Applications is rejected")

        var lookalike = good; lookalike.appPath = "/Users/x/NotApplications/Chute.app"
        T.eq(Diagnostics.run(lookalike).first(where: { !$0.passed })?.check.id ?? "", "app-location",
             "a lookalike directory is rejected")

        // A failing check must never describe itself in terms that read like success.
        for env in [blank, disabledDetail, nested, lookalike] {
            for o in Diagnostics.run(env) where !o.passed {
                T.no(o.detail == "enabled" || o.detail == "verified" || o.detail == "ok",
                     "a failing check (\(o.check.id)) does not report a success word as its detail")
            }
        }

        // "Registered and enabled" is not "running". The extension writes a marker when it loads;
        // a marker older than the installed binary means this build has never started — which is
        // exactly what a stale sandbox container does after a rebuild.
        let box = NSTemporaryDirectory() + "chute-started-\(UInt32.random(in: 0...99999))"
        let appexDir = box + "/Chute.app/Contents/PlugIns/ChuteFinder.appex/Contents/MacOS"
        try? FileManager.default.createDirectory(atPath: appexDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: box) }
        let appex = appexDir + "/ChuteFinder"
        let marker = box + "/extension-loaded.txt"
        let app = box + "/Chute.app"

        T.ok(Diagnostics.extensionHasStarted(extensionID: "x", appPath: app, markerPath: marker) == nil,
             "no installed binary is not a failure, it is a different check's job")

        try? "binary".write(toFile: appex, atomically: true, encoding: .utf8)
        T.eq(Diagnostics.extensionHasStarted(extensionID: "x", appPath: app, markerPath: marker), false,
             "installed but never loaded reads as not started")

        try? "loaded".write(toFile: marker, atomically: true, encoding: .utf8)
        T.eq(Diagnostics.extensionHasStarted(extensionID: "x", appPath: app, markerPath: marker), true,
             "a marker written after the install proves it started")

        // A rebuild moves the binary forward; the old marker must stop counting.
        try? FileManager.default.setAttributes([.modificationDate: Date().addingTimeInterval(600)],
                                               ofItemAtPath: appex)
        T.eq(Diagnostics.extensionHasStarted(extensionID: "x", appPath: app, markerPath: marker), false,
             "a marker from the PREVIOUS build does not vouch for this one")

        // And the check reports it in words the reader can act on.
        var stale = good
        stale.containerAccepts = false
        let started = Diagnostics.run(stale).first { $0.check.id == "ext-started" }
        T.eq(started?.passed, false, "the outcome fails")
        T.ok(started?.detail.contains("stale sandbox container") == true,
             "and names the cause rather than saying 'failed'")

        // The CLI is a symlink in ~/.local/bin pointing INTO the bundle. Reporting that directory
        // as the app location failed the app-location check on a perfectly good install.
        T.eq(Diagnostics.resolvedAppPath("/Users/x/Applications/Chute.app"),
             "/Users/x/Applications/Chute.app", "an app path is already the answer")
        T.ok(Diagnostics.resolvedAppPath("/Users/x/.local/bin").hasSuffix(".app"),
             "anything else resolves to an app bundle, never a bin directory")

        // WHERE THE CLI IS LOOKED FOR. Homebrew owns the CLI now — the app stopped writing
        // ~/.local/bin/chute, because two copies on PATH at the same version is a collision the
        // app was creating and then diagnosing. The search order has to name both Homebrew
        // prefixes or `chute doctor` reports "not found" on a Mac that has it installed:
        // /opt/homebrew on Apple Silicon, /usr/local on Intel. ~/.local/bin stays LAST so an
        // older install that still has the symlink keeps working until it is uninstalled.
        let cands = Diagnostics.cliCandidates
        T.ok(cands.contains("/opt/homebrew/bin/chute"), "Homebrew on Apple Silicon is searched")
        T.ok(cands.contains("/usr/local/bin/chute"), "Homebrew on Intel is searched")
        T.ok(cands.contains { $0.hasSuffix("/.local/bin/chute") },
             "and the legacy symlink still resolves for anyone who already has one")
        T.eq(cands.firstIndex { $0.hasSuffix("/.local/bin/chute") }, cands.count - 1,
             "but it is searched LAST — Homebrew is the copy the product supports")

        // The fix a user is told to run must not recreate the collision. Nothing in the check
        // may offer to symlink any more.
        let cliCheck = Diagnostics.all.first { $0.id == "cli" }
        T.no(cliCheck?.fix.contains(".local/bin") ?? true,
             "the cli fix no longer tells anyone to symlink into ~/.local/bin")
        T.ok(cliCheck?.fix.contains("brew install") ?? false,
             "it points at Homebrew, which is what the site and the README both advertise")

        // NOTHING A CUSTOMER IS TOLD TO RUN MAY BE A DEVELOPER'S COMMAND. The ext-started fix
        // read "sudo rm -rf ~/Library/Containers/… && ~/Documents/2026/Development/37.chute/
        // Scripts/install.sh" — a root delete, followed by a path that exists on exactly one
        // Mac in the world. Someone who installed from the DMG has no Scripts directory, so the
        // second half fails and they are left having sudo-deleted something on the strength of
        // an app's advice. The repair does not even need root: install.sh has always moved that
        // container to the Trash through Finder, which asks for no password.
        for check in Diagnostics.all {
            T.no(check.fix.contains("sudo"),
                 "check '\(check.id)' does not ask for root")
            T.no(check.fix.contains("/Documents/") || check.fix.contains("/Users/"),
                 "check '\(check.id)' names no path that exists on one machine only")
        }

        // WHICH BUILD IS INSTALLED. The stamp is the answer to the only question nine passing
        // checks cannot answer: is the app on this Mac the app in this tree. Absent must read as
        // absent — a nil that quietly became "current" would be the false all-clear again.
        let bundle = NSTemporaryDirectory() + "chute-build-\(UUID().uuidString)/Chute.app/Contents"
        try? FileManager.default.createDirectory(atPath: bundle, withIntermediateDirectories: true)
        let stampedApp = (bundle as NSString).deletingLastPathComponent
        let plist = (bundle as NSString).appendingPathComponent("Info.plist")

        T.eq(Diagnostics.installedBuild(appPath: stampedApp), nil, "no Info.plist reads as not stamped")

        try? NSDictionary(dictionary: ["CFBundleVersion": "0.2.0"]).write(toFile: plist, atomically: true)
        T.eq(Diagnostics.installedBuild(appPath: stampedApp), nil, "a plist without the key reads as not stamped")

        try? NSDictionary(dictionary: ["ChuteBuild": "   "]).write(toFile: plist, atomically: true)
        T.eq(Diagnostics.installedBuild(appPath: stampedApp), nil, "a blank stamp is not a stamp")

        try? NSDictionary(dictionary: ["ChuteBuild": "0d23f86 2026-08-28T21:09Z"])
            .write(toFile: plist, atomically: true)
        T.eq(Diagnostics.installedBuild(appPath: stampedApp), "0d23f86 2026-08-28T21:09Z",
             "the stamp build-app.sh wrote is read back verbatim")
        try? FileManager.default.removeItem(atPath: (stampedApp as NSString).deletingLastPathComponent)
    }
}
