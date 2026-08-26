import Cocoa
import FinderSync
import ChuteCore

/// The `Chute ▸` submenu in the Finder context menu — on files, on folders, and on the empty
/// background of a window. Every item comes from `ChuteActions.all`; this file decides only how to
/// draw them and how to report what happened.
///
/// There is deliberately NO main.swift: `NSExtensionMain` is a C entry point that cannot be called
/// from Swift. The binary is linked with `-Xlinker -e -Xlinker _NSExtensionMain` instead.
///
/// SANDBOX FACTS, each measured in this extension rather than assumed:
///   · the appex is sandboxed (`LSApplicationInSandboxKey=true`) and so is anything it spawns;
///   · spawning the bundled `chute` IS permitted and its writes reach the real filesystem;
///   · `NSHomeDirectory()` here is the container, so every path must be absolute and come from
///     Finder — a `~`-relative write lands in the container and still exits 0;
///   · the appex inherits almost no PATH, so `launch` sets one that includes the tools `chute`
///     shells out to (git, claude).
@objc(ChuteFinderSync)
class ChuteFinderSync: FIFinderSync {

    override init() {
        super.init()
        // An extension observing nothing shows no menu, and says nothing about why.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    /// An appex does not reliably inherit PATH, so resolve the binary from our own bundle:
    /// …/Chute.app/Contents/PlugIns/ChuteFinder.appex → up 2 → Contents/MacOS/chute
    private var chuteBinary: String {
        Bundle.main.bundleURL
            .deletingLastPathComponent()   // PlugIns
            .deletingLastPathComponent()   // Contents
            .appendingPathComponent("MacOS/chute")
            .path
    }

    // MARK: - Menu

    /// The folder the action applies to: the selected folder, the parent of the selected file, or
    /// the folder whose background was right-clicked.
    private func targetFolder() -> String? {
        let controller = FIFinderSyncController.default()
        guard let url = controller.selectedItemURLs()?.first ?? controller.targetedURL() else { return nil }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }
        return isDir.boolValue ? url.path : (url.path as NSString).deletingLastPathComponent
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let root = NSMenu(title: "Chute")
        let parent = NSMenuItem(title: "Chute", action: nil, keyEquivalent: "")
        let sub = NSMenu(title: "Chute")

        let selection = FIFinderSyncController.default().selectedItemURLs() ?? []
        let folder = targetFolder()
        let visible = ChuteActions.visible(hasSelection: !selection.isEmpty,
                                           inGitRepo: folder.map(ChuteActions.isInGitRepo) ?? false)

        var lastGroup: String?
        for action in visible {
            if let last = lastGroup, last != action.group { sub.addItem(.separator()) }
            lastGroup = action.group

            let item = NSMenuItem(title: action.title(count: selection.count),
                                  action: #selector(run(_:)), keyEquivalent: "")
            item.target = self
            item.toolTip = action.detail
            item.representedObject = action.id
            sub.addItem(item)
        }

        if visible.isEmpty {
            sub.addItem(withTitle: "Nothing to do here", action: nil, keyEquivalent: "")
        }

        root.addItem(parent)
        root.setSubmenu(sub, for: parent)
        return root
    }

    // MARK: - Running

    /// The extension does not run the action. It writes a request and `ChuteApp` carries it out.
    ///
    /// Measured inside this extension, which is why: `git` refuses to run in a sandbox at all
    /// ("xcrun: error: cannot be used within an App Sandbox"), launching an app is denied
    /// (`_LSOpenURLsWithCompletionHandler() … error -54`), and AppleScript to Terminal is denied
    /// ("A privilege violation occurred. (-10004)"). Spawning `chute` here would work for the
    /// copy actions and silently fail for the rest — a menu where half the items lie.
    @objc func run(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let action = ChuteActions.find(id) else { return }
        let controller = FIFinderSyncController.default()
        let files = (controller.selectedItemURLs() ?? []).map(\.path)

        if action.scope == .selection, files.isEmpty {
            return notify(action: action, message: "Nothing is selected.")
        }
        guard let folder = targetFolder() else {
            return notify(action: action, message: "Could not tell which folder this is.")
        }
        do {
            try ActionInbox.write(ActionRequest(id: action.id, dir: folder, files: files))
        } catch {
            return notify(action: action, message: "Failed — could not reach Chute: \(error.localizedDescription)")
        }
        // Chute.app reports the outcome once the work is done. Say nothing here unless it never
        // picks the request up — a second banner per click is noise.
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
            let pending = ActionInbox.drain().contains { $0.request.id == action.id }
            if pending {
                self.notify(action: action, message: "Chute is not running — open Chute and try again.")
            }
        }
    }

    /// A silent action reads as "nothing happened", so failures always report. Successes are
    /// reported by ChuteApp, which is the process that actually did the work.
    // ponytail: osascript notifications are attributed to Script Editor in Notification Center.
    // Upgrade path if that reads as untrustworthy: UNUserNotificationCenter from a signed app.
    private func notify(action: ChuteAction, message: String) {
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "'")
        }
        let script = """
        display notification "\(escape(message))" with title "Chute" \
        subtitle "\(escape(action.plainTitle))"
        """
        let osa = Process()
        osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osa.arguments = ["-e", script]
        try? osa.run()
        osa.waitUntilExit()
    }
}
