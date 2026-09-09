#!/usr/bin/swift
// THE CASE GALLERY — one card per state the menu can be in, for a post or a README.
//
// Composed from site/public/media/screens/cases/*.png, which Scripts/screens.sh renders from the
// SHIPPING BUILD through the real model and the real renderer. Nothing here is redrawn, so the
// gallery cannot drift from the product: regenerate both and it is current.
//
//   ./Scripts/screens.sh --pristine && swift Scripts/marketing-gallery.swift
//
// Each card states the CLAIM the case proves, not a caption of what is visible. A screenshot
// captioned "the menu" says nothing; "312% of one core and 9 GB — the row that explains why the
// machine went slow" is the reason the case exists.
import AppKit

let root = FileManager.default.currentDirectoryPath
let cases = root + "/site/public/media/screens/cases"
let out = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1] : root + "/marketing/media/gallery.png"

let ink  = NSColor(srgbRed: 0.94, green: 0.95, blue: 0.97, alpha: 1)
let dim  = NSColor(srgbRed: 0.52, green: 0.56, blue: 0.63, alpha: 1)
let bg   = NSColor(srgbRed: 0.043, green: 0.051, blue: 0.066, alpha: 1)
let red  = NSColor(srgbRed: 0.98, green: 0.35, blue: 0.31, alpha: 1)
let grn  = NSColor(srgbRed: 0.33, green: 0.84, blue: 0.47, alpha: 1)
let amb  = NSColor(srgbRed: 0.98, green: 0.68, blue: 0.22, alpha: 1)

struct Card { let file: String; let dot: NSColor?; let title: String; let claim: String }
let cards = [
    Card(file: "mixed", dot: red,
         title: "The everyday menu",
         claim: "Seven sessions, four states, one glance. Blocked sits at the top because it is the only one that cannot continue without you."),
    Card(file: "runaway", dot: amb,
         title: "The runaway",
         claim: "312% of one core and 9.0 GB. The row that explains why the machine went slow — and the only one wearing the word runaway."),
    Card(file: "allclear", dot: grn,
         title: "Nothing needs you",
         claim: "Three sessions finished and waiting for a prompt. The state the product is trying to get you to, and it says so in one colour."),
    Card(file: "nohooks", dot: nil,
         title: "Chute cannot see it",
         claim: "An agent that ships no hooks gets a grey ring and an honest sentence. Silence and blindness never render the same."),
    Card(file: "truncation", dot: nil,
         title: "A bad name is harmless",
         claim: "A path keeps its two ends and elides the middle; a name is a word and cuts at the tail. The columns hold either way."),
]

func wrapped(_ s: String, _ f: NSFont, _ c: NSColor, width: CGFloat) -> NSAttributedString {
    let p = NSMutableParagraphStyle(); p.lineSpacing = 5
    return NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: c, .paragraphStyle: p])
}

func load(_ n: String) -> NSImage? { NSImage(contentsOfFile: "\(cases)/\(n).png") }

// Measure first: each shot is a different height, so the grid is computed, never assumed.
let colW: CGFloat = 620, gap: CGFloat = 46, pad: CGFloat = 70
let cols = 3
let rows = Int(ceil(Double(cards.count) / Double(cols)))
// TEXT HEIGHT IS MEASURED, NOT ASSUMED. At a fixed 132 the runaway card's third line spilled out
// of its box and over the screenshot below it — the claim is the part most likely to be edited,
// so the layout has to survive a longer one.
let titleH: CGFloat = 46
func claimHeight(_ c: Card) -> CGFloat {
    ceil(wrapped(c.claim, .systemFont(ofSize: 23), dim, width: colW)
        .boundingRect(with: NSSize(width: colW, height: 400),
                      options: [.usesLineFragmentOrigin]).height) + 16
}
// EACH SHOT IS A DIFFERENT HEIGHT, so a fixed cell leaves the short ones floating in dead space.
// Row height is the tallest card in that row, measured from the images themselves.
let scaled: [CGFloat] = cards.map { c in
    guard let img = load(c.file) else { return 0 }
    return img.size.height * min(colW / img.size.width, 1)
}
var rowH: [CGFloat] = []
for r in 0..<rows {
    let slice = (0..<cols).compactMap { i -> CGFloat? in
        let k = r * cols + i
        return k < scaled.count ? scaled[k] : nil
    }
    let texts = (0..<cols).compactMap { i -> CGFloat? in
        let k = r * cols + i
        return k < cards.count ? claimHeight(cards[k]) : nil
    }
    rowH.append((slice.max() ?? 0) + titleH + (texts.max() ?? 0))
}
let W = pad * 2 + colW * CGFloat(cols) + gap * CGFloat(cols - 1)
let footerH: CGFloat = 70   // the strip at the bottom needs its own space, not a card's
let H = pad * 2 + 150 + footerH + rowH.reduce(0, +) + gap * CGFloat(rows - 1)

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()
bg.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()

NSAttributedString(string: "Chute", attributes: [
    .font: NSFont.systemFont(ofSize: 66, weight: .bold), .foregroundColor: ink])
    .draw(at: NSPoint(x: pad, y: H - 108))
NSAttributedString(string: "Every state the menu can be in — rendered from the shipping build, not redrawn.",
                   attributes: [.font: NSFont.systemFont(ofSize: 30), .foregroundColor: dim])
    .draw(at: NSPoint(x: pad, y: H - 150))

for (i, card) in cards.enumerated() {
    let row = i / cols
    let cx = pad + CGFloat(i % cols) * (colW + gap)
    let above = rowH.prefix(row).reduce(0, +) + gap * CGFloat(row)
    let cellH = rowH[row]
    let thisText = titleH + ((0..<cols).compactMap { j -> CGFloat? in
        let k = row * cols + j
        return k < cards.count ? claimHeight(cards[k]) : nil
    }.max() ?? 0)
    let cy = H - pad - 175 - above - cellH

    // Title, with the state's own dot beside it so the legend is the product's own vocabulary.
    var tx = cx
    if let d = card.dot {
        d.setFill()
        let r = NSRect(x: cx, y: cy + cellH - 30, width: 17, height: 17)
        (card.dot == red ? NSBezierPath(rect: r) : NSBezierPath(ovalIn: r)).fill()
        tx += 30
    }
    NSAttributedString(string: card.title, attributes: [
        .font: NSFont.systemFont(ofSize: 31, weight: .semibold), .foregroundColor: ink])
        .draw(at: NSPoint(x: tx, y: cy + cellH - 36))
    wrapped(card.claim, .systemFont(ofSize: 23), dim, width: colW)
        .draw(with: NSRect(x: cx, y: cy + cellH - thisText + 4, width: colW,
                           height: thisText - titleH),
              options: [.usesLineFragmentOrigin])

    guard let img = load(card.file) else { continue }
    let s = min(colW / img.size.width, 1)
    let w = img.size.width * s, h = img.size.height * s
    let r = NSRect(x: cx, y: cy + cellH - thisText - h, width: w, height: h)
    NSGraphicsContext.current?.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.62)
    sh.shadowBlurRadius = 34; sh.shadowOffset = NSSize(width: 0, height: -12)
    sh.set()
    NSBezierPath(roundedRect: r, xRadius: 13, yRadius: 13).addClip()
    img.draw(in: r)
    NSGraphicsContext.current?.restoreGraphicsState()
    NSColor.white.withAlphaComponent(0.10).setStroke()
    let e = NSBezierPath(roundedRect: r, xRadius: 13, yRadius: 13); e.lineWidth = 1.5; e.stroke()
}

NSAttributedString(string: "free · MIT · no account · no telemetry · no network code at all      github.com/avaluev/chute",
                   attributes: [.font: NSFont.monospacedSystemFont(ofSize: 26, weight: .regular),
                                .foregroundColor: dim])
    .draw(at: NSPoint(x: pad, y: pad - 30))
image.unlockFocus()

if let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
   let png = rep.representation(using: .png, properties: [:]) {
    try? FileManager.default.createDirectory(atPath: (out as NSString).deletingLastPathComponent,
                                             withIntermediateDirectories: true)
    try? png.write(to: URL(fileURLWithPath: out))
    print("gallery: \(out)  \(Int(W))x\(Int(H))")
} else { print("gallery: FAILED"); exit(1) }
