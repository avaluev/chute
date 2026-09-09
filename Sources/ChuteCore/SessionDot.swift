import AppKit

/// THE TRAFFIC LIGHT — and the bug that made half of it invisible for its whole life.
///
/// ── WHY THIS IS IN ChuteCore ────────────────────────────────────────────────────────────────
///
/// It lived in `Sources/ChuteApp/SessionMenu.swift`, which `chutetests` cannot link. On
/// 2026-09-08 the redesigned menu was rendered to a PNG for the first time and the two most
/// important dots in the product — the red square that means STOP and the green circle that
/// means READY — were simply not there. Only the rings drew.
///
/// The cause was one line, and a comment that argued for it:
///
///     let hole = r.insetBy(dx: f.d * f.hole, dy: f.d * f.hole)   // f.hole == 0 for "filled"
///     path.append(NSBezierPath(roundedRect: hole, ...))
///     path.windingRule = .evenOdd
///     // "A zero-inset hole is the same rect twice, which cancels to nothing —
///     //  so 'filled' needs no branch."
///
/// That reasoning is exactly backwards. Under `.evenOdd`, a point inside both rectangles has a
/// crossing number of two, which is even, which is OUTSIDE. The same rect twice does not cancel
/// the HOLE, it cancels the SHAPE. `hole: 0` never meant "filled"; it meant "draw nothing".
///
/// Nothing could catch it. `Scripts/check-untested-logic.sh` counts branches, and this code had
/// none — it was branch-free and wrong. No assertion could import it. It is the exact failure
/// `StatusMenu.swift`'s own header comment describes for Recent Copies, repeated in the one
/// place where being wrong is least survivable: the signal the whole app exists to give you.
///
/// So the geometry moved here, where `SessionDotSuite` renders every token and counts the pixels
/// that actually got painted. A dot that draws nothing now fails the build.
///
/// ── THE TWO RULES, UNCHANGED ────────────────────────────────────────────────────────────────
///
/// SHAPE CARRIES THE MEANING; COLOUR IS THE REDUNDANCY. A filled square stops you, a filled
/// circle is finished, a ring is motion, a small mark is nothing to do. Squint, or drop the hue
/// entirely, and they are still four different things — roughly one man in twelve cannot separate
/// this red from this green, and they are squarely in this product's audience.
///
/// UNKNOWN MUST NEVER READ AS CALM. `idle` and `unknown` deliberately share the same grey, so
/// neither looks more or less alarming than the other by colour; only shape separates "a quiet
/// shell" from "Chute has no idea what this session is doing".
public enum SessionDot {
    /// `systemRed`/`systemGreen`/`systemOrange` are dynamic catalog colours, so they re-resolve
    /// for light, dark and Increase Contrast on their own.
    static let ink: [String: NSColor] = [
        "blocked": .systemRed, "waiting": .systemGreen, "working": .systemOrange,
        "idle": .tertiaryLabelColor, "unknown": .tertiaryLabelColor,
    ]

    /// `d` is the glyph's diameter. `holeInset` is the fraction of `d` to inset the cut-out by, so
    /// **0.5 insets it to zero size and leaves a solid shape** — that is what "filled" means here,
    /// and it is the fix for the bug in this file's header. It is data, not a branch: every token
    /// takes the identical drawing path, and `dot()` still has no `if` in it.
    /// `corner` of 0 is a square; a large value is a circle.
    static let form: [String: (d: CGFloat, holeInset: CGFloat, corner: CGFloat)] = [
        // ONE GEOMETRY, AND SIZE MEANS EXACTLY ONE THING.
        //
        // Every mark is a SQUARE (corner 0) as of 2026-09-09: five different outlines read as
        // noise in a list this dense.
        //
        // The first attempt that day drew `waiting` at 7pt against `blocked`'s 9pt, so the two
        // would differ without colour — red and green being the pair roughly one man in twelve
        // cannot separate. The founder looked at it and asked what the size meant. Nothing: it
        // was a hack, and SIZE READS AS MAGNITUDE, so a difference that encoded nothing invited
        // everyone to look for a meaning that was not there.
        //
        // What that reasoning missed is that the dot is not the only carrier. The row says
        // "blocked 22 min" or "ready 2 h" in bold immediately beside it, and that word is what a
        // colour-blind reader actually uses. The dot is a scanning aid, not the sole signal.
        //
        // So size now means ONE thing — small is a shell with nothing running — and FILL does the
        // work that cannot fall back on words: `unknown` and `idle` are BOTH GREY, so colour can
        // never separate them, and an un-instrumented machine must never read as a calm one.
        // That pair is pinned by `SessionDotSuite` and is the one distinction here that has no
        // second carrier at all.
        "blocked": (9, 0.5,  0),     // solid square — the one that stops you
        "waiting": (9, 0.5,  0),     // solid square — finished, wants a prompt
        // ONE HOLLOW WEIGHT, not three. This was 0.34, which left a 2.9pt pinhole inside a 3.1pt
        // border — nearly solid, and the eye read it as a HEAVIER, larger mark than the 9pt solid
        // squares beside it. The founder saw the orange looking bigger than the green and asked
        // why, which is the same complaint as the size question before it: a visual difference
        // that encodes nothing. 0.25 matches `unknown`, so every hollow square in the menu is the
        // same 2.25pt outline and the only weights in the column are SOLID and OUTLINE.
        "working": (9, 0.25, 0),     // hollow square — running, nothing for you to do
        "idle":    (5, 0.5,  0),     // a SMALL solid square — a shell, nothing running
        // A RING NEEDS ROOM TO BE A RING. At 5pt with a 0.34 inset the hole is 1.6pt, which
        // rasterises away to nothing at 1x — so `unknown` painted the identical pixels as
        // `idle`, and the two states that must never look alike looked exactly alike. Caught by
        // SessionDotSuite the day this file was written, and it is the brief's own hard rule:
        // an un-instrumented machine must read as UNINSTRUMENTED, never as all-clear. 7pt with a
        // 0.25 inset leaves a 3.5pt hole, which survives even on a non-Retina display.
        "unknown": (9, 0.25, 0),     // a hollow square — Chute does not know, and says so
        "none":    (0, 0.5,  0),     // draws NOTHING, on purpose — the column header's own
                                     // "dot", so its text starts from the same origin as every
                                     // session row's. This is the ONE token allowed to be blank.
    ]

    /// Every token that must actually paint something. `none` is deliberately absent.
    public static let visibleTokens = ["blocked", "waiting", "working", "idle", "unknown"]

    public static func image(_ token: String) -> NSImage {
        // A CONSTANT CANVAS, whatever the glyph's size. AppKit lays a menu item's text out from
        // the right edge of its image, so a 5pt image and a 9pt image would put their titles in
        // two different columns and the whole list would develop a ragged left margin. The glyph
        // shrinks inside the box; the box never does.
        let box = NSSize(width: 12, height: 12)
        let colour = ink[token] ?? .tertiaryLabelColor
        let f = form[token] ?? (5, 0.5, 99)
        return NSImage(size: box, flipped: false) { rect in
            let r = NSRect(x: rect.midX - f.d / 2, y: rect.midY - f.d / 2, width: f.d, height: f.d)
            let path = NSBezierPath(roundedRect: r, xRadius: f.corner, yRadius: f.corner)
            let hole = r.insetBy(dx: f.d * f.holeInset, dy: f.d * f.holeInset)
            // evenOdd turns the second shape into a hole rather than a second disc. At
            // holeInset 0.5 that shape has zero size and contributes nothing, so the outer shape
            // stays solid — see the header for what happens when it does NOT have zero size.
            path.append(NSBezierPath(roundedRect: hole, xRadius: f.corner, yRadius: f.corner))
            path.windingRule = .evenOdd
            colour.setFill()
            path.fill()
            return true
        }
    }

    /// How many pixels the token's glyph actually paints, at the canvas's own scale. Exists so a
    /// test can ask the question that nothing could ask before: *did anything appear?*
    public static func paintedPixels(_ token: String) -> Int {
        let img = image(token)
        guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff)
        else { return 0 }
        var painted = 0
        for x in 0..<rep.pixelsWide {
            for y in 0..<rep.pixelsHigh where (rep.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.01 {
                painted += 1
            }
        }
        return painted
    }
}
