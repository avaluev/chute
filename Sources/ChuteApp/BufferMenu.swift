import AppKit
import ChuteCore

/// The Clipboard Buffer submenu — a view onto `chute buf`, and nothing more.
///
/// WHAT THIS IS NOT: clipboard history. Chute does not watch the pasteboard. There is no
/// `changeCount` poll, no timer, no observer, and nothing reaches this list that the user did not
/// hand over deliberately. A passive history would silently hold passwords, licence keys and
/// private messages, and would need a permission story, a retention policy and a paragraph on the
/// privacy page — for a job that "I am collecting four things and the fourth copy must not destroy
/// the first" already solves.
///
/// Hidden entirely when the buffer is empty, so it costs a reader nothing until they use it. Modelled
/// on ServersMenu, which is the same shape: a count in the parent, the contents underneath.
enum BufferMenu {
    static func append(to menu: NSMenu, target: AnyObject) {
        let buf = ContextBuffer()
        let entries = buf.entries()

        // No "(0)". A count of nothing is not a count, it is a row telling you it has nothing
        // to tell you — and this menu just deleted several of those. The item still appears so the
        // one action it offers stays discoverable.
        let parent = NSMenuItem(title: entries.isEmpty
                                    ? "Clipboard Buffer"
                                    : "Clipboard Buffer  (\(entries.count))",
                                action: nil, keyEquivalent: "")
        let sub = NSMenu()

        let add = NSMenuItem(title: "Add Clipboard to Buffer",
                             action: #selector(AppDelegate.bufferAdd), keyEquivalent: "")
        add.target = target
        add.toolTip = "Nothing is captured unless you pick this. Chute never watches your clipboard."
        sub.addItem(add)

        if entries.isEmpty {
            // An empty buffer still shows the ONE thing you can do with it. A submenu that opens
            // onto nothing reads as broken.
            parent.submenu = sub
            menu.addItem(parent)
            return
        }

        sub.addItem(.separator())
        for (i, e) in entries.enumerated() {
            let item = NSMenuItem(title: "\(i + 1).  \(e.preview)",
                                  action: #selector(AppDelegate.bufferCopyOne(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = e.name
            item.toolTip = "Copy just this one back to the clipboard."
            sub.addItem(item)
        }
        sub.addItem(.separator())

        let flush = NSMenuItem(title: "Copy All \(entries.count) and Empty",
                               action: #selector(AppDelegate.bufferFlush), keyEquivalent: "")
        flush.target = target
        sub.addItem(flush)

        // Destructive, so it is ellipsised and confirms — the same rule the Finder menu follows
        // for "Move Junk to Trash…". Losing a collection you spent five minutes assembling to a
        // mis-click is exactly the failure this feature exists to prevent.
        let clear = NSMenuItem(title: "Empty Without Copying…",
                               action: #selector(AppDelegate.bufferClear), keyEquivalent: "")
        clear.target = target
        sub.addItem(clear)

        parent.submenu = sub
        menu.addItem(parent)
    }
}
