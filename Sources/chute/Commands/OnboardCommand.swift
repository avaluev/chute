import Foundation
import ChuteCore

/// `chute onboard` — the terminal half of first-run.
///
/// It ships value on its own: someone who found Chute through Homebrew and never installs the app
/// still gets told what the product is and what the two halves are.
///
/// THE ASYMMETRY, STATED WHERE IT IS IMPLEMENTED. This passes `observed: []` and always will.
/// `ActionInbox.drain()` deletes each request file BEFORE executing it, so a CLI watching
/// ~/.chute/requests would lose that race on nearly every click and tell a user who DID the thing
/// that they did not. Being told "you have not done this yet" immediately after doing it is worse
/// than not being checked at all. So the CLI declines to answer that beat and says so plainly;
/// the app, which owns the inbox, answers it for real. The asymmetry lives here, in the surface,
/// and never in OnboardingSteps.
func cmdOnboard(_ args: Args) {
    let outcomes = Dictionary(uniqueKeysWithValues:
        Diagnostics.run(Diagnostics.liveEnv()).map { ($0.check.id, $0.passed) })

    Out.line("")
    for (n, step) in Onboarding.steps.enumerated() {
        let mark: String
        switch step.done {
        case .always:
            mark = "  "
        case .check:
            mark = Onboarding.isDone(step, outcomes: outcomes, observed: []) ? "✓ " : "· "
        case .action:
            // Not "✗". The CLI cannot see it, and a cross is a claim it has no standing to make.
            mark = "· "
        }
        Out.line("\(mark)\(n + 1). \(step.title)")
        Out.line("     \(step.body)")
        if let c = step.command { Out.line("     \(c)") }
        if case .action = step.done {
            Out.line("     (do it in Finder — the app confirms it for you when it happens)")
        }
        Out.line("")
    }

    let stuck = Onboarding.firstIncomplete(outcomes: outcomes, observed: [])
    if let stuck, case .check(let id) = stuck.done,
       let c = Diagnostics.all.first(where: { $0.id == id }) {
        Out.line("Next: \(c.fix)")
    } else {
        Out.line("Next: right-click a folder in Finder.")
    }
}
