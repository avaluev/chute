#!/usr/bin/env python3
"""
Every pixel of text that goes onto a recording, rendered here.

WHY NOT ffmpeg's drawtext: the ffmpeg on this machine is built without it, and that was found by
testing the filtergraph rather than at recording time with a human sitting in front of the
screen. Rendering with PIL is also strictly better — it uses JetBrains Mono and the exact colours
from brand/tokens.json, the same four-surface palette the app icon, the site and the terminal
demos read. A demo captioned in Helvetica grey is a demo that looks like it came from somewhere
else.

  python3 overlay.py labels  OUT  --left "By hand" --right "With Chute"
  python3 overlay.py clock   OUT  --manual 95.2 --chute 4.8 --seconds 14

`clock` emits one PNG per second so the count can tick without drawtext: ffmpeg reads the
directory as an image sequence at 1 fps and overlays it as a single input.
"""
import argparse, json, os, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
TOKENS = json.load(open(os.path.join(HERE, "..", "..", "brand", "tokens.json")))
C = {k: v["hex"] for k, v in TOKENS["color"].items()}
FONT_DIR = os.path.expanduser("~/Library/Fonts")


def font(weight, size):
    """Never a silent system-font swap: a caption in the wrong face is worse than a crash here,
    because it ships looking almost right."""
    path = os.path.join(FONT_DIR, f"JetBrainsMono-{weight}.ttf")
    if not os.path.exists(path):
        sys.exit(f"overlay: missing {path} — the brand face is not installed")
    return ImageFont.truetype(path, size)


def rgba(hex_, alpha=255):
    h = hex_.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def labels(out, width, height, left, right, note):
    """The bar above the race. It carries the disclosure, because the artifact has to be able to
    explain itself when it is reposted without the page around it."""
    img = Image.new("RGBA", (width, height), rgba(C["ground900"]))
    d = ImageDraw.Draw(img)
    half = width // 2
    d.text((40, 18), left, font=font("SemiBold", 30), fill=rgba(C["muted"]))
    d.text((half + 40, 18), right, font=font("SemiBold", 30), fill=rgba(C["accent"]))
    # The hairline that makes it read as two panels rather than one wide window.
    d.rectangle([half - 1, 0, half + 1, height], fill=rgba(C["ground600"]))
    d.text((width - 40 - d.textlength(note, font=font("Regular", 18)), 24), note,
           font=font("Regular", 18), fill=rgba(C["ground600"]))
    img.save(out)


def clock(outdir, width, height, manual_total, chute_total, seconds):
    """One frame per second. The right-hand clock STOPS at the moment the job really finished and
    shows a check; the left keeps counting. The last frame states how much of the manual run you
    are not being shown — the video is short, the measurement is not, and the difference is
    exactly the thing a viewer would otherwise be right to suspect."""
    os.makedirs(outdir, exist_ok=True)
    half = width // 2
    base = height - 120          # clear of the bottom edge; 44px glyphs were clipping at -90
    for t in range(seconds + 1):
        img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        big = font("Bold", 44)

        # The divider runs the FULL height, not just the label bar. Without it the two panels
        # read as one impossibly wide window rather than as two recordings.
        d.rectangle([half - 1, 0, half + 1, height], fill=rgba(C["ground600"], 220))

        # A plate behind each clock: these sit over a live recording, and white-on-whatever is
        # unreadable the moment the Finder window under it happens to be light.
        def plate(x, w=210):
            d.rectangle([x - 16, base - 14, x + w, base + 58], fill=rgba(C["ground900"], 215))

        plate(40)
        d.text((40, base), f"{t}.0s", font=big, fill=rgba(C["paper"]))

        if t < chute_total:
            plate(half + 40)
            d.text((half + 40, base), f"{t}.0s", font=big, fill=rgba(C["paper"]))
        else:
            plate(half + 40, 330)
            d.text((half + 40, base), f"{chute_total}s  done",
                   font=big, fill=rgba(C["accentGlow"]))

        if t == seconds:
            remaining = max(0, round(manual_total - t))
            txt = f"still going — {remaining}s left"
            w = d.textlength(txt, font=font("Regular", 26))
            d.rectangle([24, base - 66, 56 + w, base - 22], fill=rgba(C["ground900"], 215))
            d.text((40, base - 58), txt, font=font("Regular", 26), fill=rgba(C["danger"]))
        img.save(os.path.join(outdir, f"{t:03d}.png"))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("mode", choices=["labels", "clock"])
    p.add_argument("out")
    p.add_argument("--width", type=int, default=1920)
    p.add_argument("--height", type=int, default=660)
    p.add_argument("--left", default="By hand")
    p.add_argument("--right", default="With Chute")
    p.add_argument("--note", default="two real recordings, aligned at their start")
    p.add_argument("--manual", type=float, default=95.0)
    p.add_argument("--chute", type=float, default=5.0)
    p.add_argument("--seconds", type=int, default=14)
    a = p.parse_args()
    if a.mode == "labels":
        labels(a.out, a.width, 60, a.left, a.right, a.note)
    else:
        clock(a.out, a.width, a.height, a.manual, a.chute, a.seconds)
    print(a.out)
