#!/usr/bin/env python3
"""Social-graphics generator for Chute. Colour comes only from tokens.json.

Usage:
    python3 brand/cards.py            # generate everything into brand/out/
    python3 brand/cards.py --check    # regenerate + assert every output is sane
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
TOKENS_PATH = os.path.join(HERE, "tokens.json")
OUT_DIR = os.path.join(HERE, "out")
FONT_DIR = "/Users/sxope/Library/Fonts"
# fallback order when a requested weight file is missing (never a silent system-font swap)
WEIGHT_FALLBACKS = ["Bold", "SemiBold", "Regular", "Medium", "ExtraBold", "Light"]

with open(TOKENS_PATH) as f:
    TOKENS = json.load(f)

C = {k: v["hex"] for k, v in TOKENS["color"].items()}
BRAND = TOKENS["brand"]

FEATURES = [
    ("bundle", "Eight files, one paste", "with the token count before you send it"),
    ("unpack", "An answer becomes files", "previews first, never escapes the folder"),
    ("sessions", "Which agent is waiting", "nine terminals, one honest list"),
    ("ports", "What is running on :3000", "and which project it belongs to"),
]

# (accent-coloured lead, rest) — kept as explicit data, not auto-split, so wording stays exact
QUOTES = [
    ("90–120", "minutes a day"),
    ("0", "lines of network code"),
    ("25", "commands, zero dependencies"),
    ("no account,", "no telemetry, no network"),
]


def hx(hex_code):
    """'#RRGGBB' -> (r, g, b)."""
    h = hex_code.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


_font_cache = {}


def load_font(weight, size):
    key = (weight, size)
    if key in _font_cache:
        return _font_cache[key]
    order = [weight] + [w for w in WEIGHT_FALLBACKS if w != weight]
    for i, w in enumerate(order):
        path = os.path.join(FONT_DIR, f"JetBrainsMono-{w}.ttf")
        if os.path.exists(path):
            if i > 0:
                print(f"WARNING: JetBrainsMono-{weight} missing, falling back to {w}", file=sys.stderr)
            font = ImageFont.truetype(path, size)
            _font_cache[key] = font
            return font
    raise RuntimeError("no JetBrains Mono weight found on disk")


def fit_font(draw, text, weight, max_width, start_size, min_size=16):
    """Shrink until the single line fits max_width. Returns (font, bbox)."""
    size = start_size
    font = load_font(weight, size)
    bbox = draw.textbbox((0, 0), text, font=font)
    while bbox[2] - bbox[0] > max_width and size > min_size:
        size -= 2
        font = load_font(weight, size)
        bbox = draw.textbbox((0, 0), text, font=font)
    assert bbox[2] - bbox[0] <= max_width, f"text overflow, cannot fit: {text!r}"
    assert bbox[3] - bbox[1] <= max_width, f"text vertical overflow: {text!r}"
    return font, bbox


def draw_text_fit(draw, xy, text, weight, max_width, size, fill, min_size=16):
    font, bbox = fit_font(draw, text, weight, max_width, size, min_size)
    draw.text(xy, text, font=font, fill=fill)
    return bbox


def new_canvas(w, h):
    img = Image.new("RGB", (w, h), hx(C["ground900"]))
    return img, ImageDraw.Draw(img)


def hairline(draw, x0, y, x1):
    draw.line([(x0, y), (x1, y)], fill=hx(C["ground600"]), width=1)


def draw_mark(d, x, y, size):
    """The Chute mark: a hopper narrowing into a lit slot. Returns the width it occupied.

    Vector, never a font glyph — see make_og. The proportions follow Scripts/make-icon.swift so
    the OG card, the app icon and the menu bar are recognisably the same object.
    """
    w = size * 0.78
    lip, throat = w, w * 0.34
    top, bottom = y + size * 0.10, y + size * 0.74
    wall = max(3, int(size * 0.075))

    # Two converging walls.
    d.line([(x, top), (x + (lip - throat) / 2, bottom)], fill=hx(C["accent"]), width=wall)
    d.line([(x + lip, top), (x + lip - (lip - throat) / 2, bottom)], fill=hx(C["accent"]), width=wall)

    # The lit slot at the bottom — the one bright thing, matching the icon's glow stop.
    slot_l = x + (lip - throat) / 2
    d.line([(slot_l, bottom), (slot_l + throat, bottom)],
           fill=hx(C["accentGlow"]), width=max(4, int(size * 0.10)))

    # A document falling in.
    dw, dh = throat * 0.62, throat * 0.78
    dx = slot_l + (throat - dw) / 2
    dy = top + (bottom - top) * 0.26
    d.rectangle([dx, dy, dx + dw, dy + dh], fill=hx(C["paper"]))
    return lip


def make_og():
    W, H = 1200, 630
    margin = 90
    img, d = new_canvas(W, H)

    # The mark is DRAWN, not typed. "⤓" is U+2913 and JetBrains Mono has no glyph for it, so
    # typing it produced a tofu box — a missing-glyph rectangle that the --check below cannot
    # detect, because a tofu box is not a flat image. Drawing it also means the mark matches the
    # app icon (two converging walls, a lit slot) instead of approximating it with punctuation.
    mark_w = draw_mark(d, margin, 150, 104)
    name_font, _ = fit_font(d, BRAND["name"], "Bold", W - 2 * margin - mark_w, 108, min_size=60)
    d.text((margin + mark_w + 34, 150), BRAND["name"], font=name_font, fill=hx(C["paper"]))

    draw_text_fit(d, (margin, 290), BRAND["tagline"], "Regular", W - 2 * margin, 44, hx(C["muted"]))

    hairline(d, margin, H - 110, W - margin)
    draw_text_fit(d, (margin, H - 90), BRAND["domain"], "Regular", W - 2 * margin, 30, hx(C["muted"]))

    path = os.path.join(OUT_DIR, "og.png")
    img.save(path)
    return path


def make_card(name, title, body):
    W, H = 1200, 675
    margin = 90
    img, d = new_canvas(W, H)

    # one accent mark per image: a short bar to the left of the title
    bar_top, bar_h = 200, 44
    d.rectangle([margin, bar_top, margin + 8, bar_top + bar_h], fill=hx(C["accent"]))

    draw_text_fit(d, (margin + 32, bar_top - 4), title, "Bold", W - 2 * margin - 32, 58, hx(C["paper"]))
    draw_text_fit(d, (margin + 32, bar_top + 70), body, "Regular", W - 2 * margin - 32, 34, hx(C["muted"]))

    hairline(d, margin, H - 90, W - margin)
    draw_text_fit(d, (margin, H - 70), BRAND["domain"], "Regular", 400, 26, hx(C["muted"]))

    path = os.path.join(OUT_DIR, f"card-{name}.png")
    img.save(path)
    return path


def make_quote(n, lead, rest):
    W = H = 1080
    margin = 100
    img, d = new_canvas(W, H)
    max_w = W - 2 * margin

    lead_font, lead_bbox = fit_font(d, lead, "Bold", max_w, 130, min_size=60)
    lead_h = lead_bbox[3] - lead_bbox[1]
    y = H // 2 - lead_h
    d.text((margin, y), lead, font=lead_font, fill=hx(C["accent"]))

    rest_font, rest_bbox = fit_font(d, rest, "SemiBold", max_w, 90, min_size=44)
    rest_h = rest_bbox[3] - rest_bbox[1]
    d.text((margin, y + lead_h + 40), rest, font=rest_font, fill=hx(C["paper"]))

    hairline(d, margin, H - 90, W - margin)
    draw_text_fit(d, (margin, H - 70), BRAND["domain"], "Regular", max_w, 26, hx(C["muted"]))

    path = os.path.join(OUT_DIR, f"quote-{n}.png")
    img.save(path)
    return path


def generate_all():
    os.makedirs(OUT_DIR, exist_ok=True)
    paths = [make_og()]
    for name, title, body in FEATURES:
        paths.append(make_card(name, title, body))
    for n, (lead, rest) in enumerate(QUOTES, start=1):
        paths.append(make_quote(n, lead, rest))
    return paths


def is_flat(path):
    with Image.open(path) as img:
        extrema = img.convert("RGB").getextrema()
    return all(lo == hi for lo, hi in extrema)


def expected_sizes():
    sizes = {os.path.join(OUT_DIR, "og.png"): (1200, 630)}
    for name, _, _ in FEATURES:
        sizes[os.path.join(OUT_DIR, f"card-{name}.png")] = (1200, 675)
    for n in range(1, len(QUOTES) + 1):
        sizes[os.path.join(OUT_DIR, f"quote-{n}.png")] = (1080, 1080)
    return sizes


def check():
    generate_all()
    failures = []
    for path, expected_wh in expected_sizes().items():
        if not os.path.exists(path):
            failures.append(f"missing: {path}")
            continue
        try:
            with Image.open(path) as img:
                if img.format != "PNG":
                    failures.append(f"not a PNG: {path} ({img.format})")
                if img.size != expected_wh:
                    failures.append(f"wrong size: {path} got {img.size} want {expected_wh}")
        except Exception as e:
            failures.append(f"unreadable: {path} ({e})")
            continue
        if is_flat(path):
            failures.append(f"flat/blank image: {path}")

    n = len(expected_sizes())
    if failures:
        print(f"CHECK FAILED — {len(failures)}/{n} outputs bad:")
        for line in failures:
            print(f"  - {line}")
        return False
    print(f"CHECK OK — {n}/{n} outputs present, correctly sized, non-flat.")
    return True


def demo():
    """Self-check for the pure helpers, no file I/O."""
    assert hx("#8FDB70") == (0x8F, 0xDB, 0x70)
    img = Image.new("RGB", (10, 10), (0, 0, 0))
    d = ImageDraw.Draw(img)
    font, bbox = fit_font(d, "Chute", "Bold", 400, 40)
    assert bbox[2] - bbox[0] <= 400
    print("demo OK")


if __name__ == "__main__":
    if "--check" in sys.argv:
        demo()
        sys.exit(0 if check() else 1)
    else:
        demo()
        out = generate_all()
        print(f"generated {len(out)} files in {OUT_DIR}")
