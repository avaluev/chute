import Foundation

/// The five beats of first-run, shared by the app's wizard and by `chute onboard`.
///
/// WHY A LIST OF DATA AND NOT TWO WALKTHROUGHS. There are two surfaces and they must teach the
/// same product. Written twice they drift, and the drift is invisible: nobody diffs a window
/// against a terminal transcript.
///
/// WHY AN ENUM OF IDS AND NOT `() -> Bool`. A closure is not Sendable, not Equatable, and cannot
/// be asserted against headlessly — but the real reason is that a closure forces every surface to
/// supply a probe it may not be able to implement. An id lets a surface DECLINE: read the
/// condition, and if you cannot evaluate it say "do this, then press Return" rather than
/// silently reporting false — or worse, silently reporting true. Same trick `Check{why,fix}`
/// already plays: the model states what is true, the surface decides what it can show.
public struct OnboardStep: Sendable, Equatable {
    /// What finishes this beat.
    public enum Done: Sendable, Equatable {
        /// Informational. Reading it is finishing it.
        case always
        /// A `Diagnostics.all` check id must pass.
        case check(String)
        /// A `ChuteActions` id must actually arrive in the request inbox — the user did it.
        case action(String)
    }

    public let id: String
    public let title: String
    public let body: String
    /// A copyable command, monospaced. `nil` for most: a wizard full of commands is a manual.
    public let command: String?
    public let done: Done

    public init(id: String, title: String, body: String, command: String?, done: Done) {
        self.id = id; self.title = title; self.body = body
        self.command = command; self.done = done
    }
}

public enum Onboarding {
    /// FIVE BEATS. Not four: dropping "where it lives afterwards" leaves an LSUIElement app with
    /// no Dock icon and no way back, which reads as "it did not install". Not six: every extra
    /// beat is one more thing between a stranger and the moment the product works for them.
    public static let steps: [OnboardStep] = [
        OnboardStep(
            id: "what",
            title: "A right-click menu, and a 🪂 in your menu bar",
            body: "Chute puts your files where your agent can read them. Everything it does "
                + "starts from one of those two places — there is no main window to learn.",
            command: nil,
            done: .always),

        OnboardStep(
            id: "permissions",
            title: "Switch the Finder menu on",
            // Gates on ext-enabled and NOT on automation. bundle-xml does not need Automation, so
            // someone who denied it must still be able to reach the next beat. Asking for
            // everything up front is how a wall of ten prompts gets denied as a block.
            body: "macOS keeps Finder extensions switched off until you say otherwise. This is "
                + "the only permission the next step needs.",
            command: nil,
            done: .check("ext-enabled")),

        OnboardStep(
            id: "first-win",
            title: "Right-click any folder → Copy Files as Context",
            // THE WHOLE DESIGN. Every other onboarding shows you a screenshot; this one waits
            // until you have actually done the thing, then confirms it. It is cheap because the
            // detection already exists — RequestInbox sees every Finder action as it happens.
            body: "Then paste into your agent. That is the whole product. Nothing else here "
                + "matters as much as doing it once.",
            command: nil,
            done: .action("bundle-xml")),

        OnboardStep(
            id: "cli",
            title: "There is a terminal half too, and it is free",
            body: "The same engine, MIT, yours forever, whatever happens to this app.",
            command: "brew install avaluev/tap/chute",
            done: .check("cli")),

        OnboardStep(
            id: "after",
            title: "Where things live from now on",
            body: "The 🪂 in your menu bar has your sessions and your local servers. Settings is "
                + "in that menu. If the Finder menu ever goes missing, `chute doctor` says why.",
            command: nil,
            done: .always),
    ]

    /// Is this beat finished, given what the surface was able to observe?
    ///
    /// `outcomes` maps a `Diagnostics` check id to whether it passed. An id ABSENT from the map
    /// is not "false", it is "not evaluated" — and both answer `false` here, deliberately. The
    /// dangerous direction is claiming done: a beat marked complete that the user never did
    /// removes the one thing this wizard is for.
    public static func isDone(_ step: OnboardStep,
                              outcomes: [String: Bool],
                              observed: Set<String>) -> Bool {
        switch step.done {
        case .always:          return true
        case .check(let id):   return outcomes[id] == true
        case .action(let id):  return observed.contains(id)
        }
    }

    /// The first beat whose condition is NOT satisfied, or nil when nothing is outstanding.
    ///
    /// Per-step progress is recomputed here, never persisted. A wizard that resumes from disk can
    /// resume WRONG — the user switched the extension on in System Settings while the window was
    /// closed, and a saved "you are on step 2" would put them back in front of a solved problem.
    /// `.always` beats carry no condition and so never appear here; they are things to read, and
    /// the surface walks them in order.
    public static func firstIncomplete(outcomes: [String: Bool],
                                       observed: Set<String>) -> OnboardStep? {
        steps.first { !isDone($0, outcomes: outcomes, observed: observed) }
    }
}
