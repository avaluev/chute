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
        T.eq(Diagnostics.all.count, 9, "nine checks")

        let good = DiagnosticsEnv(
            osMajor: 14, appPath: "/Users/x/Applications/Chute.app",
            cliPath: "/Users/x/.local/bin/chute",
            pluginkitList: "+    dev.valuev.chute.finder(0.1.0)",
            extensionID: "dev.valuev.chute.finder",
            automationOK: true,
            processList: "/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal",
            hooksWired: 4, endToEndPassed: true)

        T.eq(Diagnostics.run(good).filter { !$0.passed }.count, 0, "a healthy environment passes all nine")

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

        var partial = good; partial.hooksWired = 2
        T.eq(Diagnostics.run(partial).first(where: { !$0.passed })?.check.id ?? "", "hooks",
             "partially wired hooks fail the hooks check")

        var broken = good; broken.endToEndPassed = false
        T.eq(Diagnostics.run(broken).first(where: { !$0.passed })?.check.id ?? "", "end-to-end",
             "a failing end-to-end proof is named even when every component passes")

        T.eq(Diagnostics.run(good).count, 9, "run reports an outcome per check, passed or not")
    }
}
