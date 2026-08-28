import AppKit
import ChuteCore

/// Recent Copies — the last few things Chute put on your clipboard.
///
/// ── WHY THERE IS NOTHING TO LEARN ───────────────────────────────────────────────────────────
///
/// The first version of this was a "Clipboard Buffer" with an "Add Clipboard to Buffer" command:
/// you copied something, then remembered to open the menu and press Add. That is a ritual, and
/// the moment you need it is precisely the moment you have forgotten it — by the time you think
/// "I should have kept that", the next copy has already replaced it. Owner's verdict: not
/// comprehensible.
///
/// So there is no verb. Everything Chute hands you is remembered as it is handed over. You
/// right-click a folder, or run a command, and it is here afterwards. Click one to put it back on
/// the clipboard.
///
/// ── AND IT IS STILL NOT CLIPBOARD HISTORY ───────────────────────────────────────────────────
///
/// Nothing here WATCHES. There is no pasteboard observer, no `changeCount` poll, no timer, and
/// no menu item that captures the clipboard. Everything this menu records, it recorded because
/// this app put it on your clipboard at your request.
///
/// THE ONE EXCEPTION, STATED, BECAUSE THE CLAIM WAS OVERSOLD. This comment used to say it was
/// "not possible" for a password copied out of a manager to appear in this list. That was false,
/// and security review caught it: `chute buf add` with no argument reads whatever is on the
/// pasteboard right now (Sources/chute/Commands/ContextCommands.swift) and files it in the same
/// store this menu displays. It is an explicit command a person types, not a background capture
/// — but "you can put anything here on purpose" is a different sentence from "this cannot
/// contain your password", and only the first one is true.
///
/// So the honest version: nothing reaches this list passively. The menu has no verb that adds
/// the clipboard, and it never will. The CLI has one, deliberately, and it does exactly what its
/// name says.
///
/// Hidden entirely until there is something in it, so it costs a reader nothing on day one.
enum BufferMenu {
    static func append(to menu: NSMenu, target: AnyObject) {
        let entries = ContextBuffer().entries().reversed().map { $0 }   // newest first, as read
        guard !entries.isEmpty else { return }

        let parent = NSMenuItem(title: "Recent Copies  (\(entries.count))",
                                action: nil, keyEquivalent: "")
        let sub = NSMenu()

        for e in entries {
            let item = NSMenuItem(title: "\(e.preview)      \(SessionPhrasing.ago(e.date))",
                                  action: #selector(AppDelegate.bufferCopyOne(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = e.name
            item.toolTip = "Put this back on the clipboard."
            sub.addItem(item)
        }

        sub.addItem(.separator())

        // JTBD 22: the four things you collected, pasted once. Named for what it does rather than
        // for the mechanism — "flush the buffer" is a sentence about the implementation.
        let all = NSMenuItem(title: "Copy All \(entries.count) Together",
                             action: #selector(AppDelegate.bufferFlush), keyEquivalent: "")
        all.target = target
        sub.addItem(all)

        // No confirmation sheet, and no ellipsis. These refill themselves every time you use the
        // product, so nothing here is a thing you spent five minutes assembling by hand — the
        // dialog would cost more attention than the contents are worth.
        let clear = NSMenuItem(title: "Clear", action: #selector(AppDelegate.bufferClear),
                               keyEquivalent: "")
        clear.target = target
        sub.addItem(clear)

        parent.submenu = sub
        menu.addItem(parent)
    }
}
