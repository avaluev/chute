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

/**
 * Text a visitor actually sees — PLUS the metadata a visitor never sees and a crawler always does.
 *
 * Stripping tags was the whole blind spot: on 2026-09-01 the site's own `<meta name="description">`
 * and OpenGraph description still sold `unpack`, a command deleted on 2026-08-31, and every check
 * in this file passed because all of them read `visible()` and `visible()` threw those away. That
 * string is what Google, an AI crawler and every shared link show — the highest-leverage sentence
 * on the site was the one sentence nothing checked.
 */
const metaText = (html) =>
  [...html.matchAll(/<meta[^>]+content="([^"]*)"/g)].map((m) => m[1]).join(" ")
  + " " + (html.match(/<title[^>]*>([\s\S]*?)<\/title>/)?.[1] ?? "")

const visible = (html) =>
  (html + " " + metaText(html))
    .replace(/<script[\s\S]*?<\/script>/g, " ")
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

// ── the Finder menu the site NAMES must be the menu the app DRAWS ───────────────────────────
// Every check above compares the site against a hand-maintained fact sheet, so it can only catch
// a claim someone already thought to forbid. That is exactly how /changelog kept advertising
// "copy files with contents", "paste an image from the clipboard" and "new markdown file" for a
// day after all three were renamed — three false claims, zero gate failures.
//
// So read the ACTION TABLE ITSELF. `chute finder-actions --json` is the same list the extension
// draws from, which makes this the only check here that cannot go stale on its own.
import { execFileSync } from "node:child_process"
const BIN = new URL("../../.build/release/chute", import.meta.url).pathname
let actions = null
try {
  actions = JSON.parse(execFileSync(BIN, ["finder-actions", "--json"], { encoding: "utf8" }))
} catch {
  bad("the Finder action table could not be read",
      `build it first: swift build -c release  (looked for ${BIN})`)
}
if (actions) {
  // Titles the app no longer has. A page naming one is describing a product that shipped.
  const live = new Set(actions.flatMap((a) => [a.title, a.parentTitle].filter(Boolean))
                              .map((t) => t.replace(/\s*\(\{n\}\)/, "").toLowerCase()))
  const RETIRED = ["copy files with contents", "write clipboard files here", "new file here",
                   "new clean room for an agent", "new markdown file from clipboard",
                   "paste image from clipboard", "new agent sandbox here"]
  const stale = []
  for (const [page, html] of HTML) {
    const text = visible(html).toLowerCase()
    for (const t of RETIRED) if (text.includes(t) && !live.has(t)) stale.push(`${page}: "${t}"`)
  }
  stale.length
    ? bad(`${stale.length} page(s) name a Finder action that no longer exists`, stale.join("; "))
    : ok(`no page names a retired Finder action (${live.size} live titles checked)`)
}

// ── EVERY `chute <command>` NAMED ANYWHERE MUST ACTUALLY RUN ────────────────────────────────
//
// The check above compares pages against a HAND-KEPT list of retired titles, which is why it
// passed on 2026-08-31 while README.md, the docs page, terms and commands.json all still told
// people to run `chute unpack` — a command deleted that morning. A list somebody has to remember
// to update is not a gate; it is a second place for the truth to live.
//
// Two decisions make this precise rather than noisy:
//
//   TRUTH = THE DISPATCH SWITCH, not `chute help`. `buf` (a kept alias), `finder-actions` and
//   `paste-image` (internal, driven by the Finder extension) all really work and are deliberately
//   absent from help. Checking against help would have called three working commands ghosts.
//
//   SCOPE = CODE SPANS ONLY. `chute command-line tool`, `chute production signing` and
//   `chute licence key` are English sentences, not invocations. Matching prose produced eleven
//   false positives on the first run. Only `backticked` markdown and <code> in HTML count.
const MAIN = readFileSync(new URL("../../Sources/chute/main.swift", import.meta.url).pathname, "utf8")
// Every quoted name on every `case` line. The first version required all names on a line to be
// bare words, so `case "help", "-h", "--help", ...:` matched nothing and `chute help` — the most
// documented command in the product — was reported as a ghost.
const known = new Set([...MAIN.matchAll(/^case ([^:\n]+):/gm)]
  .flatMap((m) => [...m[1].matchAll(/"([a-z][a-z-]*)"/g)].map((x) => x[1])))

const spans = []
for (const [page, html] of HTML) {
  for (const m of html.matchAll(/<code[^>]*>([\s\S]*?)<\/code>/g)) spans.push([page, visible(m[1])])
}
const REPO = new URL("../../", import.meta.url).pathname
const md = [["README.md", readFileSync(REPO + "README.md", "utf8")]]
// Two files describe things that are deliberately NOT the shipped product:
//   06-BACKLOG.md    names commands nobody has built — that is what a backlog is.
//   11-PHASE-0-RUNBOOK.md  is ops prose about Paddle and Apple, where `chute licence minting`
//                          is a product-description FIELD and `chute notarytool` is a sentence.
// Both produced only false alarms, and a gate that cries wolf is one people learn to ignore.
const NOT_THE_PRODUCT = new Set(["06-BACKLOG.md", "11-PHASE-0-RUNBOOK.md"])
for (const f of readdirSync(REPO + "docs")) {
  if (f.endsWith(".md") && !NOT_THE_PRODUCT.has(f)) {
    md.push([`docs/${f}`, readFileSync(REPO + "docs/" + f, "utf8")])
  }
}
// marketing/ WAS NOT SCANNED until 2026-09-01, and that is the whole reason five assets — the
// positioning, the landing copy, the launch posts, the demo script and the calendar — still sold
// `chute unpack` a day after it was deleted, with every gate green. The launch material is a
// place a claim reaches a stranger; it belongs inside the gate, not beside it.
for (const f of readdirSync(REPO + "marketing")) {
  if (f.endsWith(".md")) md.push([`marketing/${f}`, readFileSync(REPO + "marketing/" + f, "utf8")])
}
for (const [where, text] of md) {
  for (const m of text.matchAll(/`([^`\n]+)`/g)) spans.push([where, m[1]])
  for (const m of text.matchAll(/```[a-z]*\n([\s\S]*?)```/g)) spans.push([where, m[1]])
}

const ghosts = new Set()
for (const [where, code] of spans) {
  for (const m of code.matchAll(/\bchute ([a-z][a-z-]{2,})\b/g)) {
    if (!known.has(m[1])) ghosts.add(`${where}: "chute ${m[1]}"`)
  }
}
ghosts.size
  ? bad(`${ghosts.size} place(s) show a chute command that does not exist`, [...ghosts].join("; "))
  : ok(`every documented chute command is in the dispatch (${known.size} live)`)

// ── every LinkedIn hook must be under the truncation limit, and must say its own real length ─
// LinkedIn truncates at ~140 characters on mobile: past that the first line — the only line most
// people read — is cut mid-sentence. marketing/08-LINKEDIN.md states a character count beside
// every hook, and on the day it was written TEN OF TWELVE were wrong, because they were counted
// by eye. A number in a document with no command behind it is a number that is already drifting.
{
  const linkedin = readFileSync(REPO + "marketing/08-LINKEDIN.md", "utf8")
  const hooks = [...linkedin.matchAll(/\*\*HOOK\*\* \((\d+)\)\n> (.+)/g)]
  const wrong = hooks.filter(([, n, text]) => Number(n) !== text.trim().length)
    .map(([, n, text]) => `"${text.trim().slice(0, 30)}…" says ${n}, is ${text.trim().length}`)
  const tooLong = hooks.filter(([, , text]) => text.trim().length > 140)
    .map(([, , text]) => `"${text.trim().slice(0, 30)}…" is ${text.trim().length}`)
  if (!hooks.length) bad("the LinkedIn hooks were read", "no **HOOK** (n) blocks found — has the format changed?")
  if (wrong.length) bad(`${wrong.length} LinkedIn hook(s) state the wrong length`, wrong.join("; "))
  if (tooLong.length) bad(`${tooLong.length} LinkedIn hook(s) exceed the 140-char mobile cut`, tooLong.join("; "))
  if (hooks.length && !wrong.length && !tooLong.length) {
    ok(`${hooks.length} LinkedIn hooks are under 140 chars and count themselves honestly`)
  }
}

// ── the changelog's newest entry must be the version that actually ships ────────────────────
// A changelog is the one page whose whole job is being current, and it is hand-maintained on
// purpose (see the comment on that page). So this asks Version.swift — the single source the app
// bundle, the DMG and `chute --version` all read — whether the top entry is the shipping build.
// Caught within a minute of being introduced on 2026-09-01: the changelog was written for 0.2.1
// while Version.swift still said 0.2.0.
{
  const version = readFileSync(REPO + "Sources/ChuteCore/Version.swift", "utf8")
    .match(/static let current = "([^"]+)"/)?.[1]
  const newest = readFileSync(REPO + "site/src/app/changelog/page.tsx", "utf8")
    .match(/version: "([^"]+)"/)?.[1]
  if (!version || !newest) bad("the version and the changelog were both read", `Version.swift=${version} changelog=${newest}`)
  else if (version !== newest) {
    bad("the changelog's newest entry is not the shipping version",
        `Version.swift says ${version}, the changelog's top entry is ${newest}`)
  } else ok(`the changelog's newest entry is ${newest}, the shipping version`)
}

// ── the sitemap must cover the site that was actually built ─────────────────────────────────
// `sitemap.ts` derives the 19 case URLs from CASES, but its list of STATIC routes is hand-typed —
// so a new page under src/app is invisible to every crawler until someone remembers. This asks
// the BUILD OUTPUT instead: every rendered page must be in the sitemap, and every sitemap entry
// must be a page that exists. Neither half can rot without going red.
try {
  const xml = readFileSync(join(OUT, "sitemap.xml"), "utf8")
  const listed = new Set([...xml.matchAll(/<loc>([^<]+)<\/loc>/g)]
    .map((m) => m[1].replace(/^https?:\/\/[^/]+/, "")))
  const built = HTML.map(([p]) => p.replace(/index\.html$/, ""))
    // Next renders its own 404 at /_not-found/; a sitemap must never advertise an error page.
    .filter((p) => !p.startsWith("/404") && !p.startsWith("/_not-found"))
  const missing = built.filter((p) => !listed.has(p))
  const phantom = [...listed].filter((p) => !built.includes(p))
  if (missing.length) bad(`${missing.length} built page(s) are not in sitemap.xml`, missing.join(", "))
  if (phantom.length) bad(`${phantom.length} sitemap entr(ies) point at nothing`, phantom.join(", "))
  if (!missing.length && !phantom.length) ok(`sitemap.xml covers all ${built.length} built pages`)
} catch { bad("sitemap.xml was read", "not found in out/ — is `next build` current?") }

console.log(`\nclaims: ${failed ? `${failed} failed` : "every claim on the site is one the fact sheet stands behind"}`)
process.exit(failed ? 1 : 0)
