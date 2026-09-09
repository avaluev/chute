// FINDER MENU SHOT — a rendering of Chute's Finder context menu, driven by the menu's own
// source of truth. It is NOT a photograph of Finder.
//
// ── WHY THIS EXISTS ─────────────────────────────────────────────────────────────────────────
//
// macOS cannot screenshot another app's open context menu headlessly: `NSMenu.popUp` needs a
// real tracking loop with a real user session, and Finder's own context menu belongs to Finder,
// not to any process a script controls. There is no API to ask Finder "open this menu and hold
// still." So there has never been an image of the Finder menu anywhere in this repo, on the
// site, or in the README — even though it is half the product (the other half, the menu-bar
// HUD, got this same treatment in `Scripts/menu-shot.swift`, for the same reason).
//
// This draws the menu itself instead of capturing one. Nothing about the CONTENT is invented:
// every row comes from `ChuteActions.rows()` in `Sources/ChuteCore/FinderActions.swift` — the
// same call `chute finder-actions --menu` makes and the same call `ChuteFinderSync.menu(for:)`
// makes to build the real thing — read at THIS SCRIPT'S RUN TIME, not copied out by hand. If a
// row's wording, icon, or grouping ever drifts from what ships, this image drifts with it
// automatically the next time it is regenerated; it can never go stale silently the way a
// hand-drawn mock-up would.
//
// ── HOW IT READS ChuteCore WITHOUT A BUILD SYSTEM ──────────────────────────────────────────
//
// `swift Scripts/finder-shot.swift` runs this file alone, in Swift's single-file script mode —
// no `import ChuteCore` is possible there, because nothing has told the compiler where that
// module lives (this script deliberately touches no other file, including Package.swift, so it
// cannot add itself as a target). So the trick used below is the one `#if` gives for free:
// this file compiles a SECOND time, combined with every file in Sources/ChuteCore/ in one
// `swiftc` invocation with `-DCHUTE_RENDER` set, and that combined binary is what actually
// draws. The first pass (no flag) never type-checks the `#if CHUTE_RENDER` branch below, so it
// has nothing to fail to resolve; the second pass has ChuteCore's declarations in the same
// compilation unit, so `ChuteActions` and `ChuteAction` are visible with no import at all.
// `swiftc` requires the file holding top-level statements to be named literally `main.swift`
// when compiling multiple files together, which is why the bootstrap below copies this file to
// a temp dir under that name before compiling it alongside ChuteCore's sources.
//
// Run from the repo root, matching every other script in this folder:
//   swift Scripts/finder-shot.swift [output.png]
// Defaults to site/public/media/screens/finder-menu.png. A second file, with `-submenu`
// inserted before the extension, renders the same menu with one row's submenu open — pick a
// custom base name and both files follow it.

import Foundation

#if CHUTE_RENDER

// ═══════════════════════════════════════════════════════════════════════════════════════════
// THE RENDERER — compiled together with Sources/ChuteCore/*.swift. ChuteActions, ChuteAction
// and everything else in ChuteCore is visible here with no `import` because this file and
// ChuteCore's sources are, for this one build, the same module.
// ═══════════════════════════════════════════════════════════════════════════════════════════

import AppKit

// tint(_:) mirrors Sources/ChuteFinder/ChuteFinderSync.swift's `tint(_:)` — the one place the
// shipped extension decides colour-by-kind. It cannot be imported: ChuteFinderSync.swift lives
// in the ChuteFinder target and imports FinderSync, a framework this standalone renderer has no
// way to link against. Duplicated by hand instead, same five cases, same colours; if that file's
// mapping ever changes, this one must be brought back in step with it by hand too.
func tint(_ kind: ChuteAction.Kind) -> NSColor {
    switch kind {
    case .copy:        return .systemBlue
    case .create:      return .systemGreen
    case .setup:       return .systemPurple
    case .destructive: return .systemRed
    case .open:        return .systemIndigo
    }
}

// icon(_:tint:) — the same bake-the-colour-into-a-bitmap approach as ChuteFinderSync.icon: a
// live NSMenuItem.image loses isTemplate/SymbolConfiguration on the trip across a process
// boundary, so the shipped extension pre-renders too. Drawn at 2x (36px into an 18pt frame) so
// it stays crisp once composited into the 2x menu bitmap below.
func icon(_ symbol: String, tint: NSColor) -> NSImage? {
    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .semibold, scale: .large)
    guard let base = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }
    let points = NSSize(width: 18, height: 18)
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 36, pixelsHigh: 36,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else { return base }
    rep.size = points
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = base.size
    let scale = min(points.width / s.width, points.height / s.height)
    let w = s.width * scale, h = s.height * scale
    base.draw(in: NSRect(x: (points.width - w) / 2, y: (points.height - h) / 2, width: w, height: h))
    tint.setFill()
    NSRect(origin: .zero, size: points).fill(using: .sourceAtop)   // recolour the glyph only
    NSGraphicsContext.restoreGraphicsState()
    let out = NSImage(size: points)
    out.addRepresentation(rep)
    return out
}

/// One row worth drawing: a title, its already-tinted icon, and whether a chevron belongs on it.
struct PanelRow {
    let title: String
    let image: NSImage?
    let chevron: Bool
}

/// Draws one rounded menu panel — the metrics (21pt leading pad, 5pt icon gap, 10pt corner
/// radius, `NSColor(calibratedWhite: 0.16)` ground) match `Scripts/menu-shot.swift`'s own
/// `--draw` block, so a Finder-menu shot and a status-bar-menu shot from this repo read as the
/// same product. Baked at 2x explicitly (not via `lockFocus`, whose backing scale depends on
/// whatever screen happens to be attached) so the PNG is retina regardless of the machine that
/// renders it. Returns the top offset of every row (measured down from the panel's own top) so
/// a caller composing a submenu beside it can line the two up.
func makePanel(_ rows: [PanelRow], highlight: Int?) -> (image: NSImage, size: NSSize, rowTops: [CGFloat]) {
    let leftPad: CGFloat = 21, imgGap: CGFloat = 5, vPad: CGFloat = 5
    let trailingPad: CGFloat = 14, chevronGap: CGFloat = 10, chevronBox: CGFloat = 12
    let font = NSFont.menuFont(ofSize: 0)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white]

    var lineHeights: [CGFloat] = []
    var maxTextWidth: CGFloat = 0
    for row in rows {
        let size = (row.title as NSString).size(withAttributes: attrs)
        maxTextWidth = max(maxTextWidth, size.width)
        lineHeights.append(ceil(size.height) + vPad * 2)
    }
    let hasChevron = rows.contains { $0.chevron }
    let width = leftPad + 18 + imgGap + maxTextWidth + (hasChevron ? chevronGap + chevronBox : 0) + trailingPad

    var rowTops: [CGFloat] = []
    var cursor: CGFloat = 6   // top margin, matching menu-shot.swift's `total = heights.reduce(12, +)`
    for h in lineHeights { rowTops.append(cursor); cursor += h }
    let total = cursor + 6   // bottom margin
    let size = NSSize(width: width, height: total)

    let scale: CGFloat = 2   // RETINA, baked in — see the function comment.
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: Int(size.width * scale),
                                     pixelsHigh: Int(size.height * scale),
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else {
        fatalError("finder-shot: could not allocate the menu bitmap")
    }
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // ponytail: no drop shadow baked in here — a shadow that bleeds past this panel's own
    // bounds would fight "tight cropping," and adding the margin to hold one is a second knob
    // for a marketing nicety. Add one (with matching canvas padding) if the flat edge reads
    // wrong once this is actually laid out on the site.
    NSColor(calibratedWhite: 0.16, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 10, yRadius: 10).fill()

    for (i, row) in rows.enumerated() {
        let h = lineHeights[i]
        let y = total - rowTops[i] - h   // AppKit's bitmap context is bottom-up
        if i == highlight {
            NSColor.controlAccentColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 6, y: y, width: size.width - 12, height: h),
                         xRadius: 4, yRadius: 4).fill()
        }
        var x = leftPad
        row.image?.draw(in: NSRect(x: x, y: y + (h - 18) / 2, width: 18, height: 18))
        x += 18 + imgGap
        (row.title as NSString).draw(at: NSPoint(x: x, y: y + vPad), withAttributes: attrs)
        if row.chevron, let chev = icon("chevron.right", tint: NSColor(white: 1, alpha: 0.55)) {
            let side: CGFloat = 9
            chev.draw(in: NSRect(x: size.width - trailingPad - side, y: y + (h - side) / 2,
                                 width: side, height: side))
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    let image = NSImage(size: size)
    image.addRepresentation(rep)
    return (image, size, rowTops)
}

/// Composites panels side by side into one transparent 2x canvas — the same explicit-bitmap
/// approach as `makePanel`, for the same reason: retina output that does not depend on which
/// screen happens to be attached when this runs.
func compose(_ pieces: [(image: NSImage, origin: NSPoint)], size: NSSize) -> NSImage {
    let scale: CGFloat = 2
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                     pixelsWide: Int(size.width * scale),
                                     pixelsHigh: Int(size.height * scale),
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB,
                                     bytesPerRow: 0, bitsPerPixel: 0) else {
        fatalError("finder-shot: could not allocate the composite bitmap")
    }
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    for piece in pieces {
        piece.image.draw(at: piece.origin, from: .zero, operation: .sourceOver, fraction: 1)
    }
    NSGraphicsContext.restoreGraphicsState()
    let out = NSImage(size: size)
    out.addRepresentation(rep)
    return out
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("finder-shot: could not encode \(path)\n".utf8))
        exit(1)
    }
    try? FileManager.default.createDirectory(
        atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    do {
        try png.write(to: URL(fileURLWithPath: path))
    } catch {
        FileHandle.standardError.write(Data("finder-shot: could not write \(path): \(error)\n".utf8))
        exit(1)
    }
    print("finder-shot: wrote \(path) — \(rep.pixelsWide)x\(rep.pixelsHigh)px")
}

// ── THE ROWS, READ FROM FinderActions.swift ────────────────────────────────────────────────
//
// `ChuteActions.rows()` is the exact call `chute finder-actions --menu` and the shipped
// `ChuteFinderSync.menu(for:)` both make — see FinderActions.swift's own doc comment on why
// there is only the one implementation. Defaults (hasSelection: true, targetIsFolder: true)
// match `chute finder-actions --menu`'s, so this image and that command's output are the same
// menu asked the same question.
//
// `Row` carries a title and a symbol but not the action's `Kind` — the colour lives on
// `ChuteAction`, not `Row`. FinderActions.swift's own invariant ("no two drawn rows share a
// symbol") is what makes the symbol a safe key back to the action that owns it, including for a
// submenu holder row, whose symbol is deliberately its first child's (ChuteFinderSync does the
// same thing when it builds the holder's icon).
func owningAction(bySymbol symbol: String) -> ChuteAction {
    guard let found = ChuteActions.all.first(where: { $0.symbol == symbol }) else {
        fatalError("finder-shot: no ChuteAction owns symbol \(symbol) — " +
                   "FinderActions.swift's one-symbol-per-action invariant broke")
    }
    return found
}

struct MenuRow {
    let title: String
    let symbol: String
    let tint: NSColor
    let children: [ChuteAction]
}

let topRows: [MenuRow] = ChuteActions.rows(hasSelection: true, targetIsFolder: true).map { row in
    let owner = owningAction(bySymbol: row.symbol)
    return MenuRow(title: row.title, symbol: row.symbol, tint: tint(owner.kind),
                   children: row.children.compactMap(ChuteActions.find))
}

// ── OUTPUT PATHS ────────────────────────────────────────────────────────────────────────────

let argv = CommandLine.arguments
let defaultOut = "/Users/sxope/Documents/2026/Development/37.chute/site/public/media/screens/finder-menu.png"
let mainOut = argv.count > 1 ? argv[1] : defaultOut
let ext = (mainOut as NSString).pathExtension.isEmpty ? "png" : (mainOut as NSString).pathExtension
let base = (mainOut as NSString).deletingPathExtension
let submenuOut = base + "-submenu." + ext

// ── THE COLLAPSED MENU ──────────────────────────────────────────────────────────────────────

let mainRows: [PanelRow] = topRows.map {
    PanelRow(title: $0.title, image: icon($0.symbol, tint: $0.tint), chevron: !$0.children.isEmpty)
}
let (mainImage, _, mainRowTops) = makePanel(mainRows, highlight: nil)
savePNG(mainImage, to: mainOut)

// ── THE SAME MENU, ONE SUBMENU OPEN ─────────────────────────────────────────────────────────
//
// "New File" is the row with the most visually distinct children (a pencil, a clipboard, a
// photo, each a different tint) — a better demonstration of the submenu style than "Copy
// Folder Tree", whose three rows share one symbol and one colour. Falls back to the first row
// that has a submenu at all, so this still renders something if that row is ever renamed.
let expandIndex = topRows.firstIndex(where: { $0.title == "New File" })
    ?? topRows.firstIndex(where: { !$0.children.isEmpty })

if let idx = expandIndex {
    let (highlighted, highlightedSize, _) = makePanel(mainRows, highlight: idx)
    let children = topRows[idx].children
    let childRows: [PanelRow] = children.map {
        PanelRow(title: $0.plainTitle, image: icon($0.symbol, tint: tint($0.kind)), chevron: false)
    }
    let (submenuImage, submenuSize, _) = makePanel(childRows, highlight: nil)

    let overlap: CGFloat = 4   // a real macOS submenu abuts its parent, not floats beside it
    let subOriginX = highlightedSize.width - overlap
    // subOriginY is relative to the MAIN panel's own bottom edge (y=0), and can go negative —
    // a submenu opening off the last row hangs below where the main panel ends. The canvas has
    // to stretch to whichever of the two panels reaches lower, then both origins shift up by
    // that amount so nothing is drawn off the bottom of the bitmap.
    let subOriginY = highlightedSize.height - mainRowTops[idx] - submenuSize.height
    let lowestY = min(0, subOriginY)
    let highestY = max(highlightedSize.height, subOriginY + submenuSize.height)
    let canvasSize = NSSize(width: subOriginX + submenuSize.width, height: highestY - lowestY)
    let composite = compose([
        (highlighted, NSPoint(x: 0, y: -lowestY)),
        (submenuImage, NSPoint(x: subOriginX, y: subOriginY - lowestY)),
    ], size: canvasSize)
    savePNG(composite, to: submenuOut)
} else {
    print("finder-shot: no row has a submenu — skipped the expanded shot")
}

#else

// ═══════════════════════════════════════════════════════════════════════════════════════════
// THE BOOTSTRAP — this half runs when this file is compiled ALONE (a bare
// `swift Scripts/finder-shot.swift`, exactly as invoked). It never sees ChuteCore's
// declarations and never needs to: `#if`/`#else` means the renderer above is not even
// type-checked on this pass. Its only job is to recompile this same file together with
// Sources/ChuteCore/*.swift, this time with `-DCHUTE_RENDER` set, and hand off to that binary.
// ═══════════════════════════════════════════════════════════════════════════════════════════

let root = FileManager.default.currentDirectoryPath   // run from the repo root, like every
                                                        // other script in Scripts/
let coreDir = root + "/Sources/ChuteCore"
let fm = FileManager.default

guard let entries = try? fm.contentsOfDirectory(atPath: coreDir) else {
    FileHandle.standardError.write(Data(
        "finder-shot: can't see \(coreDir) — run this from the Chute repo root.\n".utf8))
    exit(1)
}
let coreFiles = entries.filter { $0.hasSuffix(".swift") }.map { coreDir + "/" + $0 }
guard !coreFiles.isEmpty else {
    FileHandle.standardError.write(Data("finder-shot: no .swift files under \(coreDir)\n".utf8))
    exit(1)
}

let selfPath = root + "/Scripts/finder-shot.swift"
let workDir = NSTemporaryDirectory() + "chute-finder-shot-\(UUID().uuidString)"
try? fm.createDirectory(atPath: workDir, withIntermediateDirectories: true)
defer { try? fm.removeItem(atPath: workDir) }

// swiftc requires the file carrying top-level statements to be literally named `main.swift`
// when it is one of several files compiled together — hence the copy, not a direct reference
// to this file's own path.
let mainCopy = workDir + "/main.swift"
do {
    try fm.copyItem(atPath: selfPath, toPath: mainCopy)
} catch {
    FileHandle.standardError.write(Data("finder-shot: couldn't stage \(selfPath): \(error)\n".utf8))
    exit(1)
}

let binPath = workDir + "/finder-shot-bin"
let compile = Process()
compile.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
compile.arguments = coreFiles + [mainCopy, "-DCHUTE_RENDER", "-o", binPath]
do {
    try compile.run()
} catch {
    FileHandle.standardError.write(Data("finder-shot: couldn't launch swiftc: \(error)\n".utf8))
    exit(1)
}
compile.waitUntilExit()
guard compile.terminationStatus == 0 else {
    let msg = "finder-shot: the combined build failed — is FinderActions.swift in step with " +
              "this script's renderer?\n"
    FileHandle.standardError.write(Data(msg.utf8))
    exit(Int32(compile.terminationStatus))
}

let run = Process()
run.executableURL = URL(fileURLWithPath: binPath)
run.arguments = Array(CommandLine.arguments.dropFirst())
do {
    try run.run()
} catch {
    FileHandle.standardError.write(Data("finder-shot: couldn't run the rendered binary: \(error)\n".utf8))
    exit(1)
}
run.waitUntilExit()
exit(run.terminationStatus)

#endif
