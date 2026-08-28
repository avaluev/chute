import AppKit
import ChuteCore

/// The app's half of first-run: the five beats of `OnboardingSteps`, one at a time.
///
/// FirstRunWindow is a REPAIR window — it shows only what is failing, and shows nothing when
/// everything passes. That is right for what it does and useless for teaching: a stranger who
/// installs cleanly sees nothing at all, and an LSUIElement app has no Dock icon, so "nothing" is
/// indistinguishable from "it did not install".
///
/// This draws no chrome of its own. Panel, UI.pad and FirstRunWindow.row are the existing
/// vocabulary and the window has to look like the rest of the app, not like a tour.
enum Onboard {
    nonisolated(unsafe) static var window: NSWindow?
    nonisolated(unsafe) private static var observed: Set<String> = []
    nonisolated(unsafe) private static var outcomes: [String: Bool] = [:]
    nonisolated(unsafe) private static var index = 0

    /// Called from the request inbox for every Finder action that arrives, ABOVE the trial gate.
    /// The user performed the right-click; the teaching succeeded. Whether the action was
    /// PERMITTED is a separate question, and a lapsed trial must not make beat 3 unreachable.
    static func observe(_ actionID: String) {
        observed.insert(actionID)
        DispatchQueue.main.async { if window?.isVisible == true { render() } }
    }

    /// True first launch only. `UserDefaults` and not a file in ~/.chute, because of the rule the
    /// deleted `state.json` established: a file may live in ~/.chute only if the process that
    /// READS it is not the process that WROTE it. requests/, sessions/, extension-loaded.txt all
    /// pass that. An onboarding flag is written and read by ChuteApp alone, so it fails it.
    /// The escape hatch is ordinary macOS — `defaults delete dev.valuev.chute` — not a dotfile
    /// whose purpose the next person has to reverse-engineer before daring to delete it.
    ///
    /// The flag is written in `Handler.next()`'s Finish branch, not here. Writing it before
    /// `show()` meant quitting mid-wizard still marked it done — the only way back was deleting
    /// the whole defaults domain. Written late, quitting early leaves it unset, and the wizard is
    /// what greets the next launch.
    static func showIfFirstRun() {
        guard !hasOnboarded else { return }
        show()
    }

    /// Read by `main.swift` too, to decide between this wizard and the repair window on launch —
    /// one string, one place, rather than the key duplicated at each call site.
    static var hasOnboarded: Bool { UserDefaults.standard.bool(forKey: "onboarded") }

    static func show() {
        index = 0
        refreshOutcomes()
        let w = window ?? Panel.make(title: "Chute", width: 560, height: 300)
        window = w
        render()
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    private static func refreshOutcomes() {
        // Never on the main thread: the probe shells out to osascript, pluginkit and ps, and a
        // frozen launch in a Dock-less app reads as a crash.
        DispatchQueue.global(qos: .userInitiated).async {
            let run = Diagnostics.run(Diagnostics.liveEnv())
            let map = Dictionary(uniqueKeysWithValues: run.map { ($0.check.id, $0.passed) })
            DispatchQueue.main.async {
                outcomes = map
                blockers = run.filter { !$0.passed }
                if window?.isVisible == true { render() }
            }
        }
    }

    nonisolated(unsafe) private static var blockers: [CheckOutcome] = []

    private static var step: OnboardStep { Onboarding.steps[min(index, Onboarding.steps.count - 1)] }

    private static func render() {
        guard let w = window else { return }
        let s = step
        let done = Onboarding.isDone(s, outcomes: outcomes, observed: observed)

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14

        let counter = NSTextField(labelWithString:
            "\(index + 1) of \(Onboarding.steps.count)")
        counter.font = .systemFont(ofSize: 11)
        counter.textColor = .secondaryLabelColor
        root.addArrangedSubview(counter)

        let heading = NSTextField(labelWithString: s.title)
        heading.font = .systemFont(ofSize: 18, weight: .semibold)
        root.addArrangedSubview(heading)

        let body = NSTextField(wrappingLabelWithString: s.body)
        body.preferredMaxLayoutWidth = FirstRunWindow.contentWidth
        root.addArrangedSubview(body)

        if let c = s.command {
            let cmd = NSTextField(labelWithString: c)
            cmd.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            cmd.isSelectable = true
            root.addArrangedSubview(cmd)
        }

        // NEVER ASK THE IMPOSSIBLE. If the extension is off, beat 3 does NOT say "go right-click
        // a folder" — the click cannot work and the user would be told to do something the
        // product already knows will fail. Show the failing checks' own why and fix instead,
        // through the row FirstRunWindow already draws.
        if case .action = s.done, !done {
            let stoppers = blockers.filter { $0.check.id == "ext-enabled" || $0.check.id == "ext-started" }
            for o in stoppers { root.addArrangedSubview(FirstRunWindow.row(o)) }
        }
        if case .check = s.done, !done {
            for o in blockers where !Onboarding.isDone(s, outcomes: outcomes, observed: observed) {
                if case .check(let id) = s.done, o.check.id == id { root.addArrangedSubview(FirstRunWindow.row(o)) }
            }
        }

        if done, case .always = s.done {} else if done {
            let ok = NSTextField(labelWithString: "Done.")
            ok.textColor = .systemGreen
            root.addArrangedSubview(ok)
        }

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 10
        let last = index == Onboarding.steps.count - 1
        let next = NSButton(title: last ? "Finish" : "Continue",
                            target: Handler.shared, action: #selector(Handler.next))
        next.keyEquivalent = "\r"
        buttons.addArrangedSubview(next)
        // Skip is on EVERY step and is never the default button, so beat 3's Skip carries no more
        // shame than any other. Panel already gives ⌘W and Esc at any step.
        if !last {
            buttons.addArrangedSubview(
                NSButton(title: "Skip", target: Handler.shared, action: #selector(Handler.next)))
        }
        root.addArrangedSubview(buttons)

        w.contentView = UI.pad(root)
        FirstRunWindow.fitToContent(w)
    }

    final class Handler: NSObject {
        nonisolated(unsafe) static let shared = Handler()
        @objc func next() {
            // Finish — and Skip on the last beat, which is the same button: there is no Skip row
            // once `last` is true (see render()). Written HERE, not on first show, so quitting
            // mid-wizard leaves it unset and the wizard is what the next launch shows again.
            if index >= Onboarding.steps.count - 1 {
                UserDefaults.standard.set(true, forKey: "onboarded")
                window?.close()
                return
            }
            index += 1
            refreshOutcomes()
            render()
        }
    }
}
