#!/usr/bin/env node
// brand/tokens.json → demo/chute.theme.json, the terminal palette every recorded demo uses.
// Run via `make -C brand`. Never hand-edit the output.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const t = JSON.parse(readFileSync(join(here, "tokens.json"), "utf8"));
const c = t.color;
const [red, orange, yellow, green, cyan, blue, violet, magenta] = t.sessionHues;

// The demo terminal IS the product's colour, so a GIF dropped into a README or a tweet reads as
// Chute before a word is read. Background and accent come straight from the icon.
const theme = {
  background: c.ground900.hex,
  foreground: c.paper.hex,
  cursor: c.accentGlow.hex,
  selection: c.ground600.hex,
  black: c.ground800.hex,
  red, green: c.accent.hex, yellow, blue, magenta: violet, cyan, white: c.paper.hex,
  brightBlack: c.muted.hex,
  brightRed: red, brightGreen: c.accentGlow.hex, brightYellow: yellow,
  brightBlue: blue, brightMagenta: magenta, brightCyan: cyan, brightWhite: "#FFFFFF",
};

const demo = join(here, "..", "demo");
writeFileSync(join(demo, "chute.theme.json"), JSON.stringify(theme, null, 2) + "\n");

// Every tape opens with `Source _common.tape`, so the look of all twelve demos is decided here
// and nowhere else. Sizes are chosen so a GIF stays legible when a timeline scales it to ~600px.
const common = `# GENERATED from brand/tokens.json by brand/gen-vhs-theme.mjs — do not edit.
# The look of all twelve demos is decided here and nowhere else.
Set Theme ${JSON.stringify(theme)}
Set FontFamily "${t.font.mono.split(",")[0].replace(/'/g, "")}"
Set FontSize 20
Set Width 1200
Set Height 640
Set Padding 30
Set Margin 26
Set MarginFill "${c.ground900.hex}"
Set BorderRadius 10
Set TypingSpeed 55ms
Set Shell "bash"
`;
writeFileSync(join(demo, "common.tape"), common);
console.log("demo/chute.theme.json + demo/common.tape ← brand/tokens.json");
