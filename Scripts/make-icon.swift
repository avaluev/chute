// Chute app icon — THE PARACHUTE. A canopy under drift, four taut risers, and a crate of the
// user's work riding down under it. "Drop context into your agent."
//
//   swift Scripts/make-icon.swift [outdir]     (macOS 14+, AppKit only, Command Line Tools only)
//
// outdir defaults to Resources/Chute.iconset, relative to the current directory. Every size is
// drawn at its NATIVE pixel size by the same code — nothing is ever downscaled from 1024.
import AppKit

// ── Palette ───────────────────────────────────────────────────────────────────────
// Transcribed by hand from brand/tokens.json, the one place Chute's colours are declared. No JSON
// parser, because this has to run as a single `swift make-icon.swift`. Every green below is a
// shading stop derived from accent/accentGlow — no new hue enters the icon.
@inline(__always) func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(deviceRed: r, green: g, blue: b, alpha: a)
}
let ground900  = rgba(0.051, 0.059, 0.090)   // #0D0F17
let ground800  = rgba(0.090, 0.110, 0.161)   // #171C29
let ground600  = rgba(0.200, 0.231, 0.310)   // #333B4F
let accent     = rgba(0.561, 0.859, 0.439)   // #8FDB70
let accentGlow = rgba(0.451, 0.980, 0.400)   // #73FA66
let paper      = rgba(0.969, 0.969, 0.969)   // #F7F7F7
let white      = rgba(1, 1, 1)

func mix(_ x: NSColor, _ y: NSColor, _ t: CGFloat) -> NSColor {
    rgba(x.redComponent   + (y.redComponent   - x.redComponent)   * t,
         x.greenComponent + (y.greenComponent - x.greenComponent) * t,
         x.blueComponent  + (y.blueComponent  - x.blueComponent)  * t)
}
func shade(_ c: NSColor, _ m: CGFloat) -> NSColor {
    rgba(min(1, c.redComponent * m), min(1, c.greenComponent * m), min(1, c.blueComponent * m))
}
func black(_ a: CGFloat) -> NSColor { rgba(0, 0, 0, a) }

// The crown sits BETWEEN the two brand greens, not on accentGlow alone: accentGlow is 12° cooler
// than accent, and letting it own the lit half dragged the whole canopy off the accent token.
let goreLit   = mix(mix(accentGlow, accent, 0.50), white, 0.12)   // the crown, dead under the light
let goreEdge  = shade(accent, 0.52)               // fabric turning away at the silhouette
let seamDark  = shade(accent, 0.30)               // the stitched seam between two gores
let skirtEdge = shade(accent, 0.40)               // the reinforced hem tape
let cordLit   = mix(accent, paper, 0.30)
let cordDark  = mix(accent, ground800, 0.34)

// The crate. A box has three faces under one light, and the tonal STEP between them is what makes
// it an object — a flat rounded rect with a printed seam read as a credit card. The key is up and
// to the left, so: lid brightest, front a clear step down, right flank turned out of the light.
let crateTop   = white                            // 255 — the lid, square into the key
let crateTopLo = mix(paper, white, 0.50)          // 250 — its far corner
let crateFaceT = mix(paper, ground600, 0.06)      // 236 — the front face starts a visible step down
let crateFaceB = mix(paper, ground600, 0.40)      // 168 — and falls to the floor
let crateSideT = mix(paper, ground600, 0.46)      // 156 — the right flank, out of the light …
let crateSideB = mix(paper, ground600, 0.66)      // 120 — … and darker still at its foot
let crateFloor = mix(paper, ground600, 0.24)      // the small crate's one shaded floor row

// ── Helpers ───────────────────────────────────────────────────────────────────────
func grad(_ s: [(NSColor, CGFloat)]) -> NSGradient {
    NSGradient(colors: s.map { $0.0 }, atLocations: s.map { $0.1 }, colorSpace: .deviceRGB)!
}
func rect(_ r: NSRect) -> NSBezierPath { NSBezierPath(rect: r) }
func poly(_ pts: [NSPoint]) -> NSBezierPath {
    let p = NSBezierPath(); p.move(to: pts[0])
    for q in pts.dropFirst() { p.line(to: q) }
    p.close(); return p
}
func layer(_ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState(); draw(); NSGraphicsContext.restoreGraphicsState()
}
func noShadow(_ ctx: CGContext) { ctx.setShadow(offset: .zero, blur: 0, color: nil) }
func bitmap(_ n: Int) -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: n, pixelsHigh: n, bitsPerSample: 8,
                     samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
}

// ── A CONTINUOUS corner (the iOS/macOS squircle), not NSBezierPath(roundedRect:) ───
// The published construction: the curve leaves the straight edge 1.5287r from the corner and
// arrives through three cubics, so curvature never jumps. A circular corner is visible at 1024.
func squircle(_ r: NSRect, _ radius: CGFloat) -> NSBezierPath {
    let rr = min(radius, min(r.width, r.height) / 3.0574)
    let a = 1.52866498*rr, b = 1.08849296*rr, c = 0.86840694*rr, d = 0.63149379*rr
    let e = 0.37282383*rr, f = 0.16905956*rr, g = 0.07491138*rr
    let (x0, y0, x1, y1) = (r.minX, r.minY, r.maxX, r.maxY); let p = NSBezierPath()
    func L(_ x: CGFloat, _ y: CGFloat) { p.line(to: NSPoint(x: x, y: y)) }
    func C(_ x: CGFloat, _ y: CGFloat, _ ax: CGFloat, _ ay: CGFloat, _ bx: CGFloat, _ by: CGFloat) {
        p.curve(to: NSPoint(x: x, y: y), controlPoint1: NSPoint(x: ax, y: ay),
                controlPoint2: NSPoint(x: bx, y: by))
    }
    p.move(to: NSPoint(x: x0 + a, y: y1)); L(x1 - a, y1)
    C(x1-d, y1-g, x1-b, y1, x1-c, y1); C(x1-g, y1-d, x1-e, y1-f, x1-f, y1-e); C(x1, y1-a, x1, y1-c, x1, y1-b)
    L(x1, y0 + a)
    C(x1-g, y0+d, x1, y0+b, x1, y0+c); C(x1-d, y0+g, x1-f, y0+e, x1-e, y0+f); C(x1-a, y0, x1-c, y0, x1-b, y0)
    L(x0 + a, y0)
    C(x0+d, y0+g, x0+b, y0, x0+c, y0); C(x0+g, y0+d, x0+e, y0+f, x0+f, y0+e); C(x0, y0+a, x0, y0+c, x0, y0+b)
    L(x0, y1 - a)
    C(x0+g, y1-d, x0, y1-b, x0, y1-c); C(x0+d, y1-g, x0+f, y1-e, x0+e, y1-f); C(x0+a, y1, x0+c, y1, x0+b, y1)
    p.close(); return p
}

// ── The tile ──────────────────────────────────────────────────────────────────────
// The cast shadow is FITTED, PER SIZE, against the macOS system icons. Apple's shadow is not one
// fraction scaled down the range: at 1024 it dies 34px below the body (4% of it), at 32 it dies
// at 3px (11%), and at 16 it is not a drop shadow at all but a flat 38-alpha halo on all four
// sides. Those three regimes are why an earlier round read as "a glow with no edge" at 16/32.
//
// Each row below was found by grid search against Notes.app rendered through
// NSWorkspace.icon(forFile:) at that exact size — the render whose 1024 body bbox is x[100…923].
// Verified identical on Calendar, Mail, Maps, Music and Reminders.
//   size: (dy px, blur px, alpha)      Notes' below/left/above alpha 1px outside the body
let SHADOW: [Int: (CGFloat, CGFloat, CGFloat)] = [
      16: (0.00,  1.30, 0.50),   // 38 / 38 / 38   — a halo, dead symmetric
      32: (0.52,  1.03, 0.30),   // 53 / 24 /  6
      64: (1.51,  1.05, 0.30),   // 71 / 24 /  1
     128: (1.54,  2.09, 0.30),   // 64 / 29 /  4
     256: (2.67,  5.16, 0.30),   // 61 / 34 /  9
     512: (5.11, 10.31, 0.30),
    1024: (9.88, 20.63, 0.30),   // 64 / 37 / 11
]

let bodyGrad = grad([(mix(ground600, white, 0.06), 0), (ground800, 0.52), (ground900, 1)])

@discardableResult
func drawTile(_ ctx: CGContext, _ body: NSRect, _ canvas: Int, hairline: Bool) -> NSBezierPath {
    let S = body.width
    let path = squircle(body, S * 0.225)                     // Apple's 22.5% of the body
    let (dy, blur, alpha) = SHADOW[canvas] ?? (S * 0.0120, S * 0.0250, 0.30)
    layer {
        ctx.setShadow(offset: CGSize(width: 0, height: -dy), blur: blur,
                      color: rgba(0, 0, 0.02, alpha).cgColor)
        ground900.setFill(); path.fill()
    }
    bodyGrad.draw(in: path, angle: -90)
    // The hairline along the lit edge is the difference between an object and a sticker. Below
    // 64px it would be a grey halo on a 28px square, so it is dropped there.
    guard hairline else { return path }
    let rim = squircle(body.insetBy(dx: S * 0.005, dy: S * 0.005), S * 0.221)
    layer {
        ctx.addPath(rim.cgPath.copy(strokingWithWidth: max(S * 0.007, 0.7), lineCap: .round,
                                    lineJoin: .round, miterLimit: 10))
        ctx.clip()
        grad([(rgba(1, 1, 1, 0.22), 0), (rgba(1, 1, 1, 0.08), 0.42), (rgba(1, 1, 1, 0.03), 1)])
            .draw(in: rect(body), angle: -90)
    }
    return path
}

// ── The mark, full detail (64px and up) ───────────────────────────────────────────
// Geometry as fractions of the body square, so the 64 is the same drawing as the 1024.
let APEX_Y: CGFloat   = 0.910     // crown of the canopy
let RX: CGFloat       = 0.380     // canopy half-width
let HEM_Y: CGFloat    = 0.578     // skirt height at the centre gore …
let HEM_LIFT: CGFloat = 0.052     // … and how much the outer cusps ride up
let CRATE_W: CGFloat  = 0.320     // the whole box, silhouette included …
let CRATE_H: CGFloat  = 0.250
let CRATE_Y: CGFloat  = 0.100
let DEPTH_X: CGFloat  = 0.070     // … of which this much is the box turning away to the right …
let DEPTH_Y: CGFloat  = 0.052     // … and this much is the lid we are looking down onto.
let TILT: CGFloat     = -5.0      // degrees, clockwise: canopy leans into the drift, crate trails
let kappa: CGFloat    = 0.5523    // a circle/ellipse quarter as one cubic

func drawFull(_ ctx: CGContext, _ body: NSRect, _ canvas: Int) {
    let S = body.width
    func X(_ f: CGFloat) -> CGFloat { body.minX + f * S }
    func Y(_ f: CGFloat) -> CGFloat { body.minY + f * S }
    func u(_ f: CGFloat) -> CGFloat { f * S }
    func P(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: y) }

    let tile = drawTile(ctx, body, canvas, hairline: true)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    // Descent: the whole rig rotates a few degrees about its own centroid, so the canopy leans
    // into the drift and the crate trails behind it. Perfect symmetry is what made it read parked.
    ctx.translateBy(x: X(0.5), y: Y(0.5))
    ctx.rotate(by: TILT * .pi / 180)
    ctx.translateBy(x: -X(0.5), y: -Y(0.5))

    // Canopy. Its seams are longitudes, and a longitude on a dome projects to a quarter-ellipse —
    // horizontal tangent at the apex, vertical at the hem. That is the whole trick that makes it
    // a curved surface rather than a green semicircle.
    let apex = NSPoint(x: X(0.5), y: Y(APEX_Y))
    let spread: [CGFloat] = [-1, -0.7045, -0.2545, 0.2545, 0.7045, 1]
    let cusps = spread.map { NSPoint(x: X(0.5 + RX * $0), y: Y(HEM_Y + HEM_LIFT * $0 * $0)) }

    func seamDown(_ p: NSBezierPath, to c: NSPoint) {
        p.curve(to: c, controlPoint1: NSPoint(x: apex.x + kappa * (c.x - apex.x), y: apex.y),
                controlPoint2: NSPoint(x: c.x, y: c.y + kappa * (apex.y - c.y)))
    }
    func seamUp(_ p: NSBezierPath, from c: NSPoint) {
        p.curve(to: apex, controlPoint1: NSPoint(x: c.x, y: c.y + kappa * (apex.y - c.y)),
                controlPoint2: NSPoint(x: apex.x + kappa * (c.x - apex.x), y: apex.y))
    }
    // The hem sags between the cusps. The scallops are what say parachute and not mushroom.
    func scallop(_ p: NSBezierPath, from a: NSPoint, to b: NSPoint) {
        let span = b.x - a.x, sag = 0.30 * abs(span)
        p.curve(to: b, controlPoint1: NSPoint(x: a.x + 0.26 * span, y: a.y - sag),
                controlPoint2: NSPoint(x: b.x - 0.26 * span, y: b.y - sag))
    }
    let hem = NSBezierPath()          // the skirt alone, for the hem tape
    hem.move(to: cusps[5])
    for i in stride(from: 5, to: 0, by: -1) { scallop(hem, from: cusps[i], to: cusps[i - 1]) }

    // Base silhouette first: the gores are painted over it, so an anti-aliased seam can never open
    // a hairline of slate between two panels.
    let canopy = NSBezierPath()
    canopy.move(to: cusps[0]); seamUp(canopy, from: cusps[0]); seamDown(canopy, to: cusps[5])
    canopy.append(hem); canopy.close()
    mix(goreEdge, goreLit, 0.55).setFill(); canopy.fill()

    // Gores. Each is shaded by how far it faces away from the viewer AND by which side of the
    // light it is on — the source sits up and to the LEFT, so the left flank of a canopy leaning
    // right catches it. That asymmetry is the difference between falling and parked.
    // The floor of the vertical falloff is held high (0.78, not 0.60) so the canopy's mass stays
    // on the accent token instead of sliding a hue cooler and two stops darker than #8FDB70.
    for i in 0..<5 {
        let gore = NSBezierPath()
        gore.move(to: apex); seamDown(gore, to: cusps[i])
        scallop(gore, from: cusps[i], to: cusps[i + 1])
        seamUp(gore, from: cusps[i + 1]); gore.close()
        let mid = (spread[i] + spread[i + 1]) / 2
        let facing = sqrt(max(0, 1 - mid * mid))          // 1 dead ahead → 0 at the silhouette
        let lit = max(0, min(1, 0.36 + 0.58 * facing - 0.17 * mid))
        let top = mix(goreEdge, goreLit, lit)
        grad([(top, 0), (shade(top, 0.94), 0.42), (shade(top, 0.78), 1)]).draw(in: gore, angle: -90)
    }

    // Seams: a stitched dark line with a lit ridge on its left shoulder. Fabricated, not soft.
    layer {
        canopy.addClip()
        let ridge = NSBezierPath(), stitch = NSBezierPath()
        for i in 1...4 {
            stitch.move(to: apex); seamDown(stitch, to: cusps[i])
            ridge.move(to: NSPoint(x: apex.x - u(0.006), y: apex.y))
            ridge.curve(to: NSPoint(x: cusps[i].x - u(0.006), y: cusps[i].y),
                        controlPoint1: NSPoint(x: apex.x - u(0.006) + kappa * (cusps[i].x - apex.x), y: apex.y),
                        controlPoint2: NSPoint(x: cusps[i].x - u(0.006), y: cusps[i].y + kappa * (apex.y - cusps[i].y)))
        }
        ridge.lineWidth = max(0.6, u(0.005))
        mix(goreLit, white, 0.35).withAlphaComponent(0.32).setStroke(); ridge.stroke()
        stitch.lineWidth = max(0.7, u(0.0055))
        seamDark.withAlphaComponent(0.72).setStroke(); stitch.stroke()
    }
    // The hem tape: a defined skirt edge, stroked at double width inside the canopy's own clip so
    // exactly half of it lands — a hard band on the inside, the silhouette untouched.
    layer {
        canopy.addClip()
        hem.lineWidth = max(1, u(0.017))
        skirtEdge.setStroke(); hem.stroke()
        // and a lit lip along the very edge of the tape
        hem.lineWidth = max(0.6, u(0.005))
        mix(accent, white, 0.30).withAlphaComponent(0.55).setStroke(); hem.stroke()
    }
    // Specular rim along the crown, clipped so only the inner half shows.
    layer {
        canopy.addClip()
        let crown = NSBezierPath()
        crown.move(to: cusps[0]); seamUp(crown, from: cusps[0]); seamDown(crown, to: cusps[5])
        crown.lineWidth = max(1, u(0.020))
        mix(accentGlow, white, 0.60).withAlphaComponent(0.50).setStroke(); crown.stroke()
    }

    // ── The crate ────────────────────────────────────────────────────────────────
    // Three faces of one box, so the whole thing occupies exactly the CRATE_W × CRATE_H it always
    // did: the front face gives up DEPTH_X to the right flank and DEPTH_Y to the lid.
    let fx0 = X(0.5 - CRATE_W / 2),  fx1 = fx0 + u(CRATE_W - DEPTH_X)
    let fy0 = Y(CRATE_Y),            fy1 = fy0 + u(CRATE_H - DEPTH_Y)
    let dx = u(DEPTH_X), dy = u(DEPTH_Y)
    let LF = P(fx0, fy1), RF = P(fx1, fy1)                       // front-top edge of the lid
    let LB = P(fx0 + dx, fy1 + dy), RB = P(fx1 + dx, fy1 + dy)   // and its back edge
    // The risers converge on the middle of each end of the LID — clear of every corner, and the
    // one place on the box where "hanging from" is unambiguous.
    let anchorL = P(fx0 + dx / 2, fy1 + dy / 2)
    let anchorR = P(fx1 + dx / 2, fy1 + dy / 2)

    // Risers: dead straight lines under tension, brighter where they leave the lit skirt.
    //
    // Both ends are BURIED, and that is the entire fix for the round-2 blocker. A riser that stops
    // exactly on the crate's outline lands on whatever the outline is doing there — under a 5°
    // tilt and a rounded corner that was open background, and the tips floated 7-13px clear of the
    // box at 1024. So each riser now starts a little INSIDE the canopy and ends a long way INSIDE
    // the crate, and the crate is painted over it afterwards. Contact is then a property of the
    // geometry, not of a tangency that has to be got right to the pixel.
    var top = -CGFloat.infinity, bot = CGFloat.infinity
    let cords = NSBezierPath()
    for (c, a) in [(cusps[0], anchorL), (cusps[1], anchorL), (cusps[4], anchorR), (cusps[5], anchorR)] {
        let s = P(c.x + (c.x < a.x ? u(0.010) : -u(0.010)), c.y + u(0.014))
        let e = P(a.x + (a.x - s.x) * 0.45, a.y + (a.y - s.y) * 0.45)
        cords.move(to: s); cords.line(to: e)
        top = max(top, s.y); bot = min(bot, e.y)
    }
    layer {
        ctx.addPath(cords.cgPath.copy(strokingWithWidth: max(1.25, u(0.0105)), lineCap: .butt,
                                      lineJoin: .miter, miterLimit: 10))
        ctx.clip()
        // The gradient is vertical, so only its VERTICAL extent carries colour — but its
        // horizontal extent still decides what gets painted at all. It must span the whole rig,
        // rotation included. Pinning it to the crate's own box is what severed the risers before.
        // The dark stop lands at 0.66, which is where the lid swallows them.
        grad([(cordLit, 0), (mix(cordLit, cordDark, 0.55), 0.35), (cordDark, 0.66), (cordDark, 1)])
            .draw(in: rect(NSRect(x: X(-0.5), y: bot, width: u(2.0), height: top - bot)), angle: -90)
    }

    let front = NSRect(x: fx0, y: fy0, width: fx1 - fx0, height: fy1 - fy0)
    let box = poly([P(fx0, fy0), P(fx1, fy0), P(fx1 + dx, fy0 + dy), RB, LB, LF])
    layer {
        ctx.setShadow(offset: CGSize(width: 0, height: -u(0.012)), blur: u(0.026),
                      color: black(0.45).cgColor)
        black(1).setFill(); box.fill()
    }
    noShadow(ctx)
    layer {
        box.addClip()
        grad([(crateFaceT, 0), (crateFaceB, 1)]).draw(in: rect(front), angle: -90)
        grad([(crateSideT, 0), (crateSideB, 1)])
            .draw(in: poly([P(fx1, fy0), P(fx1 + dx, fy0 + dy), RB, RF]), angle: -90)
        grad([(crateTop, 0), (crateTopLo, 1)]).draw(in: poly([LF, RF, RB, LB]), angle: 0)
        // One light across the whole object: the left end catches the key, the right falls off.
        grad([(rgba(1, 1, 1, 0.30), 0), (rgba(1, 1, 1, 0), 0.30), (black(0), 0.70), (black(0.10), 1)])
            .draw(in: rect(box.bounds), angle: 0)
    }
    // The lit lip along the front-top edge — the one edge of a box that always catches the light.
    layer {
        box.addClip()
        let lip = NSBezierPath(); lip.move(to: LF); lip.line(to: RF)
        lip.lineWidth = max(0.8, u(0.005))
        white.withAlphaComponent(0.85).setStroke(); lip.stroke()
        // The seam: one strip of tape over the lid and down the front, following the box's own
        // perspective. It darkens whatever is under it rather than carrying a colour of its own,
        // so it survives the step from a 255 lid to a 168 front face without banding, and it
        // fades out on its own by 64px. This is the difference between a white cube and a parcel.
        let mx = (fx0 + fx1) / 2, w = u(0.014)
        black(0.055).setFill()
        poly([P(mx - w, fy0), P(mx + w, fy0), P(mx + w, fy1), P(mx + w + dx, fy1 + dy),
              P(mx - w + dx, fy1 + dy), P(mx - w, fy1)]).fill()
        let edge = NSBezierPath()
        edge.move(to: P(mx - w, fy0)); edge.line(to: P(mx - w, fy1)); edge.line(to: P(mx - w + dx, fy1 + dy))
        edge.lineWidth = max(0.6, u(0.0035))
        white.withAlphaComponent(0.30).setStroke(); edge.stroke()
    }
    NSGraphicsContext.restoreGraphicsState()
}

// ── The mark, recut on the pixel grid (32) ───────────────────────────────────────
// Below 64 a gore is under a pixel wide and a real diagonal riser is a grey smear. What survives
// is the part that carries the silhouette: canopy, GAP, two risers, crate. The gap is the whole
// reason this is a parachute and not a mushroom, so it is budgeted first. Every edge lands on a
// whole pixel — that, not the drawing, is what makes a small icon look sharp.
func drawSmall(_ ctx: CGContext, _ body: NSRect, _ canvas: Int) {
    let tile = drawTile(ctx, body, canvas, hairline: false)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    let cx = body.midX
    // Half-widths of the canopy, one entry per pixel row, apex first. Hand-cut: a rounded crown
    // that flares to its widest at the skirt, which is the parachute's own profile.
    let half: [CGFloat] = [4, 6, 7, 8, 9, 9, 10, 10, 11, 11]
    let apexY  = body.maxY - 2
    let hemY   = apexY - CGFloat(half.count)
    let crateW: CGFloat = 12
    let crateH: CGFloat = 9
    let crateY = body.minY + 3
    let crateTopY = crateY + crateH
    let steps = Int(hemY - crateTopY)              // 4 rows of riser

    let dome = NSBezierPath()
    for (i, h) in half.enumerated() {
        dome.appendRect(NSRect(x: cx - h, y: apexY - CGFloat(i) - 1, width: 2 * h, height: 1))
    }
    dome.windingRule = .nonZero
    // Lit from up and to the LEFT, same source as the full drawing.
    grad([(mix(accentGlow, white, 0.20), 0), (accent, 0.55), (shade(accent, 0.74), 1)])
        .draw(in: dome, angle: -72)
    // Skirt: the bottom row is the hem tape, one whole pixel of it.
    shade(accent, 0.60).setFill()
    rect(NSRect(x: cx - half[half.count - 1], y: hemY, width: 2 * half[half.count - 1], height: 1)).fill()
    // Scallops, only where one is a whole pixel deep: three notches cut out of the hem at the gore
    // cusps, repainted with the tile's own gradient so they are background, never a grey speck.
    layer {
        let notches = NSBezierPath()
        for dx in [CGFloat(-6), 0, 6] {
            notches.appendRect(NSRect(x: cx + dx - 1, y: hemY, width: 2, height: 1))
        }
        notches.addClip()
        ground900.setFill(); rect(body).fill()
        bodyGrad.draw(in: rect(body), angle: -90)
    }
    // Risers. Two rules, and between them they are the whole 32px drawing:
    //   · A one-pixel-per-row staircase is a DOTTED line — consecutive pixels meet at a corner
    //     only, so nothing connects. Each step is therefore 2px wide and shifts by 1, which makes
    //     row i and row i+1 share a whole column.
    //   · They must SPLAY. Dropping them straight down from the middle of the hem into the top of
    //     the crate made a stranger read the result as a tree: dome, two stems, pot. Starting them
    //     out near the ends of the skirt and walking them inward onto the crate's shoulders is
    //     what puts the V back, and the V is the parachute.
    let riserLit  = shade(accent, 0.94)
    let riserDark = shade(accent, 0.72)
    let x0 = cx - (crateW / 2 + CGFloat(steps) - 1)
    for i in 0..<steps {
        let y = hemY - 1 - CGFloat(i)
        let x = x0 + CGFloat(i)
        let w: CGFloat = 2
        riserLit.setFill(); rect(NSRect(x: x, y: y, width: w, height: 1)).fill()
        riserDark.setFill()
        rect(NSRect(x: 2 * cx - x - w, y: y, width: w, height: 1)).fill()
    }
    // Crate: the big drawing's three faces and nothing else — two lit rows for the lid, one dark
    // column on the right for the flank turned out of the light, one shaded floor row. A seam line
    // ACROSS the front as well made it read as a window frame rather than a box.
    let block = NSRect(x: cx - crateW / 2, y: crateY, width: crateW, height: crateH)
    // Flat paper, not the big drawing's 236→168 front-face ramp: over nine pixel rows that ramp
    // turned the whole block grey and cost it the brightness the blind test actually read.
    paper.setFill(); rect(block).fill()
    white.setFill()
    rect(NSRect(x: block.minX, y: block.maxY - 1, width: crateW, height: 1)).fill()
    crateFloor.setFill()
    rect(NSRect(x: block.minX, y: block.minY, width: crateW, height: 1)).fill()
    crateTopLo.setFill()
    rect(NSRect(x: block.minX, y: block.maxY - 2, width: crateW, height: 1)).fill()
    crateSideT.setFill()
    rect(NSRect(x: block.maxX - 1, y: block.minY, width: 1, height: crateH - 1)).fill()
    NSGraphicsContext.restoreGraphicsState()
}

// ── The 16, cut as a table of fourteen pixels ────────────────────────────────────
// The body is 14×14 device pixels at margin 1. At this size the drawing IS the pixel grid, so it
// is written as one: body-local coordinates, x 0…13 left to right, y 0…13 BOTTOM to top.
//
// The round-1 16 put a dome on two thick converging legs above a small block, and 2 of 5 unprimed
// viewers called it a BROCCOLI FLORET (rest of the guess pool: tree, mushroom, hot air balloon).
// Eight rounds of rendering and looking say the hem was not the culprit — there were never any
// scallops at 16, the `if !tiny` guard skipped them. The culprit was that the canopy, the legs
// and the box formed ONE continuous tapering green mass, which is precisely a floret's
// silhouette. Three changes fix it and all three are about the VOID:
//   · the rigging is ONE pixel wide, not two. Two pixels a side converging over four rows is a
//     filled cone, and the cone is the floret. One pixel is a cord.
//   · the hem OVERHANGS the rigging by two pixels each side. Nothing that grows out of the ground
//     is narrower than the thing on top of it.
//   · the rigging lands INBOARD of the crate's corners, so the box sticks out past its own lines.
//     A table's legs are at its corners; a slung load's are not. That one pixel is what moved the
//     read from "stool" to "hanging".
// Tried, rendered, looked at and rejected: scallops here (they earn their place at 32, where the
// hem is 21px and a notch is 2 — at 12px they are noise); a canopy run to the full 14 (it merges
// with the tile's own rounded top and reads as a LID on a jar); and the 32's proportions halved
// honestly, 5 canopy rows over a 5-row crate, which is a PLANT POT whatever the arithmetic says.
func drawTiny(_ ctx: CGContext, _ body: NSRect) {
    let tile = drawTile(ctx, body, 16, hairline: false)
    NSGraphicsContext.saveGraphicsState()
    tile.addClip()
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
        NSRect(x: body.minX + x, y: body.minY + y, width: w, height: h)
    }
    // Canopy: three rows widening onto the hem, lit from up and to the LEFT like the 1024.
    let dome = NSBezierPath()
    for (y, x, w) in [(12, 4, 6), (11, 2, 10), (10, 1, 12)] as [(CGFloat, CGFloat, CGFloat)] {
        dome.appendRect(R(x, y, w, 1))
    }
    dome.windingRule = .nonZero
    grad([(mix(accentGlow, white, 0.20), 0), (accent, 0.55), (shade(accent, 0.74), 1)])
        .draw(in: dome, angle: -72)
    shade(accent, 0.80).setFill()                  // the hem tape, one whole pixel of it
    rect(R(1, 9, 12, 1)).fill()
    // Rigging: two cords one pixel wide and four rows tall, hung two pixels inboard of the
    // skirt's corners. Dead straight — a 1px line cannot change column without breaking into a
    // dotted diagonal, and a broken cord is worse than a vertical one.
    mix(accent, paper, 0.60).setFill(); rect(R(4, 5, 1, 4)).fill()   // the side facing the key
    mix(accent, paper, 0.34).setFill(); rect(R(9, 5, 1, 4)).fill()   // the side turned away
    // Crate: eight wide, four deep, and three faces of one box — lit lid, front, and a flank out
    // of the light — which is the least ink that reads rigid instead of printed. Its lid is wider
    // than the cords land, and that overhang is what makes it hang rather than stand.
    paper.setFill();      rect(R(3, 1, 8, 4)).fill()
    white.setFill();      rect(R(3, 4, 8, 1)).fill()
    crateFloor.setFill(); rect(R(3, 1, 8, 1)).fill()
    crateSideT.setFill(); rect(R(10, 1, 1, 3)).fill()
    NSGraphicsContext.restoreGraphicsState()
}

// ── Render ────────────────────────────────────────────────────────────────────────
// Tile geometry measured off the macOS system icons at every size that ships. The opaque body is
// a WHOLE number of device pixels at each one — Apple does not scale one fraction down the range,
// the small sizes get proportionally more ink so they stay legible.
//
// 64 → 52 (margin 6), NOT 54/5. Measured on Notes, Calendar, Mail, Maps, Music and Reminders
// rendered natively at 64: every one is x[6…57], and the pixel just outside reads shadow (24 at
// the flanks, 71 below), not a body fringe. 54 was wrong and it made the tile 3.8% oversized.
// 512 → 412 (margin 50): the system's own 512 has a HALF-TONE body edge (the ring outside its
// alpha≥250 bbox reads 210 on all four sides, i.e. a body of 411.6px), so there is no whole-pixel
// answer to copy. 412 is the nearest one and is exactly half of 1024's 824.
let MARGIN: [Int: CGFloat] = [16: 1, 32: 2, 64: 6, 128: 12, 256: 25, 512: 50, 1024: 100]

func icon(_ size: Int) -> NSBitmapImageRep {
    let rep = bitmap(size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    let m = MARGIN[size] ?? (CGFloat(size) * 0.09765625).rounded()
    let body = NSRect(x: m, y: m, width: CGFloat(size) - 2 * m, height: CGFloat(size) - 2 * m)
    size <= 16 ? drawTiny(ctx, body)
        : size < 64 ? drawSmall(ctx, body, size) : drawFull(ctx, body, size)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Nearest-neighbour blow-up: review only, so the 16 and 32 can be judged by eye.
func zoom(_ rep: NSBitmapImageRep, to size: Int) -> NSBitmapImageRep {
    let out = bitmap(size)
    let img = NSImage(size: NSSize(width: rep.pixelsWide, height: rep.pixelsHigh))
    img.addRepresentation(rep)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: out)
    NSGraphicsContext.current?.imageInterpolation = .none
    NSGraphicsContext.current?.cgContext.interpolationQuality = .none
    img.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    return out
}

// ── Output ────────────────────────────────────────────────────────────────────────
let outDir = CommandLine.arguments.dropFirst().first ?? "Resources/Chute.iconset"
// The review PNGs go in a SIBLING directory, always — never inside outDir, and never conditional
// on its name. Anything but the ten icon_*.png in the folder handed to iconutil is either copied
// into the .icns as junk chunks (702,594 bytes vs 668,181 — 5.1% of dead weight) or, for a stray
// subdirectory, rejected outright with "Invalid Iconset." That made the command this script
// PRINTS fail for every outdir that did not happen to end in .iconset.
let outURL = URL(fileURLWithPath: outDir)
let reviewDir = outURL.deletingLastPathComponent().appendingPathComponent("icon-review").path
for d in [outDir, reviewDir] {
    try! FileManager.default.createDirectory(atPath: d, withIntermediateDirectories: true)
}
func write(_ rep: NSBitmapImageRep, _ name: String, _ dir: String) {
    try! rep.representation(using: .png, properties: [:])!
        .write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
}
// The ten ICONUTIL-CANONICAL names. `iconutil -c icns` exits 1 with "Failed to generate ICNS" on
// bare numeric filenames — these are the only ones it reads, and each is rendered NATIVELY at its
// pixel size rather than downscaled from a bigger one.
let sizes: [(Int, [String])] = [
    (16,   ["icon_16x16"]),
    (32,   ["icon_16x16@2x", "icon_32x32"]),
    (64,   ["icon_32x32@2x"]),
    (128,  ["icon_128x128"]),
    (256,  ["icon_128x128@2x", "icon_256x256"]),
    (512,  ["icon_256x256@2x", "icon_512x512"]),
    (1024, ["icon_512x512@2x"]),
]
var reps: [Int: NSBitmapImageRep] = [:]
for (px, names) in sizes {
    let rep = icon(px); reps[px] = rep
    for n in names { write(rep, n, outDir) }
}
for px in [128, 64, 32, 16] { write(reps[px]!, "\(px)", reviewDir) }
write(zoom(reps[16]!, to: 512), "16-zoom", reviewDir)
write(zoom(reps[32]!, to: 512), "32-zoom", reviewDir)
// ── Install ───────────────────────────────────────────────────────────────────────
// With NO argument this does the whole job: iconset → .icns → the site's favicon, from one set of
// pixels. The mark used to live in three places that were regenerated by hand, which is how a
// launch ends up with three slightly different logos. One command, or it drifts.
//
// With an outdir argument it renders and stops — that is the path the design bake-off used, and
// it must never touch the repo.
func run(_ tool: String, _ args: [String]) -> Int32 {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: tool)
    p.arguments = args
    do { try p.run() } catch { return -1 }
    p.waitUntilExit()
    return p.terminationStatus
}

/// An .ico is a 6-byte header, one 16-byte directory entry per image, then the payloads back to
/// back. PNG payloads rather than the legacy BMP form: every browser since IE11 reads them, and it
/// keeps this to twenty lines instead of a bitmap encoder.
func writeICO(_ images: [(side: Int, data: Data)], to path: String) throws {
    func le<T: FixedWidthInteger>(_ v: T) -> [UInt8] { withUnsafeBytes(of: v.littleEndian, Array.init) }
    var out = Data([0, 0, 1, 0])                                  // reserved, type = icon
    out.append(contentsOf: le(UInt16(images.count)))
    var offset = 6 + 16 * images.count
    for i in images {
        // 0 means 256 in this field — the byte cannot hold 256 itself.
        let n = UInt8(i.side == 256 ? 0 : i.side)
        out.append(contentsOf: [n, n, 0, 0])                      // w, h, palette count, reserved
        out.append(contentsOf: le(UInt16(1)))                     // colour planes
        out.append(contentsOf: le(UInt16(32)))                    // bits per pixel
        out.append(contentsOf: le(UInt32(i.data.count)))
        out.append(contentsOf: le(UInt32(offset)))
        offset += i.data.count
    }
    for i in images { out.append(i.data) }
    try out.write(to: URL(fileURLWithPath: path))
}

guard CommandLine.arguments.count == 1 else {
    // iconutil ALSO refuses any input directory whose NAME does not end in .iconset — "Invalid
    // Iconset.", exit 1, whatever is inside it. So for any other outdir the honest next step is
    // the copy. Printing an instruction that fails is the same bug as shipping files that break it.
    let next = outDir.hasSuffix(".iconset")
        ? "iconutil -c icns \(outDir) -o Chute.icns"
        : "ditto \(outDir) \(outDir).iconset && iconutil -c icns \(outDir).iconset -o Chute.icns"
    print("10 iconset PNGs → \(outDir)\n 6 review PNGs → \(reviewDir)\n \(next)")
    exit(0)
}

let icns = "Resources/Chute.icns"
let status = run("/usr/bin/iconutil", ["-c", "icns", outDir, "-o", icns])
guard status == 0 else {
    FileHandle.standardError.write(Data("make-icon: iconutil failed (\(status))\n".utf8))
    exit(1)
}

// The favicon comes off the SAME draw function, so the tab icon and the Dock icon cannot disagree.
// 48 is downscaled from 256 rather than drawn: below 64 the artwork is hand-cut per size for 16
// and 32 only, and a 48 through that path would be neither the small mark nor the large one.
let ico = "site/src/app/favicon.ico"
do {
    let png = { (r: NSBitmapImageRep) in r.representation(using: .png, properties: [:])! }
    let big = reps[256]!
    let r48 = bitmap(48)
    layer {
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: r48)
        NSGraphicsContext.current?.imageInterpolation = .high
        let img = NSImage(size: NSSize(width: 256, height: 256)); img.addRepresentation(big)
        img.draw(in: NSRect(x: 0, y: 0, width: 48, height: 48))
    }
    try writeICO([(16, png(reps[16]!)), (32, png(reps[32]!)), (48, png(r48)), (256, png(big))],
                 to: ico)
} catch {
    FileHandle.standardError.write(Data("make-icon: cannot write \(ico) — \(error)\n".utf8))
    exit(1)
}

let bytes = (try? FileManager.default.attributesOfItem(atPath: icns)[.size] as? Int) ?? 0
print("""
      10 iconset PNGs → \(outDir)
       6 review PNGs → \(reviewDir)
                icns → \(icns) (\(bytes) bytes)
             favicon → \(ico)
      """)
