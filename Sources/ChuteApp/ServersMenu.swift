import AppKit
import ChuteCore

/// The "Local servers" section of the menu bar: what is listening, and what to do about it.
/// Kept apart from AppDelegate because it is a whole feature, not a menu detail.
extension AppDelegate {
    /// FR-25 — what is running locally right now. Two `lsof` calls, made only when the menu opens.
    func appendLocalServers(to menu: NSMenu) {
        let servers = LocalServers.discover()
        let title = servers.isEmpty ? "No local servers running" : "Local servers (\(servers.count))"
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menu.addItem(parent)
        guard !servers.isEmpty else { return }

        let sub = NSMenu()
        for server in servers {
            let item = NSMenuItem(title: server.label, action: nil, keyEquivalent: "")
            item.toolTip = server.loopbackOnly
                ? "Reachable from this Mac only — pid \(server.pid)"
                : "Reachable from your whole network — pid \(server.pid)"
            let actions = NSMenu()
            for (label, selector) in [("Open in Browser", #selector(openServer(_:))),
                                      ("Copy \(server.url)", #selector(copyServerURL(_:))),
                                      ("Stop It (kill \(server.pid))", #selector(killServer(_:)))] {
                let action = NSMenuItem(title: label, action: selector, keyEquivalent: "")
                action.target = self
                action.representedObject = server.port
                actions.addItem(action)
            }
            sub.addItem(item)
            sub.setSubmenu(actions, for: item)
        }
        menu.setSubmenu(sub, for: parent)
    }

    @objc func openServer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }
        NSWorkspace.shared.open(URL(string: "http://localhost:\(port)")!)
    }

    @objc func copyServerURL(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }
        Clipboard.write("http://localhost:\(port)")
        notify("Local servers", "Copied http://localhost:\(port)")
    }

    @objc func killServer(_ sender: NSMenuItem) {
        guard let port = sender.representedObject as? Int else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let pids = LocalServers.kill(port: port)
            notify("Local servers", pids.isEmpty
                   ? "Nothing was listening on \(port) any more."
                   : "Stopped \(pids.count) process(es) on port \(port).")
        }
    }
}
