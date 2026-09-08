import AppKit
import Foundation
import ChuteCore

/// THE ICON HAS DISAPPEARED FROM THE MENU BAR TWICE. This is the test that would have caught it.
///
/// An `NSStatusItem` with `variableLength`, no image and no title is **zero points wide**. The
/// app is running, the status item is real, and there is nothing on screen to see or to click —
/// which is indistinguishable, to the person looking, from the app having failed to launch.
///
/// Both incidents shipped green:
///   · 2026-09-04 — a refactor removed `updateBadgeFromHooks()`, whose name said "badge" but
///     which was also the only thing that ever set the status item's image at launch.
///   · 2026-09-08 — the mark gained a state pip, and the quiet case stopped drawing anything.
///
/// Neither could be caught, because `MenuBarMark` lived in `Sources/ChuteApp/` and `chutetests`
/// links only `ChuteCore`; an executable target cannot be imported. Moving the file is what makes
/// these assertions possible, and the assertions are the actual point of having moved it.
///
/// `screencapture` is NOT a substitute and must never be used as one: without Screen Recording
/// permission it returns a pure black image, which looks exactly like an empty menu bar. The tool
/// that would verify this lies in the same direction as the bug.
func menuBarMarkSuite() {
    T.suite("MenuBarMark") {
        // A mark that draws nothing is the bug. Count pixels that actually got ink.
        func inkedPixels(_ image: NSImage) -> Int {
            guard let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff) else { return 0 }
            var lit = 0
            for x in 0..<bitmap.pixelsWide {
                for y in 0..<bitmap.pixelsHigh where (bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0) > 0.05 {
                    lit += 1
                }
            }
            return lit
        }

        // ── EVERY STATE DRAWS SOMETHING ─────────────────────────────────────────────────────
        //
        // "idle" and "unknown" are the ones that broke: they take the no-pip path, which is the
        // path the app is in on a machine whose hooks are not wired — i.e. every new install.
        for token in ["idle", "unknown", "blocked", "waiting", "working", "nonsense-token"] {
            let img = MenuBarMark.image(token)
            T.ok(img.size.width > 0 && img.size.height > 0, "\(token): the image has a size")
            T.ok(inkedPixels(img) > 20,
                 "\(token): the mark actually draws — a blank image is a zero-width menu bar item")
        }

        // The parachute is the identity and must be present whatever the state, so a mark with a
        // pip has MORE ink than the plain one, never less. This catches a pip drawn with a
        // destination-clearing composite op, which would erase the canopy it sits beside.
        let plainInk = inkedPixels(MenuBarMark.image("idle"))
        for token in ["blocked", "waiting", "working"] {
            T.ok(inkedPixels(MenuBarMark.image(token)) >= plainInk,
                 "\(token): the pip adds ink, it never eats the parachute")
        }

        // ── TEMPLATE, OR THE COLOUR IS THROWN AWAY ──────────────────────────────────────────
        //
        // macOS treats a template image as a MASK and recolours it for the bar, discarding every
        // colour in it. A coloured pip therefore CANNOT be a template; the plain mark must be one,
        // or it stops adapting to a light bar, a tinted desktop and Increase Contrast.
        T.ok(MenuBarMark.image("idle").isTemplate, "the quiet mark is a template, so macOS tints it")
        T.ok(MenuBarMark.image("unknown").isTemplate, "and so is an un-instrumented machine's")
        for token in ["blocked", "waiting", "working"] {
            T.no(MenuBarMark.image(token).isTemplate,
                 "\(token): a coloured pip cannot be a template or its colour is discarded")
        }

        // ── THE PLAN IS THE THING THE APP ACTS ON ───────────────────────────────────────────
        T.no(MenuBarMark.plan("idle").pip, "idle asks for no pip")
        T.no(MenuBarMark.plan("unknown").pip, "and neither does unknown — silence is not green")
        T.eq(MenuBarMark.plan("idle").diameter, 0, "so its diameter is zero and nothing is drawn")
        for token in ["blocked", "waiting", "working"] {
            T.ok(MenuBarMark.plan(token).pip, "\(token) asks for a pip")
            T.ok(MenuBarMark.plan(token).diameter > 2, "\(token)'s pip is big enough to see")
        }
        // An unknown token must fall back to silence, never to a colour. A typo in a state name
        // must not light the bar green.
        T.no(MenuBarMark.plan("nonsense-token").pip, "an unrecognised state shows nothing at all")

        // ── LEGIBLE ON A DARK MENU BAR ──────────────────────────────────────────────────────
        //
        // THIS IS THE ONE THAT WOULD HAVE CAUGHT 2026-09-08's SECOND DISAPPEARANCE, and the
        // pixel-count assertions above would not have — they passed while the icon was invisible.
        // The mark drew perfectly; it drew in BLACK. That is correct for a template, where macOS
        // discards the colour and re-inks the mask white on a dark bar. A mark carrying a coloured
        // pip cannot be a template, so its black survived, and a black parachute on a dark menu
        // bar is nothing at all.
        //
        // "It renders" is not "it can be seen". Assert the second thing.
        func meanLuminance(_ image: NSImage) -> Double {
            guard let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff) else { return 0 }
            var total = 0.0, counted = 0
            for x in 0..<bitmap.pixelsWide {
                for y in 0..<bitmap.pixelsHigh {
                    guard let c = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB),
                          c.alphaComponent > 0.5 else { continue }
                    total += Double(c.brightnessComponent)
                    counted += 1
                }
            }
            return counted == 0 ? 0 : total / Double(counted)
        }

        if let dark = NSAppearance(named: .darkAqua) {
            dark.performAsCurrentDrawingAppearance {
                for token in ["blocked", "waiting", "working"] {
                    // Not a template, so nothing will re-ink this for us. It must arrive light.
                    T.ok(meanLuminance(MenuBarMark.image(token)) > 0.4,
                         "\(token): the parachute is legible on a DARK menu bar, not black on black")
                }
            }
        }
        if let light = NSAppearance(named: .aqua) {
            light.performAsCurrentDrawingAppearance {
                for token in ["blocked", "waiting", "working"] {
                    T.ok(meanLuminance(MenuBarMark.image(token)) < 0.6,
                         "\(token): and dark enough to read on a LIGHT one")
                }
            }
        }

        // ── SIZE ────────────────────────────────────────────────────────────────────────────
        // 16 tall matches the SF Symbol this replaced, so the menu bar row height does not jump.
        T.eq(Double(MenuBarMark.size.height), 16, "the mark is 16 points tall")
        T.ok(MenuBarMark.size.width > MenuBarMark.size.height,
             "and wider than it is tall — the canopy's aspect ratio is load-bearing")
    }
}
