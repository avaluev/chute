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

        T.ok(blocked > waiting,
             "a 9pt square covers more than a 9pt circle — the two differ in SHAPE, not just hue")
        T.ok(working < waiting,
             "the ring is hollow, so it paints less than the filled circle of the same diameter")
        T.ok(idle < waiting,
             "a shell's mark is the small one — it is the state with nothing to say")

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
