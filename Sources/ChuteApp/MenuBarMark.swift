import AppKit

/// THE MENU BAR MARK: the app icon's parachute, redrawn as a template image.
///
/// It was the SF Symbol `arrow.down.to.line` until 2026-09-03 — a generic download arrow, which
/// is the one thing `brand/tokens.json` says the mark must not be, and it shared nothing with the
/// app icon a user had just seen in their Dock.
///
/// A menu bar extra is a TEMPLATE image: alpha only, no colour. macOS fills it black on a light
/// menu bar, white on a dark one, and inverts it while the menu is open. So none of the app
/// icon's drawing carries over — no green canopy, no white crate, no lighting. All that survives
/// is the silhouette, and the silhouette has to do the whole job at 16 points.
///
/// WHAT THE SHAPE HAD TO SOLVE. The first four drafts read as a hot-air balloon, because a
/// balloon IS a dome over a box with short ropes, and at this size a filled canopy sitting close
/// above a filled payload is exactly that. A parachute is the opposite proportion: a wide shallow
/// canopy, a SMALL load, and a long steep drop between them. The numbers below are that budget —
/// canopy ~30% of the height, lines ~50%, load ~20% — and the air between the lines is the cue
/// doing the work, the same lesson the app icon's own 16px slice had to learn.
///
/// Verified the way the app icon was: four unprimed viewers shown the rendered glyph with no
/// context and asked what object it is. 4/4 said "parachute", 0/4 said balloon, lamp or umbrella,
/// two of them said "parachute with cargo box" unprompted. Do not change these numbers without
/// running that again — the shape is one bad proportion away from being a lampshade.
enum MenuBarMark {
    /// 16 tall matches the SF Symbol this replaced (13x16), so the row height does not jump. The
    /// WIDTH is then forced by the 18x17 design grid — 16 * 18/17 — and not by the old symbol's
    /// 13. Picking the old width instead squashes the canopy 18% horizontally, which is a
    /// lampshade; the grid's aspect ratio is load-bearing and has to survive the scale.
    static let size = NSSize(width: 16 * 18.0 / 17.0, height: 16)

    /// Built once. `applyBadge` runs on a two-second timer while the menu is open, and redrawing
    /// a bezier path sixty times a minute to produce identical pixels is free work.
    static let image: NSImage = {
        let img = NSImage(size: size, flipped: false) { _ in draw(in: size); return true }
        img.isTemplate = true
        return img
    }()

    // The grid the shape was designed on. 18 wide, 17 tall, y up from the baseline.
    private static let GRID = NSSize(width: 18, height: 17)
    private static let canopyW: CGFloat = 16      // the canopy is nearly the full width …
    private static let domeH: CGFloat = 5.2
    private static let hemY: CGFloat = 11.8
    private static let loadW: CGFloat = 5.0       // … and the load is under a third of it
    private static let loadTop: CGFloat = 3.4
    private static let loadBottom: CGFloat = 0.8
    private static let cordW: CGFloat = 0.8       // ONE unit. Two makes the lines a filled cone.
    private static let scallops = 4

    private static func draw(in box: NSSize) {
        let ux = box.width / GRID.width, uy = box.height / GRID.height
        func P(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * ux, y: y * uy) }
        NSColor.black.setFill()
        NSColor.black.setStroke()

        let x0 = 9 - canopyW / 2, x1 = 9 + canopyW / 2

        // The canopy: a shallow dome closed by a straight hem. Straight is what separates it from
        // a balloon's envelope, which is closed all the way round.
        let canopy = NSBezierPath()
        canopy.move(to: P(x0, hemY))
        canopy.curve(to: P(9, hemY + domeH),
                     controlPoint1: P(x0, hemY + domeH * 0.95),
                     controlPoint2: P(9 - canopyW * 0.28, hemY + domeH))
        canopy.curve(to: P(x1, hemY),
                     controlPoint1: P(9 + canopyW * 0.28, hemY + domeH),
                     controlPoint2: P(x1, hemY + domeH * 0.95))
        // Cusps bitten up into the hem, so the skirt reads as panelled fabric rather than a rim.
        // They are drawn right-to-left because the path arrives at the right-hand end.
        let span = canopyW / CGFloat(scallops)
        for i in stride(from: scallops - 1, through: 0, by: -1) {
            let a = x0 + CGFloat(i) * span
            canopy.curve(to: P(a, hemY),
                         controlPoint1: P(a + span * 0.72, hemY - 0.9),
                         controlPoint2: P(a + span * 0.28, hemY - 0.9))
        }
        canopy.close()
        canopy.fill()

        // Two risers, from the skirt's ends to the load's shoulders. The long steep drop is the
        // whole difference between this and a basket slung under an envelope.
        let cords = NSBezierPath()
        cords.lineWidth = cordW * min(ux, uy)
        cords.move(to: P(x0 + 0.6, hemY - 0.2)); cords.line(to: P(9 - loadW / 2 + 0.6, loadTop))
        cords.move(to: P(x1 - 0.6, hemY - 0.2)); cords.line(to: P(9 + loadW / 2 - 0.6, loadTop))
        cords.stroke()

        NSBezierPath(rect: NSRect(x: (9 - loadW / 2) * ux, y: loadBottom * uy,
                                  width: loadW * ux,
                                  height: (loadTop - loadBottom) * uy)).fill()
    }
}
