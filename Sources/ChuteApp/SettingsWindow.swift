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
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                         styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.title = "Chute Settings"
        w.center()
        w.isReleasedWhenClosed = false

        let tabs = NSTabView(frame: NSRect(x: 0, y: 0, width: 520, height: 420))
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
            heading("Three surfaces, one tool"),
            body("""
                 Right-click in Finder for the file actions. ⌥⌘N anywhere for the quick menu. \
                 The `chute` command in any terminal.

                 Chute never writes to another tool's configuration. To wire the agent status \
                 hooks, run `chute hooks snippet` and paste the result yourself.
                 """),
            heading("Diagnostics"),
            body("`chute doctor` checks every prerequisite and prints the exact fix for anything "
                 + "that is not wired up yet."),
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
            body("The `chute` command-line tool is free forever and MIT licensed. This licence "
                 + "covers the app: the Finder menu, the menu-bar switcher and the hotkey."),
            heading("Licence key"),
            row,
            body("Paste the key from your purchase email. It is checked on this Mac — Chute never "
                 + "contacts a server to verify a licence, and never will."),
            buy,
        ])
        return pad(v)
    }

    private static func about() -> NSView {
        let v = NSStackView(views: [
            heading("Chute \(ChuteVersion.current)"),
            body("Drop context into your agent."),
            body("""
                 Offline. No account. No telemetry. Nothing is uploaded, ever, except by the \
                 `gist` command when you explicitly ask for it.

                 chutedev.com
                 """),
        ])
        return pad(v)
    }

    // MARK: - Plumbing

    private static func heading(_ s: String) -> NSTextField {
        let t = NSTextField(labelWithString: s)
        t.font = .systemFont(ofSize: 13, weight: .semibold)
        return t
    }

    private static func body(_ s: String) -> NSTextField {
        let t = NSTextField(wrappingLabelWithString: s)
        t.font = .systemFont(ofSize: 12)
        t.textColor = .secondaryLabelColor
        t.preferredMaxLayoutWidth = 460
        return t
    }

    private static func pad(_ stack: NSStackView) -> NSView {
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        let host = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 390))
        host.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: host.topAnchor, constant: 24),
        ])
        return host
    }

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
            statusLabel?.stringValue = "Trial ended — the app is locked until it is licensed"
            statusLabel?.textColor = .systemOrange
        }
    }

    /// NSButton needs an Objective-C target that outlives the view, and the rest of this file is
    /// an enum by design — one shared handler is cheaper than making the whole thing a class.
    final class Handler: NSObject {
        static let shared = Handler()

        @objc func activate() {
            let typed = keyField?.stringValue ?? ""
            guard !typed.isEmpty, !typed.contains("…") else { return }   // the masked form, untouched
            if let info = Trial.activate(typed) {
                statusLabel?.stringValue = "Licensed to \(info.email)"
                statusLabel?.textColor = .systemGreen
                keyField?.stringValue = License.masked(typed)
                notify("Chute", "Licensed to \(info.email). Thank you.")
            } else {
                statusLabel?.stringValue = "That key was not recognised — check it was pasted whole"
                statusLabel?.textColor = .systemRed
            }
        }

        @objc func buy() {
            if let url = URL(string: buyURL) { NSWorkspace.shared.open(url) }
        }
    }
}
