import Cocoa
import FinderSync

/// The `Chute ▸` submenu in the Finder context menu — on files, on folders, and on the empty
/// background of a window.
///
/// There is deliberately NO main.swift: `NSExtensionMain` is a C entry point that cannot be called
/// from Swift. The binary is linked with `-Xlinker -e -Xlinker _NSExtensionMain` instead.
///
/// SANDBOX FACTS, each measured in this extension, not assumed:
///   · the appex is sandboxed (`LSApplicationInSandboxKey=true`) and so is anything it spawns;
///   · spawning the bundled `chute` IS permitted, and its writes DO land on the real filesystem;
///   · `NSHomeDirectory()` here is the container, not `/Users/<you>` — so every path handed to
///     `chute` must be absolute and come from Finder, never built from `~` or the home directory.
@objc(ChuteFinderSync)
class ChuteFinderSync: FIFinderSync {

    /// (title, chute subcommand, needs a selection)
    static let actions: [(String, [String], Bool)] = [
        ("Copy Paths for Prompt",     ["paths"],                 true),
        ("Bundle Context (XML)",      ["bundle"],                true),
        ("Copy Redacted",             ["redact"],                true),
        ("New File from Clipboard",   ["new", "--reveal"],       false),
        ("Unpack Markdown Here",      ["unpack"],                false),
        ("Checkpoint Before Agent",   ["checkpoint"],            false),
        ("Sandbox + Agent (yolo)",    ["sandbox", "--yolo"],     false),
        ("Open Terminal Here",        ["open"],                  false),
    ]

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

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let root = NSMenu(title: "Chute")
        let parent = NSMenuItem(title: "Chute", action: nil, keyEquivalent: "")
        let sub = NSMenu(title: "Chute")

        let hasSelection = !(FIFinderSyncController.default().selectedItemURLs()?.isEmpty ?? true)

        for (index, action) in Self.actions.enumerated() {
            if action.2 && !hasSelection { continue }
            let item = NSMenuItem(title: action.0, action: #selector(run(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            sub.addItem(item)
        }

        root.addItem(parent)
        root.setSubmenu(sub, for: parent)
        return root
    }

    @objc func run(_ sender: NSMenuItem) {
        let (_, argv, needsSelection) = Self.actions[sender.tag]
        let controller = FIFinderSyncController.default()

        var args = argv
        if needsSelection {
            let urls = controller.selectedItemURLs() ?? []
            guard !urls.isEmpty else { return }
            args += urls.map(\.path)
        } else {
            let target = controller.selectedItemURLs()?.first ?? controller.targetedURL()
            guard let target else { return }
            var dir = target.path
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: dir, isDirectory: &isDir), !isDir.boolValue {
                dir = (dir as NSString).deletingLastPathComponent
            }
            // `unpack`, `new` and `sandbox` take --dir; `checkpoint` and `open` take a positional.
            args += (argv[0] == "checkpoint" || argv[0] == "open") ? [dir] : ["--dir", dir]
        }
        launch(args)
    }

    private func launch(_ args: [String]) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: chuteBinary)
        p.arguments = args
        let err = Pipe()
        p.standardError = err
        p.standardOutput = Pipe()
        do { try p.run() } catch {
            NSLog("Chute: cannot run %@: %@", chuteBinary, error.localizedDescription)
            return
        }
        // Read the pipe on a background queue: a menu action must never block Finder, and a full
        // pipe buffer would deadlock the child if nobody drains it.
        DispatchQueue.global(qos: .utility).async {
            let data = err.fileHandleForReading.readDataToEndOfFile()
            p.waitUntilExit()
            let message = String(decoding: data, as: UTF8.self)
                .split(separator: "\n").last.map(String.init) ?? "done"
            self.notify(message)
        }
    }

    /// A silent action reads as "nothing happened", so every run reports. `display notification`
    /// via osascript is what a sandboxed appex can reach — measured, along with its exit status.
    func notify(_ message: String) {
        let safe = message.replacingOccurrences(of: "\"", with: "'")
        let osa = Process()
        osa.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osa.arguments = ["-e", "display notification \"\(safe)\" with title \"Chute\""]
        let err = Pipe()
        osa.standardError = err
        do { try osa.run() } catch {
            NSLog("Chute: notification spawn failed: %@", error.localizedDescription)
            return
        }
        let data = err.fileHandleForReading.readDataToEndOfFile()
        osa.waitUntilExit()
        if osa.terminationStatus != 0 {
            NSLog("Chute: notification refused (status %d): %@", osa.terminationStatus,
                  String(decoding: data, as: UTF8.self))
        }
    }
}
