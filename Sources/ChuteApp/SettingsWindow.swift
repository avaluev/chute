import AppKit
import ChuteCore

/// Settings and About.
///
/// Hand-built AppKit, like FirstRunWindow: there is no Xcode in this build, so no xib and no
/// storyboard. There was a third, License, tab — it and the key field it held went with the paid
/// price on 2026-09-08, when Chute went free and MIT. Two tabs is what a free app needs.
enum SettingsWindow {
    nonisolated(unsafe) static var window: NSWindow?

    static func show(selecting tab: Int = 0) {
        if let w = window {
            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            return
        }
        let w = Panel.make(title: "Chute Settings", width: 520, height: 420)
        let tabs = NSTabView(frame: NSRect(x: 0, y: 0, width: 520, height: 420))
        tabs.autoresizingMask = [.width, .height]
        tabs.addTabViewItem(item("General", general()))
        tabs.addTabViewItem(item("About", about()))
        tabs.selectTabViewItem(at: tab)
        w.contentView = tabs

        window = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
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

    private static func about() -> NSView {
        // The words are `ChuteCore.AboutText`, where the suite can read them. This end decides
        // nothing — see that file for why the old sentence had to go.
        let a = AboutText.about(version: ChuteVersion.current, build: Diagnostics.installedBuild())
        // A SELECTABLE FIELD WITH .link ATTRIBUTES, not a row of NSButtons. AppKit opens a link in
        // a selectable text field on click with no target, no action and no handler object — so
        // four contact rows cost this file zero decision points, which matters because
        // Scripts/check-untested-logic.sh holds it to a budget it only just earned by losing the
        // licence tab. The labels and URLs are AboutText.contacts, where the suite can read them.
        let links = AboutText.contacts.map { linkField(label: $0.label, handle: $0.handle, url: $0.url) }
        return pad(NSStackView(views:
            [heading(a.heading)] + a.body.map(body)
            + [heading(AboutText.contactHeading), body(AboutText.contactLead)] + links))
    }

    // MARK: - Plumbing
    // heading / body / pad live in Panel.swift — FirstRunWindow needs the same three.

    /// "LinkedIn   in/valuev" where the handle is a live link. `isSelectable` is what makes an
    /// NSTextField hand a click to the URL — without it the attribute renders blue and does
    /// nothing, which is worse than plain text because it looks broken.
    private static func linkField(label: String, handle: String, url: String) -> NSTextField {
        let line = NSMutableAttributedString(
            string: label + "   ",
            attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .medium),
                         .foregroundColor: NSColor.secondaryLabelColor])
        line.append(NSAttributedString(
            string: handle,
            attributes: [.font: NSFont.systemFont(ofSize: 12),
                         .link: url,
                         .foregroundColor: NSColor.linkColor]))
        let f = NSTextField(labelWithAttributedString: line)
        f.isSelectable = true
        f.allowsEditingTextAttributes = true
        f.toolTip = url
        return f
    }

    private static func heading(_ s: String) -> NSTextField { UI.heading(s) }
    private static func body(_ s: String) -> NSTextField { UI.body(s) }
    private static func pad(_ stack: NSStackView) -> NSView { UI.pad(stack, inset: 24) }

    // refreshLicenseTab() and Handler (key-field activation, Buy button) lived here to drive the
    // License tab above. Both went with it — there is nothing left in this file that talks to
    // Trial or License.
}
