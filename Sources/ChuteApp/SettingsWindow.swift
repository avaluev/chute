import AppKit
import ChuteCore

/// Settings and About.
///
/// Hand-built AppKit, like FirstRunWindow: there is no Xcode in this build, so no xib and no
/// storyboard. There was a third, License, tab — it and the key field it held went with the paid
/// price on 2026-09-08, when Chute went free and MIT. Two tabs is what a free app needs.
enum SettingsWindow {
    nonisolated(unsafe) static var window: NSWindow?

    /// MEASURED, NOT CHOSEN. `UI.pad` pins the stack's bottom with `lessThanOrEqualTo`, so content
    /// taller than the window is not a broken constraint — it is silently CLIPPED, and the reader
    /// never learns there was more. The About tab grew from 314pt to 535pt of content when the
    /// first-person opening and the star CTA landed on 2026-09-08, which put the button and all
    /// three contact rows below the fold of the old 420pt window.
    ///
    /// 535 + 48 (the 24pt inset, twice) + 28 (the tab bar) = 611. This is that, rounded up for one
    /// notch of larger accessibility text. Re-measure before trimming it: build the About stack,
    /// call `fittingSize.height`, and read the number rather than judging it by eye in one theme
    /// at one text size. The window stays resizable, which is the mitigation for everything past
    /// that notch.
    static let size = NSSize(width: 520, height: 640)

    static func show(selecting tab: Int = 0) {
        if let w = window {
            NSApp.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            return
        }
        let w = Panel.make(title: "Chute Settings", width: size.width, height: size.height)
        let tabs = NSTabView(frame: NSRect(origin: .zero, size: size))
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
            // NO COUNTS IN THE COPY. They used to read "the 9 actions" and "runs 10 checks",
            // derived rather than typed — which solved staleness and left the sentences sounding
            // like a machine describing an inventory. A person reading a Settings pane wants to
            // know what is there, not how many of it there are. The derivation guarded a number
            // that should never have been in the sentence; deleting the number deletes the
            // problem. Any count that stays anywhere in this repo is still read, never typed.
            body("""
                 Finder — right-click a file or a folder. Chute's actions are in the menu.

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
            body("`chute doctor` checks the extension, the Automation permission and the "
                 + "hooks, and prints the fix for whatever is not working. `chute doctor --fix` "
                 + "applies the ones it can."),
        ])
        return pad(v)
    }

    private static func about() -> NSView {
        // The words are `ChuteCore.AboutText`, where the suite can read them. This end decides
        // nothing — see that file for why the old sentence had to go.
        let a = AboutText.about(version: ChuteVersion.current, build: Diagnostics.installedBuild())
        // A SELECTABLE FIELD WITH .link ATTRIBUTES, not a row of NSButtons. AppKit opens a link in
        // a selectable text field on click with no target, no action and no handler object — so
        // three contact rows cost this file zero decision points, which matters because
        // Scripts/check-untested-logic.sh holds it to a budget it only just earned by losing the
        // licence tab. The labels and URLs are AboutText.contacts, where the suite can read them.
        let links = AboutText.contacts.map { linkField(label: $0.label, handle: $0.handle, url: $0.url) }
        // The star CTA is the one row that IS an NSButton — see starButton() for why a button and
        // not a fourth link.
        //
        // BUILT IN NAMED STEPS, not one long `+` chain. Swift's Array is invariant, so every
        // element needs an explicit upcast to NSView, and the fully-inlined version of this
        // expression made the type-checker give up outright: "unable to type-check this
        // expression in reasonable time". Each `let` below is an annotated sub-expression, which
        // is the documented fix and also reads better than the chain did.
        //
        // `compactMap` over the optional heading rather than an `if` — a section without one (the
        // build stamp) simply contributes no heading view. This file is held to a hard cap on
        // decision points, and a branch here would spend the last of it on layout.
        let sections: [NSView] = a.body.flatMap { section -> [NSView] in
            let head: NSView? = section.heading.map { heading($0) }
            return [head, body(section.text) as NSView].compactMap { $0 }
        }
        let contact: [NSView] = [heading(AboutText.contactHeading), body(AboutText.contactLead)]
        let contactLinks: [NSView] = links
        let views: [NSView] = [heading(a.heading)] + sections + [starButton()] + contact + contactLinks
        return pad(NSStackView(views: views))
    }

    /// THE STAR CTA. `AboutText.starReason` is the copy that sits above this in the stack — the
    /// reason comes first, the button second, so it reads as an argument and not a plea. Target
    /// and action need an `NSObject`, and `SettingsWindow` is an enum, so `Handler` below carries
    /// the one-line `@objc` handler — the same shape as `AppDelegate.openNotificationSettings` at
    /// `Sources/ChuteApp/main.swift:245-247`. `AboutText.starURL` is a `URL`, not a `String`, so
    /// there is nothing here to guard or force-unwrap: zero decision points either way.
    private static func starButton() -> NSButton {
        NSButton(title: AboutText.starTitle, target: Handler.shared, action: #selector(Handler.openStar))
    }

    final class Handler: NSObject {
        nonisolated(unsafe) static let shared = Handler()
        @objc func openStar() { NSWorkspace.shared.open(AboutText.starURL) }
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

    // refreshLicenseTab() and a DIFFERENT Handler (key-field activation, Buy button) lived here to
    // drive the License tab above. Both went with it on 2026-09-08 — the Handler above this
    // comment is new, for the star button, and talks to neither Trial nor License.
}
