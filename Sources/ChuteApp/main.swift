import AppKit
import Carbon.HIToolbox
import ChuteCore

/// Every action is the CLI. The app is a surface, never a second implementation.
struct Action {
    let title: String
    let key: String
    let run: () -> Void
}

let chuteBinary: String = {
    let bundled = Bundle.main.bundlePath + "/Contents/MacOS/chute"
    if FileManager.default.isExecutableFile(atPath: bundled) { return bundled }
    return Shell.which("chute") ?? "/usr/local/bin/chute"
}()

@discardableResult
func chute(_ args: [String], cwd: String? = nil) -> ShellResult {
    Shell.run(chuteBinary, args, cwd: cwd)
}

func notify(_ title: String, _ body: String) {
    Shell.launch("osascript", ["-e",
        "display notification \"\(body.replacingOccurrences(of: "\"", with: "'"))\" with title \"\(title)\""])
}

let actions: [Action] = [
    Action(title: "Copy Paths for Prompt", key: "1") {
        let sel = FinderBridge.selection()
        guard !sel.isEmpty else { return notify("Chute", "Nothing selected in Finder") }
        chute(["paths"] + sel)
        notify("Chute", "\(sel.count) path(s) copied")
    },
    Action(title: "Bundle Context (XML)", key: "2") {
        let sel = FinderBridge.selection()
        guard !sel.isEmpty else { return notify("Chute", "Nothing selected in Finder") }
        let r = chute(["bundle"] + sel)
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "New File from Clipboard", key: "3") {
        let r = chute(["new", "--dir", FinderBridge.currentFolder(), "--reveal"])
        notify("Chute", r.ok ? "Created \((r.out.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).lastPathComponent)"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "Unpack Markdown Here (preview)", key: "4") {
        let r = chute(["unpack", "--dir", FinderBridge.currentFolder()])
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "Sandbox + Agent (yolo)", key: "5") {
        chute(["sandbox", "--dir", FinderBridge.currentFolder(), "--yolo"])
    },
    Action(title: "Checkpoint Before Agent", key: "6") {
        let r = chute(["checkpoint", FinderBridge.currentFolder()])
        notify("Chute", r.ok ? "Snapshot: \(r.out.trimmingCharacters(in: .whitespacesAndNewlines))"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
    Action(title: "Open Terminal Here", key: "7") {
        chute(["open", FinderBridge.currentFolder()])
    },
    Action(title: "Copy Redacted", key: "8") {
        let r = chute(["redact"])
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    },
]

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ n: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⤓"
        statusItem.button?.toolTip = "Chute — drop context into your agent"
        statusItem.menu = buildMenu()
        NSApp.servicesProvider = ServicesProvider()
        NSUpdateDynamicServices()
        registerHotKey()
        FirstRunWindow.showIfNeeded()
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()
        for (i, a) in actions.enumerated() {
            let item = NSMenuItem(title: a.title, action: #selector(fire(_:)), keyEquivalent: a.key)
            item.keyEquivalentModifierMask = []
            item.target = self
            item.tag = i
            menu.addItem(item)
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Hotkey: ⌥⌘N", action: nil, keyEquivalent: ""))
        let setupItem = NSMenuItem(title: "Setup Check…", action: #selector(openSetup), keyEquivalent: "")
        setupItem.target = self
        menu.addItem(setupItem)
        menu.addItem(NSMenuItem(title: "Quit Chute", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    @objc func openSetup() { FirstRunWindow.show() }

    @objc func fire(_ sender: NSMenuItem) {
        let action = actions[sender.tag]
        DispatchQueue.global(qos: .userInitiated).async { action.run() }
    }

    /// FE-02 — ⌥⌘N pops the action list at the pointer, wherever you are.
    func registerHotKey() {
        var hotKeyID = EventHotKeyID(signature: OSType(0x43485554), id: 1)   // 'CHUT'
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            DispatchQueue.main.async { (NSApp.delegate as? AppDelegate)?.showHUD() }
            return noErr
        }, 1, &eventType, nil, nil)
        RegisterEventHotKey(UInt32(kVK_ANSI_N), UInt32(optionKey | cmdKey),
                            hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func showHUD() {
        let menu = buildMenu()
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

/// FE-01 — Finder right-click entries. Declared in Info.plist, handled here.
final class ServicesProvider: NSObject {
    private func paths(_ pboard: NSPasteboard) -> [String] {
        (pboard.readObjects(forClasses: [NSURL.self]) as? [URL])?.map(\.path) ?? []
    }

    @objc func copyPaths(_ pboard: NSPasteboard, userData: String?,
                         error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let p = paths(pboard)
        guard !p.isEmpty else { return notify("Chute", "No files received") }
        chute(["paths"] + p)
        notify("Chute", "\(p.count) path(s) copied")
    }

    @objc func bundleContext(_ pboard: NSPasteboard, userData: String?,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let p = paths(pboard)
        guard !p.isEmpty else { return notify("Chute", "No files received") }
        let r = chute(["bundle"] + p)
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @objc func newFromClipboard(_ pboard: NSPasteboard, userData: String?,
                                error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first.map { FileScan.isDirectory($0) ? $0 : ($0 as NSString).deletingLastPathComponent }
            ?? FinderBridge.currentFolder()
        let r = chute(["new", "--dir", dir, "--reveal"])
        notify("Chute", r.ok ? "Created \((r.out.trimmingCharacters(in: .whitespacesAndNewlines) as NSString).lastPathComponent)"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @objc func unpackHere(_ pboard: NSPasteboard, userData: String?,
                          error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first ?? FinderBridge.currentFolder()
        let r = chute(["unpack", "--dir", FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent])
        notify("Chute", r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @objc func sandboxHere(_ pboard: NSPasteboard, userData: String?,
                           error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first ?? FinderBridge.currentFolder()
        chute(["sandbox", "--dir", FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent, "--yolo"])
    }

    @objc func checkpointHere(_ pboard: NSPasteboard, userData: String?,
                              error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let dir = paths(pboard).first ?? FinderBridge.currentFolder()
        let r = chute(["checkpoint", FileScan.isDirectory(dir) ? dir : (dir as NSString).deletingLastPathComponent])
        notify("Chute", r.ok ? "Snapshot: \(r.out.trimmingCharacters(in: .whitespacesAndNewlines))"
                             : r.err.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)     // LSUIElement — menu bar only, no Dock icon
app.run()
