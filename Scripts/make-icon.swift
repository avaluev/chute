// Generates Resources/Chute.icns. Run once (or after changing the mark):
//   swift Scripts/make-icon.swift
// AppKit only — no design tool, no dependency, and the result is committed so a normal build
// never has to render anything.
import AppKit

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // macOS 14+ icon geometry: the artwork sits in a rounded square inset from the canvas, with
    // the corner radius Apple uses for app icons (≈ 22.37% of the square's width).
    let inset = size * 0.0703
    let square = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = square.width * 0.2237
    let squircle = NSBezierPath(roundedRect: square, xRadius: radius, yRadius: radius)

    // Deep slate, lit from the top — Apple's icons are lit from above, never flat.
    NSGradient(colors: [NSColor(calibratedRed: 0.20, green: 0.23, blue: 0.31, alpha: 1),
                        NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.16, alpha: 1),
                        NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.09, alpha: 1)],
               atLocations: [0, 0.55, 1], colorSpace: .deviceRGB)?
        .draw(in: squircle, angle: -90)

    // A hairline of light along the top edge: the thing that makes a flat rectangle read as an
    // object rather than a sticker.
    squircle.addClip()
    let rim = NSBezierPath(roundedRect: square.insetBy(dx: size * 0.004, dy: size * 0.004),
                           xRadius: radius, yRadius: radius)
    rim.lineWidth = size * 0.008
    NSColor(calibratedWhite: 1, alpha: 0.14).setStroke()
    rim.stroke()

    // THE MARK: files funnelled into a lit slot.
    //
    // Not an arrow. Every second utility on the Dock is a green download arrow, and the product is
    // not "download" — it is "take what you have and drop it somewhere that swallows it". Two
    // heavy converging bars form the chute, three file cards fall in, and the slot at the bottom
    // glows because that is where the payload goes.
    //
    // Legibility rule: at 16pt only three shapes survive — two bars and a lit slot. Everything
    // else is detail for the large sizes.
    let green = NSColor(calibratedRed: 0.56, green: 0.86, blue: 0.44, alpha: 1)
    let glow = NSColor(calibratedRed: 0.45, green: 0.98, blue: 0.40, alpha: 1)
    let paper = NSColor(calibratedWhite: 0.97, alpha: 1)

    // SMALL SIZES GET DIFFERENT ARTWORK. At 16 and 32pt the cards turn to mush and the two bars
    // read as a checkmark, so below 64pt the icon is drawn as a hopper: a wide rim, two short
    // walls, one lit slot. Apple ships per-size artwork for exactly this reason.
    if size <= 64 {
        let hopperLip = NSBezierPath()
        hopperLip.lineWidth = size * 0.085
        hopperLip.lineCapStyle = .round
        hopperLip.move(to: NSPoint(x: size * 0.200, y: size * 0.700))
        hopperLip.line(to: NSPoint(x: size * 0.800, y: size * 0.700))
        green.setStroke()
        hopperLip.stroke()

        let walls = NSBezierPath()
        walls.lineWidth = size * 0.085
        walls.lineCapStyle = .round
        walls.move(to: NSPoint(x: size * 0.235, y: size * 0.660))
        walls.line(to: NSPoint(x: size * 0.410, y: size * 0.360))
        walls.move(to: NSPoint(x: size * 0.765, y: size * 0.660))
        walls.line(to: NSPoint(x: size * 0.590, y: size * 0.360))
        walls.stroke()

        ctx.setShadow(offset: .zero, blur: size * 0.10, color: glow.withAlphaComponent(0.9).cgColor)
        let smallSlot = NSBezierPath(roundedRect: NSRect(x: size * 0.355, y: size * 0.250,
                                                         width: size * 0.290, height: size * 0.085),
                                     xRadius: size * 0.042, yRadius: size * 0.042)
        glow.setFill()
        smallSlot.fill()
        ctx.setShadow(offset: .zero, blur: 0, color: nil)

        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    // Three cards, smallest and faintest highest: a stack in motion, not a pile.
    for (i, spec) in [(y: 0.760, w: 0.150, a: 0.38, dx: -0.045),
                      (y: 0.648, w: 0.180, a: 0.68, dx:  0.035),
                      (y: 0.520, w: 0.215, a: 1.00, dx:  0.000)].enumerated() {
        let w = size * spec.w
        let h = w * 0.70
        // Offset left and right, with air between them: three documents falling, not one object.
        let card = NSBezierPath(roundedRect: NSRect(x: (size - w) / 2 + size * spec.dx,
                                                    y: size * spec.y, width: w, height: h),
                                xRadius: size * 0.018, yRadius: size * 0.018)
        paper.withAlphaComponent(spec.a).setFill()
        card.fill()
        // A fold line, so a card reads as a document and not as a blank tile.
        if i == 2 {
            let fold = NSBezierPath()
            fold.lineWidth = size * 0.012
            let x0 = (size - w) / 2 + size * spec.dx
            fold.move(to: NSPoint(x: x0 + w * 0.22, y: size * spec.y + h * 0.42))
            fold.line(to: NSPoint(x: x0 + w * 0.78, y: size * spec.y + h * 0.42))
            NSColor(calibratedWhite: 0.35, alpha: 0.55).setStroke()
            fold.stroke()
        }
    }

    // The chute itself: two heavy bars converging on the slot.
    // A lip across the top of the walls: with it the shape is a hopper you drop things into;
    // without it, two converging strokes are just a checkmark.
    let lip = NSBezierPath()
    lip.lineWidth = size * 0.070
    lip.lineCapStyle = .round
    lip.move(to: NSPoint(x: size * 0.175, y: size * 0.475))
    lip.line(to: NSPoint(x: size * 0.330, y: size * 0.475))
    lip.move(to: NSPoint(x: size * 0.670, y: size * 0.475))
    lip.line(to: NSPoint(x: size * 0.825, y: size * 0.475))
    green.setStroke()
    lip.stroke()

    let chute = NSBezierPath()
    chute.lineWidth = size * 0.082
    chute.lineCapStyle = .round
    chute.move(to: NSPoint(x: size * 0.180, y: size * 0.470))
    chute.line(to: NSPoint(x: size * 0.395, y: size * 0.235))
    chute.move(to: NSPoint(x: size * 0.820, y: size * 0.470))
    chute.line(to: NSPoint(x: size * 0.605, y: size * 0.235))
    green.setStroke()
    chute.stroke()

    // The slot: lit, because it is the point of the whole thing.
    ctx.setShadow(offset: .zero, blur: size * 0.075, color: glow.withAlphaComponent(0.85).cgColor)
    let slot = NSBezierPath(roundedRect: NSRect(x: size * 0.360, y: size * 0.165,
                                                width: size * 0.280, height: size * 0.052),
                            xRadius: size * 0.026, yRadius: size * 0.026)
    glow.setFill()
    slot.fill()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = "Resources/Chute.iconset"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
for (px, name) in [(16, "icon_16x16"), (32, "icon_16x16@2x"), (32, "icon_32x32"),
                   (64, "icon_32x32@2x"), (128, "icon_128x128"), (256, "icon_128x128@2x"),
                   (256, "icon_256x256"), (512, "icon_256x256@2x"), (512, "icon_512x512"),
                   (1024, "icon_512x512@2x")] {
    let data = drawIcon(size: CGFloat(px)).representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
}
print("wrote \(out) — now: iconutil -c icns \(out) -o Resources/Chute.icns")
