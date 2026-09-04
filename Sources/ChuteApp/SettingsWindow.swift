import AppKit
import ChuteCore

/// Settings and About. A paid app needs both, and Chute had neither.
///
/// Hand-built AppKit, like FirstRunWindow: there is no Xcode in this build, so no xib and no
/// storyboard. Three tabs, because a licence field with nowhere to live is why this window exists.
enum SettingsWindow {
    nonisolated(unsafe) static var window: NSWindow?
    nonisolated(unsafe) private static var statusLabel: NSTextField?
    nonisolated(unsafe) private static var keyField: NSTextField?

    static let buyURL = "https://chutedev.com/buy"

    static func show(selecting tab: Int = 0) {
        if let w = window {
            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            refreshLicenseTab()
            return
        }
        let w = Panel.make(title: "Chute Settings", width: 520, height: 420)
        let tabs = NSTabView(frame: NSRect(x: 0, y: 0, width: 520, height: 420))
        tabs.autoresizingMask = [.width, .height]
        tabs.addTabViewItem(item("General", general()))
        tabs.addTabViewItem(item("License", license()))
        tabs.addTabViewItem(item("About", about()))
        tabs.selectTabViewItem(at: tab)
        w.contentView = tabs

        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        refreshLicenseTab()
    }

    private static func item(_ label: String, _ view: NSView) -> NSTabViewItem {
        let t = NSTabViewItem(identifier: label); t.label = label; t.view = view; return t
    }

    // MARK: - Tabs

    private static func general() -> NSView {
        let v = NSStackView(views: [
            heading("Where Chute is"),
            // The counts are READ, never typed. A number written into a sentence is a number that
            // goes stale — this app shipped "every prerequisite" over ten checks, and the fact
            // sheet has a whole table of hand-typed numbers that drifted.
            body("""
                 Finder — right-click files or a folder for the \(ChuteActions.all.count) actions.

                 Menu bar — your agent sessions. ⌥⌘N opens the same menu wherever you are.

                 Terminal — the `chute` command.
                 """),
            heading("Agent status hooks"),
            body("""
                 Chute never edits ~/.claude/settings.json. `chute hooks merged` prints that file \
                 with Chute's hooks added and gives you the command that writes it, backup first.

                 Without the hooks Chute cannot tell what an agent is doing: the menu bar badge \
                 stays dark and every session reads "no status".
                 """),
            heading("If something is not working"),
            body("`chute doctor` runs \(Diagnostics.all.count) checks — the extension, the "
                 + "Automation permission, the hooks — and prints the fix for each one that "
                 + "fails. `chute doctor --fix` applies the ones it can."),
        ])
        return pad(v)
    }

    private static func license() -> NSView {
        let status = NSTextField(labelWithString: "…")
        status.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel = status

        let field = NSTextField(string: "")
        field.placeholderString = "CHUTE-…"
        field.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        field.lineBreakMode = .byTruncatingMiddle
        keyField = field

        let activate = NSButton(title: "Activate", target: Handler.shared,
                                action: #selector(Handler.activate))
        activate.keyEquivalent = "\r"
        let buy = NSButton(title: "Buy Chute — $19", target: Handler.shared,
                           action: #selector(Handler.buy))

        let row = NSStackView(views: [field, activate])
        row.orientation = .horizontal
        row.distribution = .fill
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let v = NSStackView(views: [
            status,
            body("The `chute` command line tool is MIT licensed and free. This licence is for "
                 + "the app around it: the Finder actions, the session switcher and ⌥⌘N."),
            heading("Licence key"),
            row,
            // NOT "never contacts a server, and never will" — a promise about the future that
            // nobody can check. This says the thing a reader can verify from the source in one
            // grep, which is more convincing than the absolute version anyway.
            body("Paste the key from your purchase email. Chute checks its signature here on "
                 + "this Mac; there is no network code in the app, so there is nothing for it "
                 + "to phone home to."),
            buy,
        ])
        return pad(v)
    }

    private static func about() -> NSView {
        // The words are `ChuteCore.AboutText`, where the suite can read them. This end decides
        // nothing — see that file for why the old sentence had to go.
        let a = AboutText.about(version: ChuteVersion.current, build: Diagnostics.installedBuild())
        return pad(NSStackView(views: [heading(a.heading)] + a.body.map(body)))
    }

    // MARK: - Plumbing
    // heading / body / pad live in Panel.swift — FirstRunWindow needs the same three.

    private static func heading(_ s: String) -> NSTextField { UI.heading(s) }
    private static func body(_ s: String) -> NSTextField { UI.body(s) }
    private static func pad(_ stack: NSStackView) -> NSView { UI.pad(stack, inset: 24) }

    static func refreshLicenseTab() {
        let state = Trial.touch()
        switch state {
        case .licensed(let email):
            statusLabel?.stringValue = "Licensed to \(email)"
            statusLabel?.textColor = .systemGreen
            if let key = Trial.load()?.licenseKey { keyField?.stringValue = License.masked(key) }
        case .trial(let days):
            statusLabel?.stringValue = days == 1 ? "Trial — last day" : "Trial — \(days) days left"
            statusLabel?.textColor = .labelColor
        case .expired:
            // Precise about WHAT stopped. The CLI is untouched by the trial, and saying so at the
            // exact moment the app locks is the open-core promise being kept rather than claimed.
            statusLabel?.stringValue = "Trial ended — the Finder actions and the switcher are off. `chute` still works."
            statusLabel?.textColor = .systemOrange
        }
    }

    /// NSButton needs an Objective-C target that outlives the view, and the rest of this file is
    /// an enum by design — one shared handler is cheaper than making the whole thing a class.
    final class Handler: NSObject {
        static let shared = Handler()

        @objc func activate() {
            let typed = keyField?.stringValue ?? ""
            // The masked form is what is already active, and an empty field is nothing to check.
            // Both used to return in silence, so Activate looked broken rather than done.
            guard !typed.isEmpty else {
                statusLabel?.stringValue = "Paste the key from your purchase email first"
                statusLabel?.textColor = .secondaryLabelColor
                return
            }
            guard !typed.contains("…") else {
                statusLabel?.stringValue = "That licence is already active"
                statusLabel?.textColor = .systemGreen
                return
            }
            if let info = Trial.activate(typed) {
                statusLabel?.stringValue = "Licensed to \(info.email)"
                statusLabel?.textColor = .systemGreen
                keyField?.stringValue = License.masked(typed)
                notify("Chute", "Licensed to \(info.email). Thank you.")
            } else {
                statusLabel?.stringValue = Trial.activationFailure(typed)
                statusLabel?.textColor = .systemRed
            }
        }

        @objc func buy() {
            if let url = URL(string: buyURL) { NSWorkspace.shared.open(url) }
        }
    }
}
