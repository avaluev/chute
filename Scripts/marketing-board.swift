#!/usr/bin/swift
// ONE BOARD, FIVE SCREENS — the image that goes under a LinkedIn post.
//
// Composed from site/public/media/screens/*.png, which Scripts/screens.sh renders from the
// SHIPPING BUILD. Nothing here is redrawn by hand, so the board cannot drift from the product
// the way a hand-made marketing asset always eventually does: regenerate both and it is current.
//
//   swift Scripts/marketing-board.swift [outPath]
//
// Sized 2400x1350 (16:9). LinkedIn re-encodes anything larger and the text goes soft.
import AppKit

let root = FileManager.default.currentDirectoryPath
let screens = root + "/site/public/media/screens"
let out = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1] : root + "/marketing/media/board.png"

let W: CGFloat = 2400, H: CGFloat = 1500
let bg   = NSColor(srgbRed: 0.055, green: 0.063, blue: 0.078, alpha: 1)
let ink  = NSColor(srgbRed: 0.93,  green: 0.94,  blue: 0.96,  alpha: 1)
let dim  = NSColor(srgbRed: 0.55,  green: 0.58,  blue: 0.64,  alpha: 1)
let acc  = NSColor(srgbRed: 0.38,  green: 0.85,  blue: 0.52,  alpha: 1)

func load(_ n: String) -> NSImage? { NSImage(contentsOfFile: "\(screens)/\(n).png") }

/// A screenshot with a soft shadow and a hairline, scaled to fit `box` without distortion.
///
/// `keepTop` draws only the top fraction of the source. The Settings tab is 1336px tall and its
/// content stops around 800 — pasted whole it renders as a postage stamp with half of it empty,
/// which is how a "collection of screens" ends up illegible. Cropping dead space is what buys
/// the remaining screens enough scale to actually be read at LinkedIn's display size.
func card(_ img: NSImage, in box: NSRect, label: String, note: String, keepTop: CGFloat = 1) {
    let srcH = img.size.height * keepTop
    let src = NSRect(x: 0, y: img.size.height - srcH, width: img.size.width, height: srcH)
    let s = min(box.width / src.width, box.height / srcH)
    let w = src.width * s, h = srcH * s
    let r = NSRect(x: box.minX, y: box.maxY - h, width: w, height: h)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.6)
    shadow.shadowBlurRadius = 30
    shadow.shadowOffset = NSSize(width: 0, height: -10)
    shadow.set()
    NSBezierPath(roundedRect: r, xRadius: 12, yRadius: 12).addClip()
    img.draw(in: r, from: src, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.current?.restoreGraphicsState()

    NSColor.white.withAlphaComponent(0.11).setStroke()
    let edge = NSBezierPath(roundedRect: r, xRadius: 12, yRadius: 12)
    edge.lineWidth = 1.5
    edge.stroke()

    let title = NSMutableAttributedString(string: label, attributes: [
        .font: NSFont.systemFont(ofSize: 30, weight: .semibold), .foregroundColor: ink])
    title.append(NSAttributedString(string: "   " + note, attributes: [
        .font: NSFont.systemFont(ofSize: 28, weight: .regular), .foregroundColor: dim]))
    title.draw(at: NSPoint(x: box.minX, y: box.maxY + 20))
}

/// The strip along the bottom: what to type, and where the code is. A screenshot board that
/// shows a thing without saying how to get it wastes the click it just earned.
func strip(_ rows: [(String, String)], at origin: NSPoint, width: CGFloat) {
    var y = origin.y
    for (head, cmd) in rows.reversed() {
        NSAttributedString(string: cmd, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 27, weight: .regular),
            .foregroundColor: ink]).draw(at: NSPoint(x: origin.x + 250, y: y))
        NSAttributedString(string: head, attributes: [
            .font: NSFont.systemFont(ofSize: 27, weight: .medium),
            .foregroundColor: dim]).draw(at: NSPoint(x: origin.x, y: y))
        y += 46
    }
}

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
bg.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()

// ── Masthead ────────────────────────────────────────────────────────────────────────────────
NSAttributedString(string: "Chute", attributes: [
    .font: NSFont.systemFont(ofSize: 62, weight: .bold), .foregroundColor: ink])
    .draw(at: NSPoint(x: 80, y: H - 118))
NSAttributedString(string: "Nine terminal tabs. Six agents running. Which one is waiting for you?",
                   attributes: [.font: NSFont.systemFont(ofSize: 30, weight: .regular),
                                .foregroundColor: dim])
    .draw(at: NSPoint(x: 80, y: H - 166))

let facts = "free  ·  MIT  ·  no account  ·  no telemetry  ·  no network code at all"
let factsAttr = NSAttributedString(string: facts, attributes: [
    .font: NSFont.monospacedSystemFont(ofSize: 26, weight: .medium), .foregroundColor: acc])
factsAttr.draw(at: NSPoint(x: W - 80 - factsAttr.size().width, y: H - 112))
let repoAttr = NSAttributedString(string: "github.com/avaluev/chute", attributes: [
    .font: NSFont.monospacedSystemFont(ofSize: 26, weight: .regular), .foregroundColor: dim])
repoAttr.draw(at: NSPoint(x: W - 80 - repoAttr.size().width, y: H - 160))

// ── The screens ─────────────────────────────────────────────────────────────────────────────
// The menu is the hero and gets the left half. `setup` is deliberately NOT on this board: on a
// correctly-configured machine it says "Chute is set up correctly" and a screenshot of a screen
// with nothing to report earns none of the space it costs.
if let m = load("menu") {
    card(m, in: NSRect(x: 70, y: 300, width: 980, height: 920),
         label: "The menu bar", note: "every session, one glance")
}
if let a = load("about") {
    card(a, in: NSRect(x: 1120, y: 300, width: 620, height: 920),
         label: "About", note: "why it exists, and one ask")
}
if let s = load("settings") {
    // Top 62% only — everything below it is empty window.
    card(s, in: NSRect(x: 1810, y: 300, width: 520, height: 920),
         label: "Settings", note: "where Chute is", keepTop: 0.62)
}

// ── How to get it ───────────────────────────────────────────────────────────────────────────
NSColor.white.withAlphaComponent(0.08).setFill()
NSRect(x: 70, y: 250, width: W - 140, height: 1).fill()
strip([("App",        "github.com/avaluev/chute/releases/latest"),
       ("CLI",        "brew install avaluev/tap/chute"),
       ("From source","git clone github.com/avaluev/chute && ./Scripts/install.sh"),
       ("Check it",   "chute doctor")],
      at: NSPoint(x: 70, y: 80), width: W - 140)

image.unlockFocus()

if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? FileManager.default.createDirectory(
        atPath: (out as NSString).deletingLastPathComponent,
        withIntermediateDirectories: true)
    try? png.write(to: URL(fileURLWithPath: out))
    print("board: \(out)  \(Int(W))x\(Int(H))")
} else {
    print("board: FAILED to encode"); exit(1)
}
