#!/usr/bin/env node
// brand/tokens.json → site/src/app/brand.css
//
// The trick, and the whole reason this file exists: shadcn's SEMANTIC tokens are good
// (--primary, --card, --border), but its default VALUES — neutral oklch greys, Geist, a 0.625rem
// radius — are the templated look everyone recognises. So keep the contract and repaint it.
// Every shadcn component then arrives on-brand with no per-component edits, and the green in a
// tweet is the green in the menu bar because both read this same JSON.
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const t = JSON.parse(readFileSync(join(here, "tokens.json"), "utf8"));
const c = t.color;

const css = `/* GENERATED from brand/tokens.json by brand/gen-tailwind.mjs — do not edit.
   Imported by globals.css AFTER shadcn's own variables, so these win. */

/* Chute's raw palette, for the few places that want the colour itself. */
@theme {
  --color-ground-900: ${c.ground900.hex};
  --color-ground-800: ${c.ground800.hex};
  --color-ground-600: ${c.ground600.hex};
  --color-accent-chute: ${c.accent.hex};
  --color-glow: ${c.accentGlow.hex};
  --color-paper: ${c.paper.hex};
${t.sessionHues.map((h, i) => `  --color-session-${i + 1}: ${h};`).join("\n")}
}

/* shadcn's contract, repainted. Dark only, deliberately: the product is a dark menu-bar
   utility, and a light landing page for a dark tool is a promise the app does not keep. */
:root {
  --background: ${c.ground900.hex};
  --foreground: ${c.paper.hex};
  --card: ${c.ground800.hex};
  --card-foreground: ${c.paper.hex};
  --popover: ${c.ground800.hex};
  --popover-foreground: ${c.paper.hex};

  /* The one accent. Dark text ON the green, never green text on dark for a button. */
  --primary: ${c.accent.hex};
  --primary-foreground: ${c.ground900.hex};

  --secondary: ${c.ground800.hex};
  --secondary-foreground: ${c.paper.hex};
  --muted: ${c.ground800.hex};
  --muted-foreground: ${c.muted.hex};
  --accent: ${c.ground600.hex};
  --accent-foreground: ${c.paper.hex};
  --destructive: ${c.danger.hex};
  --destructive-foreground: ${c.paper.hex};

  --border: ${c.ground600.hex};
  --input: ${c.ground600.hex};
  --ring: ${c.accentGlow.hex};

  /* Dev tools are sharp. shadcn ships 0.625rem; that roundness is half of the templated look. */
  --radius: ${t.radius};

  --font-sans: ${t.font.body};
  --font-mono: ${t.font.mono};
  --font-heading: ${t.font.heading};
  --font-geist-mono: ${t.font.mono};
}

@theme inline {
  --shadow-hero: ${t.shadow};
}
`;

writeFileSync(join(here, "..", "site", "src", "app", "brand.css"), css);
console.log("site/src/app/brand.css ← brand/tokens.json");
