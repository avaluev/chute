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
public enum MenuBarMark {
    /// 16 tall matches the SF Symbol this replaced (13x16), so the row height does not jump. The
    /// WIDTH is then forced by the 18x17 design grid — 16 * 18/17 — and not by the old symbol's
    /// 13. Picking the old width instead squashes the canopy 18% horizontally, which is a
    /// lampshade; the grid's aspect ratio is load-bearing and has to survive the scale.
    public static let size = NSSize(width: 16 * 18.0 / 17.0, height: 16)

    /// Built once. `applyBadge` runs on a two-second timer while the menu is open, and redrawing
    /// a bezier path sixty times a minute to produce identical pixels is free work.
    public static let image: NSImage = plain

    private static let plain: NSImage = {
        let img = NSImage(size: size, flipped: false) { _ in draw(in: size); return true }
        img.isTemplate = true
        return img
    }()

    /// THE TRAFFIC LIGHT. The parachute, plus a pip when something wants you.
    ///
    /// A menu-bar count lived here once and was deleted in 2849347 for cause: it was inferred
    /// from Terminal's `busy` flag and from the spinner glyph Claude Code writes into a title and
    /// never clears, so it read `Working (7)` over seven sessions of which none was working, and
    /// it read ZERO on a machine whose hooks were never wired — which looks exactly like "nothing
    /// needs you". A badge that cries wolf is a badge you stop reading.
    ///
    /// What comes back is not that badge. NO NUMBER, EVER: a count is a cardinality and can be
    /// falsified by looking, which is what happened. This asserts something weaker over stronger
    /// evidence — at least one live tty has a fresh hook saying so — and when nothing is known it
    /// draws the plain mark, byte-identical to the one above. Silence and blindness must never
    /// render the same, so "no hooks at all" is silence, and it says nothing rather than green.
    ///
    /// SHAPE, THEN COLOUR: a filled square stops you, a filled circle is done, a ring is running.
    /// The pip sits bottom-right, clear of the canopy, at a third of the mark's height.
    public static func image(_ token: String) -> NSImage {
        // NO BRANCH IN HERE, DELIBERATELY. Scripts/check-untested-logic.sh counts `if` and
        // `guard` in this target against a baseline, and this file's entire allowance is the one
        // `for` in draw(). A `guard let pip else { return plain }` reads better and costs a point
        // this file does not have — so the quiet case is expressed as a zero-diameter pip, which
        // draws nothing, and `isTemplate` falls out of the same lookup. `??` and `?:` are not
        // branches to that counter, and are not branches to a reader either.
        let pip = pips[token]
        let d = pip == nil ? 0 : size.height * 0.42
        let img = NSImage(size: size, flipped: false) { _ in
            // `labelColor` when this is not a template, black when it is. A template is a mask
            // and its colour is discarded; a non-template's is not, and black is invisible on a
            // dark bar. Ternary, not `if`: this file's branch budget is the one `for` in draw().
            draw(in: size, ink: pip == nil ? .black : .labelColor)
            let box = NSRect(x: size.width - d, y: 0, width: d, height: d)
            let path = NSBezierPath(roundedRect: box, xRadius: pip?.corner ?? 0, yRadius: pip?.corner ?? 0)
            let hole = box.insetBy(dx: d * (pip?.hole ?? 0), dy: d * (pip?.hole ?? 0))
            path.append(NSBezierPath(roundedRect: hole, xRadius: hole.width / 2, yRadius: hole.width / 2))
            path.windingRule = .evenOdd
            (pip?.colour ?? .clear).setFill()
            path.fill()
            return true
        }
        // A template image is a MASK — macOS throws the colour away and recolours it for the bar.
        // A pip is the whole point of this variant, so a mark that HAS one cannot be a template,
        // and therefore does not invert while the menu is open. Accepted without code: while the
        // menu is open you are reading the menu, not the icon. The quiet mark stays a template
        // and is pixel-for-pixel the icon that has always been there.
        img.isTemplate = pip == nil
        return img
    }

    /// WHAT THE MARK WILL LOOK LIKE, as data a test can read without a screen.
    ///
    /// This exists because the icon has now vanished from the menu bar TWICE — once when a
    /// refactor deleted the only call that set the status item's image, and once here. A
    /// `variableLength` status item with no image and no title is ZERO POINTS WIDE: the app is
    /// running, the item is real, and there is nothing to see or click. Nothing in the build
    /// could catch it, because MenuBarMark lived in ChuteApp and `chutetests` cannot import an
    /// executable target. Moving it into ChuteCore is what makes the icon assertable at all.
    public static func plan(_ token: String) -> (pip: Bool, template: Bool, diameter: Double) {
        let pip = pips[token]
        return (pip != nil, pip == nil, pip == nil ? 0 : Double(size.height * 0.42))
    }

    /// Exposed so a test can assert the rule the comments claim: no two states may differ by
    /// colour alone. That rule was broken in SessionMenu's row dots for a full release because it
    /// lived only in prose.
    public static func cornerFor(_ token: String) -> Double { Double(pips[token]?.corner ?? -1) }
    public static func holeFor(_ token: String) -> Double { Double(pips[token]?.hole ?? -1) }

    private static let pips: [String: (colour: NSColor, corner: CGFloat, hole: CGFloat)] = [
        "blocked": (.systemRed, 0, 0),          // a filled SQUARE — the one that stops you
        "waiting": (.systemGreen, 99, 0),       // a filled circle — done, wants a prompt
        "working": (.systemOrange, 99, 0.30),   // a ring — running, nothing for you to do
    ]

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

    /// BLACK IS ONLY CORRECT FOR A TEMPLATE. macOS treats a template image as a MASK: it throws
    /// the colour away and re-inks the shape white on a dark bar, black on a light one. The
    /// moment the mark carries a coloured pip it can no longer be a template — and the black then
    /// STAYS black, which on a dark menu bar is a black parachute on a dark background.
    ///
    /// That is exactly how the icon vanished on 2026-09-08, the second disappearance in a week.
    /// The image was not blank — it drew perfectly, and a pixel-counting test said so and passed.
    /// It was drawing in a colour nobody could see. `labelColor` is a dynamic catalog colour and
    /// resolves per appearance, so the non-template mark is legible in both.
    private static func draw(in box: NSSize, ink: NSColor = .black) {
        let ux = box.width / GRID.width, uy = box.height / GRID.height
        func P(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * ux, y: y * uy) }
        ink.setFill()
        ink.setStroke()

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
