#!/usr/bin/env node
/**
 * The fact sheet, enforced.
 *
 * marketing/06-FACT-SHEET.md ends with a table headed "Claims that are currently FALSE and must
 * not be used". That table exists because three false claims reached the live site — "328 KB"
 * when the app is 2.5 MB, "28 commands" when there are 25, and "Nothing is uploaded, ever" when
 * `gist` uploads on request. A rule a human has to remember gets broken; this one cannot be.
 *
 * Run against the BUILT site, so it sees what a visitor sees rather than what the source says.
 *   node scripts/check-claims.mjs        (wired into Scripts/deploy-site.sh)
 */
import { readFileSync, readdirSync, statSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, resolve, join } from "node:path"
import { CONFIG } from "../src/lib/config.ts"

const here = dirname(fileURLToPath(import.meta.url))
const OUT = resolve(here, "../out")
const SHEET = resolve(here, "../../marketing/06-FACT-SHEET.md")

let failed = 0
const ok = (m) => console.log(`  ok    ${m}`)
const bad = (m, d) => { failed++; console.log(`  FAIL  ${m}\n        ${d}`) }

// ── every rendered page ─────────────────────────────────────────────────────────────────────
function pages(dir, acc = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name)
    if (statSync(p).isDirectory()) pages(p, acc)
    else if (name.endsWith(".html")) acc.push(p)
  }
  return acc
}
let HTML
try { HTML = pages(OUT).map((p) => [p.replace(OUT, "") || "/", readFileSync(p, "utf8")]) }
catch { console.error("check-claims: no built site — run `npx next build` first"); process.exit(1) }
ok(`${HTML.length} rendered pages read`)

/** Text a visitor actually sees: tags stripped, entities unescaped, whitespace collapsed. */
const visible = (html) =>
  html.replace(/<script[\s\S]*?<\/script>/g, " ")
      .replace(/<[^>]+>/g, " ")
      .replace(/&#x27;|&apos;/g, "'").replace(/&quot;/g, '"')
      .replace(/&amp;/g, "&").replace(/&mdash;/g, "—").replace(/&nbsp;/g, " ")
      .replace(/\s+/g, " ")

// ── the FALSE table, parsed from the fact sheet rather than copied out of it ────────────────
// Copying the list here would be a second source of truth, which is the failure this whole file
// is about. The sheet is the source; if a row is added there it is enforced here on the next run.
const sheet = readFileSync(SHEET, "utf8")
const tail = sheet.slice(sheet.indexOf("## Claims that are currently FALSE"))
const FALSE_CLAIMS = [...tail.matchAll(/^\|\s*"([^"]+)"[^|]*\|/gm)].map((m) => m[1])
FALSE_CLAIMS.length >= 3
  ? ok(`${FALSE_CLAIMS.length} forbidden claims read from the fact sheet`)
  : bad("the fact sheet's FALSE table parsed", `found ${FALSE_CLAIMS.length} rows — has the table changed shape?`)

for (const claim of FALSE_CLAIMS) {
  const hits = HTML.filter(([, html]) => visible(html).toLowerCase().includes(claim.toLowerCase()))
  if (hits.length) {
    bad(`"${claim}" is on the live site`,
        `${hits.length} page(s): ${hits.map(([p]) => p).join(", ")} — see the FALSE table in marketing/06-FACT-SHEET.md`)
  }
}
if (!failed) ok("no forbidden claim appears on any page")

// ── banned words ────────────────────────────────────────────────────────────────────────────
const BANNED = (sheet.match(/^\*(seamless[^*]+)\*$/m)?.[1] ?? "")
  .split("·").map((w) => w.trim()).filter(Boolean)
for (const word of BANNED) {
  const re = new RegExp(`\\b${word.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")}\\b`, "i")
  const hits = HTML.filter(([, html]) => re.test(visible(html)))
  if (hits.length) bad(`the word "${word}" is on the live site`, hits.map(([p]) => p).join(", "))
}
BANNED.length ? ok(`${BANNED.length} banned words checked`) : bad("banned word list parsed", "none found in the fact sheet")

// ── the install command must not be printed before it works ─────────────────────────────────
// This is the one claim the fact sheet cannot check by string alone: `brew install …` is correct
// copy the day the tap exists and a broken promise the day before. CONFIG.brewLive is the switch.
const brewPages = HTML.filter(([, html]) => visible(html).includes("brew install"))
if (CONFIG.brewLive) {
  brewPages.length
    ? ok("brewLive is true and the install command is published")
    : bad("brewLive is true but no page shows it", "flip it back, or put the command back on /cli")
} else if (brewPages.length) {
  bad(`brewLive is false but "brew install" is on ${brewPages.length} page(s)`,
      `${brewPages.map(([p]) => p).join(", ")} — the tap does not exist; a visitor who pastes that gets an error`)
} else {
  ok("brewLive is false and no page tells anyone to run brew")
}

console.log(`\nclaims: ${failed ? `${failed} failed` : "every claim on the site is one the fact sheet stands behind"}`)
process.exit(failed ? 1 : 0)
