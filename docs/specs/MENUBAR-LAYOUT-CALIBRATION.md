# Menu-bar row layout — measured, not guessed

Every number below was produced by measuring real strings in the real fonts on this machine
(macOS 14.6, `swift` interpreter, `NSAttributedString.size()`), 2026-09-08. Re-run the measurement
before changing any of them; do not adjust one by eye.

## The spike that had to pass first

`NSMenuItem.attributedTitle` **does** render an embedded `\n` as two lines and grows the item.
Three identical items:

```
one-line menu: (414.0, 76.0)      25.3pt per item
two-line menu: (414.0, 127.0)     42.3pt per item      ratio 1.67
```

So the design is plain `NSMenuItem`s with tab stops — VoiceOver, keyboard navigation, Increase
Contrast and Reduce Transparency all stay free. `NSMenuItem.view` was not needed and must not be
introduced.

## Tab stops

| stop | location | alignment |
|---|---|---|
| col 2 (`AGENT · STATE`) | **200pt** | left |
| col 3 (`LOAD`) | **500pt** | right |

Measured from the **text origin**, which is why every row must carry a 12×12 image — including the
column header, which uses an empty one. A row with no image starts its text 12pt to the left and
takes the whole column system with it.

Resulting menu ≈ **547pt**. Today's widest real row measures **652pt** as one run-on string, so the
redesign is *narrower* than what it replaces, not wider.

## Worst realistic content per column

| column | widest string | width | headroom to next stop |
|---|---|---|---|
| col 1 | `~/…/a-very-lo…-directory/site` (path, 10.5 mono) | 188pt | 12pt |
| col 2 | `no hook — Chute cannot see this` (13 semibold) | 206pt | 11pt |
| col 3 | `177% · 3.0 GB` (12 mono-digit) | 83pt | — |

Headroom is tight on purpose: these two strings are the widest the product can produce, and both
are fixed wording rather than user data. If either is reworded longer, re-measure.

## Character budgets, and why they are not enough on their own

At 190pt of usable col-1 width:

| font | chars of `M` | chars of `n` |
|---|---|---|
| 13pt semibold (name) | 16 | 24 |
| 10.5pt mono (path) | 29 | 29 |

The path is monospaced, so 28 characters is an exact guarantee. **The name is not.** A 24-character
name of wide glyphs measures 277pt, overflows the 200pt tab stop, and the tab then jumps to the
next stop — which widens the entire menu and breaks every column below it. Verified:

```
ragged names   : (502.0, 166.0)      one 24-char name blew the column
short right col: (494.0, 166.0)
```

Mockup 2c's own caption is "the one that makes a bad project name harmless", so this is a
requirement, not a nicety. `PathAbbrev` keeps its pure character budgets — they are the editorial
rule, they are exactly testable, and `chute sessions` prints into a terminal where columns really
are characters. The menu additionally clamps by measured width before rendering.

## Open, to be confirmed by eye

`NSMenu.size` sums hidden `isAlternate` items, so it reports a two-line row plus its alternate as
88pt against 49pt for the row alone. That is a property of `.size`, not of what draws — AppKit
swaps the pair at display time. **Confirm by holding ⌥ with the menu open that the menu does not
change height.** If it does, the alternates need rethinking, not the tab stops.
