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

    let inset = size * 0.06
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    NSGradient(starting: NSColor(calibratedRed: 0.16, green: 0.19, blue: 0.26, alpha: 1),
               ending:   NSColor(calibratedRed: 0.07, green: 0.09, blue: 0.13, alpha: 1))?
        .draw(in: squircle, angle: -90)

    // The mark: a chute — two rails narrowing into an arrow, the thing the product does.
    let green = NSColor(calibratedRed: 0.60, green: 0.76, blue: 0.47, alpha: 1)
    green.setStroke()
    let rails = NSBezierPath()
    rails.lineWidth = size * 0.055
    rails.lineCapStyle = .round
    rails.move(to: NSPoint(x: size * 0.28, y: size * 0.74))
    rails.line(to: NSPoint(x: size * 0.44, y: size * 0.42))
    rails.move(to: NSPoint(x: size * 0.72, y: size * 0.74))
    rails.line(to: NSPoint(x: size * 0.56, y: size * 0.42))
    rails.stroke()

    let arrow = NSBezierPath()
    arrow.lineWidth = size * 0.055
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: size * 0.50, y: size * 0.42))
    arrow.line(to: NSPoint(x: size * 0.50, y: size * 0.20))
    arrow.move(to: NSPoint(x: size * 0.38, y: size * 0.30))
    arrow.line(to: NSPoint(x: size * 0.50, y: size * 0.18))
    arrow.line(to: NSPoint(x: size * 0.62, y: size * 0.30))
    arrow.stroke()

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
