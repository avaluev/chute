import Cocoa
import FinderSync
import ChuteCore

/// Chute's actions in the Finder context menu — inline, on files, on folders, and on the empty
/// background of a window. Every item comes from `ChuteActions.all`; this file only draws them and
/// hands the work over.
///
/// There is deliberately NO main.swift: `NSExtensionMain` is a C entry point that cannot be called
/// from Swift. The binary is linked with `-Xlinker -e -Xlinker _NSExtensionMain`.
///
/// TWO THINGS THAT WILL BITE THE NEXT PERSON, both measured here:
///
/// 1. **`representedObject` does not survive the trip to Finder.** A FinderSync menu is built in
///    this process and rendered by Finder, and only the plain properties cross that boundary —
///    `tag` does, `representedObject` comes back nil. Dispatching on it meant EVERY menu item was
///    a silent no-op: the menu appeared, clicks did nothing, and nothing was logged anywhere.
///    Actions are therefore addressed by `tag`, an index into `ChuteActions.all`.
///
/// 2. **The extension is sandboxed and so is anything it spawns.** `git` refuses to run at all
///    ("xcrun: error: cannot be used within an App Sandbox"), launching an app is denied
///    (`_LSOpenURLsWithCompletionHandler … error -54`), and AppleScript to Terminal is denied
///    ("A privilege violation occurred. (-10004)"). So the extension writes a request and
///    `ChuteApp` — unsandboxed — carries it out. `NSHomeDirectory()` here is the container, never
///    the real home, so every path is absolute and comes from Finder.
@objc(ChuteFinderSync)
class ChuteFinderSync: FIFinderSync {

    override init() {
        super.init()
        // An extension observing nothing shows no menu, and says nothing about why.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        mark("extension-loaded", "loaded · \(ChuteActions.all.count) actions")
    }

    /// Breadcrumbs in ~/.chute. `log show` is unreliable for an appex, and every Finder-menu
    /// problem starts with the same three questions: did it load, did it draw, did the click land?
    private func mark(_ name: String, _ text: String) {
        try? "\(text) · \(Date())\n".write(
            toFile: "/Users/" + NSUserName() + "/.chute/\(name).txt",
            atomically: true, encoding: .utf8)
    }

    /// The folder an action applies to: the selected folder, the parent of a selected file, or the
    /// folder whose background was right-clicked.
    private func targetFolder() -> (path: String, isFolder: Bool)? {
        let controller = FIFinderSyncController.default()
        guard let url = controller.selectedItemURLs()?.first ?? controller.targetedURL() else { return nil }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }
        return isDir.boolValue
            ? (url.path, true)
            : ((url.path as NSString).deletingLastPathComponent, false)
    }

    // MARK: - Menu

    /// The actions sit INLINE in Finder's own context menu — Finder renders every top-level
    /// item of the returned menu directly, so there is no `Chute ▸` hop any more. One click
    /// fewer per action, and the group is branded by its SF Symbol icons instead of a wrapper
    /// (an icon is a plain property, so unlike `representedObject` it survives the trip to
    /// Finder). Only the three tree depths keep a submenu: they are one action with a knob,
    /// not three actions.
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let root = NSMenu(title: "Chute")

        let selection = FIFinderSyncController.default().selectedItemURLs() ?? []
        let target = targetFolder()
        let visible = ChuteActions.visible(hasSelection: !selection.isEmpty,
                                           targetIsFolder: target?.isFolder ?? true)

        var submenus: [String: NSMenu] = [:]
        for action in visible {
            let item = NSMenuItem(title: action.title(count: selection.count),
                                  action: #selector(run(_:)), keyEquivalent: "")
            item.target = self
            item.toolTip = action.detail
            item.image = Self.icon(action.symbol, label: action.plainTitle)
            // The tag is the ONLY reliable way back to the action — see the note above.
            item.tag = ChuteActions.all.firstIndex(where: { $0.id == action.id }) ?? 0

            guard let parentTitle = action.parentTitle else { root.addItem(item); continue }
            if submenus[parentTitle] == nil {
                let holder = NSMenuItem(title: parentTitle, action: nil, keyEquivalent: "")
                holder.image = Self.icon(action.symbol, label: parentTitle)
                let menu = NSMenu(title: parentTitle)
                root.addItem(holder)
                root.setSubmenu(menu, for: holder)
                submenus[parentTitle] = menu
            }
            submenus[parentTitle]?.addItem(item)
        }

        mark("extension-menu", "menu · kind \(menuKind.rawValue) · \(selection.count) selected · \(root.numberOfItems) items inline")
        return root
    }

    /// Pre-rendered at a fixed size, not handed over as a live symbol. Two reasons, both learned
    /// on this menu: hairline outlines at Finder's default rendering are a grey smudge, and an
    /// NSImage is RE-ENCODED on its way across the appex → Finder boundary, where a symbol's
    /// SymbolConfiguration can be dropped — a plain bitmap cannot be. Drawn black-on-alpha at
    /// 2x with `isTemplate` on, so the system tints it correctly for dark mode, light mode and
    /// the selection highlight.
    static func icon(_ symbol: String, label: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold, scale: .large)
        guard let base = NSImage(systemSymbolName: symbol, accessibilityDescription: label)?
                .withSymbolConfiguration(config) else { return nil }

        let points = NSSize(width: 18, height: 18)
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 36, pixelsHigh: 36,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0) else { return base }
        rep.size = points   // 36 px into 18 pt = @2x, crisp on retina
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let s = base.size
        let scale = min(points.width / s.width, points.height / s.height)
        let w = s.width * scale, h = s.height * scale
        base.draw(in: NSRect(x: (points.width - w) / 2, y: (points.height - h) / 2,
                             width: w, height: h))
        NSGraphicsContext.restoreGraphicsState()

        let out = NSImage(size: points)
        out.addRepresentation(rep)
        out.isTemplate = true
        out.accessibilityDescription = label
        return out
    }

    // MARK: - Running

    @objc func run(_ sender: NSMenuItem) {
        let actions = ChuteActions.all
        guard sender.tag >= 0, sender.tag < actions.count else { return }
        let action = actions[sender.tag]
        mark("extension-action", "clicked \(action.id)")

        let controller = FIFinderSyncController.default()
        let files = (controller.selectedItemURLs() ?? []).map(\.path)
        if action.scope == .selection, files.isEmpty {
            return notify(action: action, message: "Nothing is selected.")
        }
        guard let target = targetFolder() else {
            return notify(action: action, message: "Could not tell which folder this is.")
        }
        do {
            try ActionInbox.write(ActionRequest(id: action.id, dir: target.path, files: files))
        } catch {
            return notify(action: action, message: "Failed — could not reach Chute: \(error.localizedDescription)")
        }
        // Chute.app reports the outcome once the work is done; a second banner per click is noise.
        // If it never picks the request up, that silence is itself the thing worth reporting.
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
            if ActionInbox.drain().contains(where: { $0.request.id == action.id }) {
                self.notify(action: action, message: "Chute is not running — open Chute and try again.")
            }
        }
    }

    /// Failures only. Successes are announced by ChuteApp, which is the process that did the work
    /// and can post a proper notification under Chute's own name.
    private func notify(action: ChuteAction, message: String) {
        func escape(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "'")
        }
        let osa = Process()
        osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osa.arguments = ["-e", "display notification \"\(escape(message))\" with title \"Chute\" "
                             + "subtitle \"\(escape(action.plainTitle))\""]
        try? osa.run()
        osa.waitUntilExit()
    }
}
