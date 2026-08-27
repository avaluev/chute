import AppKit
import ChuteCore

/// `chute paste-image --dir <folder>` — the clipboard's image becomes a PNG in that folder, named
/// the way macOS names screenshots, with its name selected so you can type a better one, and its
/// full path on the clipboard ready to paste into a prompt.
///
/// The whole point is the last step: a bug report needs the PATH, and the round trip of
/// screenshot → save → find file → copy path is the friction this removes.
func cmdPasteImage(_ a: Args) {
    let dir = FileScan.absolute(a.value("dir", or: FileManager.default.currentDirectoryPath))
    guard FileScan.isDirectory(dir) else { Out.fail("not a directory: \(dir)") }

    guard let png = clipboardPNG() else {
        Out.fail("no image on the clipboard — take a screenshot (⌃⇧⌘4) or copy an image first")
    }

    let base = a.optional("name") ?? PastedImage.defaultName(at: Date())
    let path: String
    do { path = try NameDerive.writeUniquely(dir: dir,
                                             base: (base as NSString).deletingPathExtension,
                                             ext: "png", data: png) }
    catch { Out.fail("cannot write in \(dir): \(error.localizedDescription)") }

    // The path goes on the clipboard NOW, so it is pasteable even if the rename never happens.
    Clipboard.write(path)
    Out.line(path)

    guard !a.has("no-rename") else {
        Out.info("→ saved · path copied")
        return
    }
    if let problem = FinderReveal.revealAndBeginRename(path) {
        Out.info("→ \(problem) · path copied")
        return
    }
    Out.info("→ saved · rename it, and the new path replaces the old one on your clipboard")
    watchForRename(of: path, in: dir, seconds: Double(a.value("watch-seconds", or: "90")) ?? 90)
}

/// PNG bytes from the clipboard, whatever form the image arrived in. A screenshot is PNG; a copy
/// out of Preview or a browser is often TIFF; either way what lands on disk should be a PNG.
private func clipboardPNG() -> Data? {
    let board = NSPasteboard.general
    if let png = board.data(forType: .png) { return png }
    guard let tiff = board.data(forType: .tiff),
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    return rep.representation(using: .png, properties: [:])
}

/// Waits for Finder's inline rename to finish, then puts the new path on the clipboard.
///
/// There is no notification for "the user stopped typing a file name", so this watches the file
/// itself: the inode does not change when a file is renamed, so it can be found again under its
/// new name. Polling, not FSEvents — this runs for at most ninety seconds in a process that exists
/// only to do this, and a poll loop is a tenth of the code.
private func watchForRename(of path: String, in dir: String, seconds: Double) {
    guard let inode = PastedImage.inode(of: path) else { return }
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
        Thread.sleep(forTimeInterval: 0.4)
        guard let current = PastedImage.path(ofInode: inode, in: dir) else { return }  // moved away
        guard current != path else { continue }
        // Renamed. Only take the clipboard if it is still the path we put there.
        if PastedImage.mayReplaceClipboard(current: Clipboard.read(), weWrote: path) {
            Clipboard.write(current)
            Out.info("→ renamed · new path copied")
        }
        return
    }
}
