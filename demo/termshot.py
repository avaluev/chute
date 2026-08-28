#!/usr/bin/env python3
"""
The terminal, drawn rather than photographed.

WHY NOT screencapture. Every GUI recording in demo/gui/ costs a human, a granted Screen Recording
permission, an exclusive screen and a machine nobody touches for the length of a take — and it
comes out at whatever the display happened to be, with whatever the terminal's font and theme
happened to be that day. For the CLI half none of that buys anything: `chute` writes plain text
(zero ANSI escapes in its whole output, checked), so a photograph of a terminal is a lossy picture
of a string we already have.

WHY NOT `freeze`, `silicon`, `carbon` or `termshot`. They are good tools and they render in THEIR
theme. demo/gui/overlay.py already settled this argument for captions: it draws with JetBrains Mono
and the exact colours from brand/tokens.json, because "a demo captioned in Helvetica grey is a demo
that looks like it came from somewhere else". The same is true of a promo frame. This is ~200 lines
and it owns the palette, the radius and the font that the icon, the site and the app all read.

WHAT IT GIVES YOU that a recording cannot:
  · pixel-identical output for identical input — no timing, no cursor, no flake
  · any resolution, crisp, because the text is drawn at scale rather than upscaled
  · it runs with no screen and no permissions, so it belongs in CI

THE OUTPUT IS REAL. The command is EXECUTED and its actual stdout/stderr is what gets drawn. This
repo shipped a GIF of the product failing once (see demo/verify.sh); a renderer that let you type
the output by hand would be a machine for doing that on purpose.

  python3 demo/termshot.py still  --cmd "chute tokens Package.swift" --out out/still/tokens.png
  python3 demo/termshot.py frames --cmd "chute tokens Package.swift" --outdir out/frames/tokens
"""
import argparse, json, os, shutil, subprocess, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.abspath(__file__))
TOKENS = json.load(open(os.path.join(ROOT, "..", "brand", "tokens.json")))
C = {k: v["hex"] for k, v in TOKENS["color"].items()}

# 2x everywhere, then the caller downsamples or uses it as a Retina asset. Drawing small and
# scaling up is how a "crisp" terminal shot ends up looking like a screenshot of a screenshot.
SCALE     = 2
FONT_PT   = 13 * SCALE
LINE      = 20 * SCALE
PAD       = 22 * SCALE
RADIUS    = 8 * SCALE          # the window, not the 4px UI radius: this is a chrome corner
BAR       = 34 * SCALE         # title bar height
COLS      = 88                 # wrap width, in characters

FONT_DIR = os.path.expanduser("~/Library/Fonts")
def font(weight="Regular", pt=FONT_PT):
    path = os.path.join(FONT_DIR, f"JetBrainsMono-{weight}.ttf")
    if not os.path.exists(path):
        sys.exit(f"termshot: missing {path} — the brand font is not optional, see brand/tokens.json")
    return ImageFont.truetype(path, pt)


def run(cmd, cwd):
    """Execute for real and keep exactly what came out, in order."""
    p = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    body = (p.stdout or "") + (p.stderr or "")
    return body.rstrip("\n").split("\n") if body.strip() else [], p.returncode


def wrap(lines, cols=COLS):
    out = []
    for ln in lines:
        while len(ln) > cols:
            out.append(ln[:cols]); ln = ln[cols:]
        out.append(ln)
    return out


def draw(cmd, out_lines, prompt, path, typed=None, revealed=None, max_rows=22):
    """One frame. `typed` truncates the command; `revealed` truncates the output."""
    shown_cmd = cmd if typed is None else cmd[:typed]
    shown_out = out_lines if revealed is None else out_lines[:revealed]

    # THE WINDOW IS A FIXED SIZE AND THE TEXT SCROLLS INSIDE IT, exactly like a terminal.
    #
    # Sizing the frame to the full output keeps an animation from jumping — but `chute bundle`
    # prints sixty lines, so every frame of the typing phase was a screenful of empty navy with
    # one line at the top. Capping the rows and showing the LAST ones as they arrive is both
    # bounded and what a terminal actually does.
    rows = min(1 + len(out_lines), max_rows)
    w = PAD * 2 + int(COLS * FONT_PT * 0.6)
    h = BAR + PAD * 2 + rows * LINE
    if len(shown_out) > rows - 1:
        shown_out = shown_out[len(shown_out) - (rows - 1):]

    img = Image.new("RGB", (w, h), C["ground900"])
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 1, h - 1], radius=RADIUS, fill=C["ground800"],
                        outline=C["ground600"], width=SCALE)
    d.line([(0, BAR), (w, BAR)], fill=C["ground600"], width=SCALE)
    d.text((PAD, BAR // 2), prompt, font=font("Regular", int(FONT_PT * 0.85)),
           fill=C["muted"], anchor="lm")

    y = BAR + PAD
    # "$", not "❯". JetBrains Mono has no U+276F and PIL silently substituted ")" — a prompt
    # glyph that renders as a stray bracket is the kind of detail that makes a promo image look
    # like a mistake. "$" is in every monospace font ever shipped and reads as a shell to everyone.
    d.text((PAD, y), "$", font=font("Bold"), fill=C["accent"])
    d.text((PAD + int(1.2 * FONT_PT), y), shown_cmd, font=font("Bold"), fill=C["paper"])
    if typed is not None and typed < len(cmd):     # a caret, only while typing
        caret_x = PAD + int(1.2 * FONT_PT) + int(len(shown_cmd) * FONT_PT * 0.6)
        d.rectangle([caret_x, y + 2, caret_x + int(FONT_PT * 0.55), y + LINE - 4], fill=C["accent"])

    for i, ln in enumerate(shown_out):
        colour = C["muted"] if ln.startswith(("→", "·")) else C["paper"]
        if ln.startswith("chute:") or "FAIL" in ln: colour = C["danger"]
        d.text((PAD, y + (i + 1) * LINE), ln, font=font("Regular"), fill=colour)

    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    img.save(path)
    return img.size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["still", "frames"])
    ap.add_argument("--cmd", required=True)
    ap.add_argument("--cwd", default=os.path.expanduser("~/Desktop/acme-app"))
    ap.add_argument("--prompt", default="acme-app")
    ap.add_argument("--out")
    ap.add_argument("--outdir")
    ap.add_argument("--fps", type=int, default=20)
    ap.add_argument("--max-rows", type=int, default=22,
                    help="visible lines; longer output scrolls, as it would in a terminal")
    ap.add_argument("--allow-failure", action="store_true",
                    help="draw the frame even if the command exited non-zero")
    a = ap.parse_args()

    lines, code = run(a.cmd, a.cwd)
    if code != 0 and not a.allow_failure:
        sys.exit(f"termshot: `{a.cmd}` exited {code} — refusing to render a failure as promotion.\n"
                 f"          Fix the command, or pass --allow-failure if the failure IS the point.\n"
                 + "\n".join("          " + l for l in lines[:8]))
    lines = wrap(lines)

    if a.mode == "still":
        out = a.out or "out/still/shot.png"
        print(f"  {out}  {draw(a.cmd, lines, a.prompt, out, max_rows=a.max_rows)}")
        return

    outdir = a.outdir or "out/frames/shot"
    shutil.rmtree(outdir, ignore_errors=True)
    os.makedirs(outdir, exist_ok=True)
    n = 0
    def frame(**kw):
        nonlocal n
        draw(a.cmd, lines, a.prompt, os.path.join(outdir, f"{n:04d}.png"), max_rows=a.max_rows, **kw)
        n += 1

    # Typing, then a beat, then the output arriving a line at a time, then a hold to read it.
    # Three characters per frame: one is unreadably slow at 20 fps and looks like a stutter.
    for i in range(0, len(a.cmd) + 1, 3): frame(typed=i, revealed=0)
    for _ in range(a.fps // 3):           frame(typed=None, revealed=0)
    for i in range(1, len(lines) + 1):    frame(typed=None, revealed=i)
    for _ in range(a.fps * 2):            frame(typed=None, revealed=len(lines))
    print(f"  {outdir}  {n} frames @ {a.fps}fps  ({n / a.fps:.1f}s)")


if __name__ == "__main__":
    main()
