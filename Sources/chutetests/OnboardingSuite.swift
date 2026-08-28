import Foundation
import ChuteCore

/// Written BEFORE either surface, and this is the reason: an onboarding step is a promise that
/// something is checkable, and the two things it can check — a diagnostics id and a Finder action
/// id — both live in other files that other people rename. A beat whose id has gone stale does
/// not crash and does not warn; it silently becomes unsatisfiable, and a user follows an
/// instruction that can never be marked done. That is the failure this suite exists to prevent.
func onboardingSuite() {
    T.suite("Onboarding") {
        let steps = Onboarding.steps
        T.eq(steps.count, 5, "five beats — see Onboarding.steps for why not four or six")
        T.eq(Set(steps.map(\.id)).count, steps.count, "beat ids are unique")

        // CROSS-LIST INTEGRITY. The highest-value assertion in the file.
        for s in steps {
            switch s.done {
            case .always: break
            case .check(let id):
                T.ok(Diagnostics.all.contains { $0.id == id },
                     "beat '\(s.id)' waits on a check that exists: \(id)")
            case .action(let id):
                T.ok(ChuteActions.find(id) != nil,
                     "beat '\(s.id)' waits on a Finder action that exists: \(id)")
            }
            T.no(s.title.isEmpty, "beat '\(s.id)' has a title")
            T.no(s.body.isEmpty, "beat '\(s.id)' says something")
        }

        // THE WHOLE DESIGN, pinned by literal. Beat 3 waits for the user to have actually
        // right-clicked a folder — not for them to have read that they could.
        T.eq(steps.first { $0.id == "first-win" }?.done, .action("bundle-xml"),
             "the first real win is a Finder action the user performed, not a screenshot")

        // Beat 2 gates on ext-enabled and NOT on automation: bundle-xml does not need Automation,
        // so someone who denied it must still be able to reach beat 3.
        T.eq(steps.first { $0.id == "permissions" }?.done, .check("ext-enabled"),
             "permissions waits on the extension being switched on, not on Automation")

        // NEVER CLAIM DONE ON SOMETHING YOU COULD NOT EVALUATE. A surface that cannot answer a
        // probe passes nothing for it, and the honest answer is "not yet", never "yes".
        let unknowable = OnboardStep(id: "x", title: "t", body: "b", command: nil,
                                     done: .check("ext-enabled"))
        T.no(Onboarding.isDone(unknowable, outcomes: [:], observed: []),
             "a check with no outcome is NOT done")
        T.no(Onboarding.isDone(OnboardStep(id: "y", title: "t", body: "b", command: nil,
                                           done: .action("bundle-xml")),
                               outcomes: [:], observed: []),
             "an action nobody observed is NOT done")
        T.ok(Onboarding.isDone(OnboardStep(id: "z", title: "t", body: "b", command: nil,
                                           done: .always), outcomes: [:], observed: []),
             "an informational beat is finished by being read")
        T.ok(Onboarding.isDone(unknowable, outcomes: ["ext-enabled": true], observed: []),
             "a passing check completes its beat")
        T.no(Onboarding.isDone(unknowable, outcomes: ["ext-enabled": false], observed: []),
             "a failing check does not")

        // THE ASYMMETRY, PINNED SO NOBODY "FIXES" IT. `chute onboard` passes observed: [] and
        // always will. ActionInbox.drain() deletes each request file BEFORE executing it, so a
        // CLI watching that directory loses the race on nearly every click — and would tell a
        // user who did the thing that they did not. The app has a live inbox and can answer;
        // the CLI declines and says "do this, then run me again". The asymmetry lives in the
        // surface, never in the model.
        let cliView = Onboarding.firstIncomplete(outcomes: ["ext-enabled": true, "cli": true],
                                                 observed: [])
        T.eq(cliView?.id, "first-win",
             "with no observations the CLI stops at the beat it cannot verify, and says so")

        // The app has a live inbox, saw the click, and therefore has nothing left to ask for.
        // `.always` beats carry no condition, so they never block: they are things to READ, and a
        // surface shows them in order rather than waiting on them. firstIncomplete answers "is
        // anything still UNSATISFIED", which is what decides whether the window opens at all.
        T.eq(Onboarding.firstIncomplete(outcomes: ["ext-enabled": true, "cli": true],
                                        observed: ["bundle-xml"]),
             nil, "the app, which saw the click, has nothing left to wait for")
        T.eq(Onboarding.firstIncomplete(outcomes: ["ext-enabled": false, "cli": true],
                                        observed: ["bundle-xml"])?.id, "permissions",
             "and a switched-off extension is what it stops on, not the beat after it")

        // NO NAGGING, MADE MECHANICAL. main.swift removes the trial line entirely once paid,
        // because "an app that keeps mentioning payment after the payment is nagging its own
        // customer". A wizard that quotes the price would reintroduce exactly that, in the one
        // window a user cannot dismiss without reading.
        for s in steps {
            let text = s.title + " " + s.body + " " + (s.command ?? "")
            for word in ["$19", "19", "buy", "purchase", "licence", "license", "trial", "pay"] {
                T.no(text.lowercased().contains(word.lowercased()),
                     "beat '\(s.id)' does not mention '\(word)' — onboarding teaches, it does not sell")
            }
        }
    }
}
