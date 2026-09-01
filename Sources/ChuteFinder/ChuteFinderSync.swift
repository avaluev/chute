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
            item.image = Self.icon(action.symbol, tint: Self.tint(action.kind),
                                   label: action.plainTitle)
            // The tag is the ONLY reliable way back to the action — see the note above.
            item.tag = ChuteActions.all.firstIndex(where: { $0.id == action.id }) ?? 0

            guard let parentTitle = action.parentTitle else { root.addItem(item); continue }
            if submenus[parentTitle] == nil {
                let holder = NSMenuItem(title: parentTitle, action: nil, keyEquivalent: "")
                // The holder inherits the FIRST child's icon and kind, which is why the tree
                // depths are all .copy and the two agent actions are both .setup: a submenu whose
                // rows disagree about safety cannot be honestly coloured by one of them.
                holder.image = Self.icon(action.symbol, tint: Self.tint(action.kind),
                                         label: parentTitle)
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

    /// Colour by what the action DOES, not by which action it is.
    ///
    /// This was a `[symbol: NSColor]` table, and it was missing four of the symbols —
    /// `arrow.down.doc.fill`, `doc.badge.gearshape.fill`, `shippingbox.and.arrow.backward.fill`
    /// and `trash.fill` — so each of them fell through to `?? .systemBlue`. "Move Junk to Trash"
    /// was drawn the same blue as "Copy Full Paths". A partial lookup with a default cannot tell
    /// you it is incomplete; a switch over an enum will not compile until it is.
    ///
    /// Seven arbitrary hues also asked colour to do a job it is bad at. A reader cannot hold
    /// "teal means bundle" in their head, but they can hold "red means it changes something".
    /// Identity stays with the icon and the word — no two drawn rows share a symbol — and colour
    /// answers the one question worth answering before the mouse comes up: is this safe?
    ///
    /// Mid-saturation system colours, so they hold up on both light and dark menu backgrounds,
    /// and they follow the user's accessibility settings rather than fixed RGB.
    static func tint(_ kind: ChuteAction.Kind) -> NSColor {
        switch kind {
        case .copy:        return .systemBlue      // reads; nothing on disk moves
        case .create:      return .systemGreen     // makes something that was not there
        case .setup:       return .systemPurple    // prepares a folder, additively
        case .destructive: return .systemRed       // changes what exists — and always asks first
        case .open:        return .systemIndigo    // leaves Finder
        }
    }

    /// Pre-rendered at a fixed size, not handed over as a live symbol. Two reasons, both learned
    /// on this menu: hairline outlines at Finder's default rendering are a grey smudge, and an
    /// NSImage is RE-ENCODED on its way across the appex → Finder boundary, where a symbol's
    /// SymbolConfiguration can be dropped — a plain bitmap cannot be. The colour is baked into
    /// the bitmap and `isTemplate` stays OFF: a template is tinted monochrome by the system,
    /// which is exactly what made the icons hard to tell apart.
    /// Rendered once per symbol+colour, not once per right-click. There are fourteen actions and
    /// the bitmap below is redrawn for each of them every time the menu is built — work repeated
    /// on the one path where a delay is most visible, because the menu cannot appear until it is
    /// done. The set of icons is fixed at fourteen, so this never grows.
    nonisolated(unsafe) private static var iconCache: [String: NSImage] = [:]

    static func icon(_ symbol: String, tint: NSColor, label: String) -> NSImage? {
        let cacheKey = "\(symbol)|\(tint.description)"
        if let hit = iconCache[cacheKey] { return hit }
        let made = render(symbol, tint: tint, label: label)
        if let made { iconCache[cacheKey] = made }
        return made
    }

    private static func render(_ symbol: String, tint: NSColor, label: String) -> NSImage? {
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
        let frame = NSRect(x: (points.width - w) / 2, y: (points.height - h) / 2,
                           width: w, height: h)
        base.draw(in: frame)
        tint.setFill()
        NSRect(origin: .zero, size: points).fill(using: .sourceAtop)   // recolour the glyph only
        NSGraphicsContext.restoreGraphicsState()

        let out = NSImage(size: points)
        out.addRepresentation(rep)
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
                // NOT "Chute is not running": from in here that cannot be told apart from Chute
                // being busy — a confirmation sheet open from a previous destructive action
                // blocks its main queue and the inbox is not drained until it is answered. The
                // old wording was a false statement in that case, and the app then reported the
                // action a second time when the sheet was dismissed.
                self.notify(action: action,
                            message: "Still queued — Chute has not picked this up yet. It may be "
                                   + "waiting for an answer in another window.")
            }
        }
    }

    /// Failures only. Successes are announced by ChuteApp, which is the process that did the work
    /// and can post a proper notification under Chute's own name.
    private func notify(action: ChuteAction, message: String) {
        let osa = Process()
        osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osa.arguments = ["-e", "display notification \"\(AppleScript.escape(message))\" with title \"Chute\" "
                             + "subtitle \"\(AppleScript.escape(action.plainTitle))\""]
        try? osa.run()
        osa.waitUntilExit()
    }
}
