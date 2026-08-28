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
/// Chute records what it WROTE, never what it read. There is no pasteboard observer, no
/// `changeCount` poll, no timer. It is not possible for a password you copied out of a manager,
/// or a message from a chat window, to appear in this list: nothing reaches it that this app did
/// not produce because you asked it to. That is the difference between a feature and a red flag,
/// and it is why this is not off by default and needs no explaining.
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
