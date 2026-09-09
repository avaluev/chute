import Foundation
import AppKit
import ChuteCore

/// THE ASSERTION THAT WOULD HAVE CAUGHT IT: did the dot draw anything at all?
///
/// Every one of these was unaskable until `SessionDot` moved into ChuteCore. The geometry lived
/// in `Sources/ChuteApp/`, which the suite cannot link, and it was branch-free — so the
/// decision-point ratchet was green on it too. It shipped invisible.
func sessionDotSuite() {
    T.suite("SessionDot") {
        // ── THE BUG, AS A RUNNING TEST ──────────────────────────────────────────────────────
        // `blocked` and `waiting` are the two the product exists to show you. Under the old
        // `holeInset: 0` they painted ZERO pixels, because an evenOdd path with the same rect
        // twice cancels the shape, not the hole.
        for token in SessionDot.visibleTokens {
            T.ok(SessionDot.paintedPixels(token) > 0,
                 "\(token) actually paints something — the whole point of a traffic light")
        }

        // ── AND THE ONE THAT IS SUPPOSED TO BE BLANK ────────────────────────────────────────
        // The column header's spacer. If this ever paints, there is a stray dot above the list.
        T.eq(SessionDot.paintedPixels("none"), 0,
             "the header's spacer draws nothing — it exists only to align the text origin")

        // An unknown token must degrade to a visible mark, never to a blank row.
        T.ok(SessionDot.paintedPixels("something-new") > 0,
             "an unrecognised state still shows SOMETHING rather than silently vanishing")

        // ── SHAPE CARRIES THE MEANING, COLOUR IS THE REDUNDANCY ─────────────────────────────
        // Drop the hue and the states must still be distinguishable. Pixel count is the coarsest
        // possible proxy for "these are different shapes", and it is enough to catch two states
        // being drawn identically — which is exactly what blocked and waiting used to be before
        // blocked became a square.
        let blocked = SessionDot.paintedPixels("blocked")
        let waiting = SessionDot.paintedPixels("waiting")
        let working = SessionDot.paintedPixels("working")
        let idle    = SessionDot.paintedPixels("idle")

        // WHAT IS ACTUALLY LOAD-BEARING, and what only looked like it.
        //
        // This block twice asserted things that were true of the drawing rather than required by
        // the design: first an ordering (working < waiting) that held only while working was a
        // ring and waiting a circle of the same diameter, then a rule that NO two states may
        // paint alike. The second is stricter than the product needs, and on 2026-09-09 it
        // blocked the right change for the wrong reason.
        //
        // `blocked` and `waiting` are allowed to be the same square in different colours. Every
        // row prints its state as a WORD in bold — "blocked 22 min", "ready 2 h" — right beside
        // the mark, so a reader who cannot separate red from green reads the row, not the dot.
        // Forcing a second difference there is what produced a 7pt green square whose smaller
        // size meant nothing and implied magnitude.
        //
        // `unknown` and `idle` are NOT allowed to match, and that is a different situation
        // entirely: they share a grey, so colour separates nothing, and their words are the two
        // most confusable in the menu. If they paint the same, a machine with no instrumentation
        // reads as a calm one. That is the distinction with no second carrier, so it is the one
        // this suite pins hardest.
        T.no(SessionDot.paintedPixels("unknown") == idle,
             "unknown and idle share a grey, so their FILL must differ or the two are one row")
        T.ok(working != blocked,
             "working is hollow where blocked is solid — the two never read as the same mark")
        T.ok(idle < blocked && idle < waiting && idle < working,
             "size means exactly one thing in this menu: the small mark is a shell with nothing running")
        T.eq(blocked, waiting,
             "blocked and waiting are deliberately the SAME square — the state word carries the difference, "
             + "and a size gap there would encode a magnitude that does not exist")

        // ── UNKNOWN MUST NOT READ AS CALM ───────────────────────────────────────────────────
        // idle and unknown share a colour on purpose, so shape is the ONLY thing separating
        // "a quiet shell" from "Chute cannot see this". If they ever paint the same, that
        // distinction is gone and an un-instrumented machine looks like a calm one.
        T.no(SessionDot.paintedPixels("unknown") == idle,
             "unknown and idle share a grey, so their SHAPES must differ or the two are one row")

        // ── THE CONSTANT CANVAS ─────────────────────────────────────────────────────────────
        // AppKit lays a menu item's text out from the right edge of its image, so a 5pt glyph and
        // a 9pt glyph in differently-sized boxes would ragged the whole left margin.
        let sizes = Set((SessionDot.visibleTokens + ["none"]).map {
            let s = SessionDot.image($0).size
            return "\(s.width)x\(s.height)"
        })
        T.eq(sizes, ["12.0x12.0"],
             "every dot ships the same 12x12 canvas, whatever the glyph inside it")
    }
}

/// The backticks that shipped as literal punctuation in two Settings tabs.
func inlineCodeSuite() {
    T.suite("InlineCode") {
        let seg = InlineCode.segments("run `chute gist` now")
        T.eq(seg.map(\.text), ["run ", "chute gist", " now"], "the span between ticks is isolated")
        T.eq(seg.map(\.isCode), [false, true, false], "and only that span is code")

        T.no(InlineCode.segments("a `b` c").contains { $0.text.contains("`") },
             "no backtick survives into anything drawn")

        // TWO commands in one sentence — the privacy paragraph has exactly this shape.
        let two = InlineCode.segments("`chute gist` uses your own `gh` credentials")
        T.eq(two.filter(\.isCode).map(\.text), ["chute gist", "gh"], "both spans are found")

        // AN UNMATCHED TICK must not restyle the rest of the paragraph. A typo in copy is a typo;
        // a typo that silently turns half a page monospace is a bug report.
        let odd = InlineCode.segments("an `unclosed span keeps going")
        T.no(odd.contains { $0.isCode }, "an unmatched tick renders nothing as code")
        T.eq(odd.map(\.text).joined(), "an unclosed span keeps going",
             "and the text still reads correctly, minus the stray tick")

        T.eq(InlineCode.segments("").count, 0, "empty in, nothing out")
        T.eq(InlineCode.segments("``").count, 0, "an empty span contributes no run")
        T.eq(InlineCode.segments("plain").map(\.text), ["plain"], "prose with no ticks is one run")

        // The real strings, so a copy edit that breaks the parse fails here.
        let privacy = InlineCode.segments(AboutText.privacy)
        T.eq(privacy.filter(\.isCode).map(\.text), ["chute gist", "gh"],
             "the privacy paragraph's two commands are the two code spans")
        T.no(AboutText.privacy.isEmpty, "and the paragraph it came from is still there")

        // Same point size, or a paragraph with a command in it breaks the baseline grid.
        let a = InlineCode.attributed("x `y`", font: .systemFont(ofSize: 12), color: .labelColor)
        var sizes = Set<CGFloat>()
        a.enumerateAttribute(.font, in: NSRange(location: 0, length: a.length)) { v, _, _ in
            (v as? NSFont).map { sizes.insert($0.pointSize) }
        }
        T.eq(sizes, [12], "code and prose share a point size, so line height does not jump")
    }
}

/// THE MENU BAR ICON'S PIP — the same question the row dots failed, asked of the icon.
///
/// `SessionDot` moved to ChuteCore because blocked and waiting had drawn NOTHING for the
/// product's whole life, and nothing could see it. `MenuBarMark` draws a pip with the identical
/// evenOdd technique and had the identical blind spot: `MenuBarMarkSuite` asserted the shape
/// TABLE, never the pixels. The icon has also vanished from the menu bar twice for unrelated
/// reasons. So it gets the same instrument.
func menuBarPipSuite() {
    T.suite("MenuBarMark pips") {
        func painted(_ token: String) -> (total: Int, red: Int, green: Int, orange: Int) {
            let img = MenuBarMark.image(token)
            guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else {
                return (0, 0, 0, 0)
            }
            var total = 0, red = 0, green = 0, orange = 0
            for x in 0..<rep.pixelsWide {
                for y in 0..<rep.pixelsHigh {
                    guard let c = rep.colorAt(x: x, y: y), c.alphaComponent > 0.5 else { continue }
                    guard let s = c.usingColorSpace(.sRGB) else { continue }
                    total += 1
                    let r = s.redComponent, g = s.greenComponent, b = s.blueComponent
                    if r > 0.6, g < 0.4, b < 0.4 { red += 1 }
                    if g > 0.5, r < 0.5, b < 0.5 { green += 1 }
                    if r > 0.7, g > 0.4, g < 0.75, b < 0.3 { orange += 1 }
                }
            }
            return (total, red, green, orange)
        }

        // THE ONE THE FOUNDER LOOKED FOR AND DID NOT SEE. `blocked` must put RED on the icon —
        // it is the only state that means a human is the blocker.
        let blocked = painted("blocked")
        T.ok(blocked.total > 0, "the blocked mark draws something at all")
        T.ok(blocked.red > 0, "and some of it is RED — a permission prompt is waiting on you")

        let waiting = painted("waiting")
        T.ok(waiting.green > 0, "waiting puts green on the icon — a turn finished, it wants a prompt")

        let working = painted("working")
        T.ok(working.orange > 0, "working puts orange on the icon — running, nothing for you to do")

        // A pip is a positive claim backed by a fresh hook. Without one the mark stays quiet —
        // silence and blindness must never render as "all clear", which is why neither of these
        // paints a colour at all.
        for quiet in ["idle", "unknown"] {
            let p = painted(quiet)
            T.eq(p.red + p.green + p.orange, 0,
                 "\(quiet) puts NO colour on the icon — Chute is not claiming anything")
            T.ok(p.total > 0, "\(quiet) still draws the parachute, so the icon never disappears")
        }

        // SHAPE, NOT ONLY COLOUR. Roughly one man in twelve cannot separate this red from this
        // green, and they are squarely in this product's audience.
        T.no(MenuBarMark.cornerFor("blocked") == MenuBarMark.cornerFor("waiting"),
             "blocked is a square and waiting is a circle — they differ with the hue removed")
        T.no(MenuBarMark.holeFor("working") == MenuBarMark.holeFor("waiting"),
             "and working is a ring, not a third filled shape")
    }
}
