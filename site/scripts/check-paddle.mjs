#!/usr/bin/env node
/**
 * Paddle domain-review gate. Run against the BUILT site, before submitting the domain.
 *
 *   cd site && npm run build && npm run check:paddle
 *
 * WHY THIS IS WORTH THE FILE. Paddle's domain review is pass/fail and a rejection costs 5–7
 * business days on resubmission. The documented failure modes are dull and entirely mechanical:
 * a 404 on the refund policy, a policy that exists but is not linked from navigation, a terms
 * page that never names the seller. Every one of those is checkable, so none of them should ever
 * be discovered by a reviewer.
 *
 * Checklist source: paddle.com/help/start/account-verification/what-is-domain-verification
 */
import { readFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const site = join(dirname(fileURLToPath(import.meta.url)), "..");
const out = join(site, "out");

let failed = 0;
const ok = (m) => console.log(`  ok    ${m}`);
const bad = (m, detail = "") => { console.error(`  FAIL  ${m}${detail ? `\n        ${detail}` : ""}`); failed++; };

if (!existsSync(out)) {
  console.error("check-paddle: site/out does not exist — run `npm run build` first");
  process.exit(1);
}

// The site may be built with a base path (a GitHub project page) or without one (the custom
// domain). The reviewer only ever sees the custom domain, but this check must pass in both
// builds or it stops being run — so read the prefix out of the build rather than assuming.
const BASE = (() => {
  const index = join(out, "index.html");
  if (!existsSync(index)) return "";
  const m = readFileSync(index, "utf8").match(/href="(\/[\w-]+)\/_next\//);
  return m ? m[1] : "";
})();
if (BASE) console.log(`  (built with basePath "${BASE}" — the project-page build)`);

const html = (route) => {
  const p = route === "/" ? join(out, "index.html") : join(out, route.replace(/^\//, ""), "index.html");
  return existsSync(p) ? readFileSync(p, "utf8") : null;
};

// 1 — every page the reviewer looks for must exist. A 404 here is a documented direct fail.
console.log("\n1. Required pages exist");
const REQUIRED = ["/", "/buy", "/terms", "/refunds", "/privacy", "/support", "/docs"];
const pages = {};
for (const route of REQUIRED) {
  const body = html(route);
  if (body) { pages[route] = body; ok(`${route} → 200`); }
  else bad(`${route} → 404`, "Paddle's checklist requires this reachable over HTTPS");
}

// 2 — "clearly accessible via navigation". Findable, not merely present: a policy three clicks
// deep fails. Every page's footer must carry all three legal links.
console.log("\n2. Legal pages are reachable from navigation on every page");
for (const [route, body] of Object.entries(pages)) {
  const missing = ["/terms", "/refunds", "/privacy"].filter((l) => !body.includes(`href="${BASE}${l}`));
  if (missing.length) bad(`${route} footer is missing ${missing.join(", ")}`);
}
if (!failed) ok("every page links to /terms, /refunds and /privacy");

// 3 — "Include the company name or sole proprietor's brand (legal name preferred) in the Terms."
console.log("\n3. The seller is named in the Terms");
const terms = pages["/terms"] ?? "";
for (const needle of ["IE Valuev Aleksandr Aleksandrovich", "Bishkek", "Kyrgyz Republic", "Paddle.com Market Ltd"]) {
  terms.includes(needle) ? ok(`terms names "${needle}"`) : bad(`terms does not name "${needle}"`);
}
terms.includes('id="seller"') ? ok("terms has a #seller anchor") : bad("terms has no #seller anchor");

// 4 — an unstated refund policy is a documented rejection cause.
console.log("\n4. The refund policy states a concrete window");
const refunds = pages["/refunds"] ?? "";
/\b30\b/.test(refunds) ? ok("refunds page states a 30-day window") : bad("refunds page states no window");
terms.includes('id="refunds"') ? ok("terms carries the policy at #refunds") : bad("terms has no #refunds section");
refunds.includes("Paddle.com Market Ltd") ? ok("refunds names the merchant of record") : bad("refunds does not name the merchant of record");

// 5 — "A clear description of your product" and "Pricing details".
console.log("\n5. Product and price are described");
const home = pages["/"] ?? "";
home.includes("$19") ? ok("home states the price") : bad("home does not state the price");
/14[\s-]day/i.test(home) ? ok("home states the trial length") : bad("home does not state the trial length");
(pages["/docs"] ?? "").includes("chute bundle") ? ok("docs lists the deliverables") : bad("docs does not list what is included");

// 6 — the default payment link must be able to HOST a checkout, not merely exist. Paddle
// redirects buyers to it with ?_ptxn=txn_… for invoices, card updates and API-opened checkouts.
console.log("\n6. /buy can host a Paddle-redirected checkout");
// The handler is in a client chunk, not the pre-rendered HTML, so look in the JS the page loads.
const buyChunks = [...(pages["/buy"] ?? "").matchAll(/\/_next\/static\/chunks\/[\w./-]+\.js/g)].map((m) => m[0]);
const buyJs = buyChunks
  .map((c) => join(out, c))
  .filter(existsSync)
  .map((f) => readFileSync(f, "utf8"))
  .join("");
buyJs.includes("_ptxn")
  ? ok(`/buy handles the ?_ptxn= redirect (found in ${buyChunks.length} loaded chunks)`)
  : bad("/buy does not handle ?_ptxn=", "set it as the default payment link and buyers land on a page with no checkout");

// 6b — the OG image must EXIST. It was referenced in metadata and absent from public/, so every
// link shared into X, Slack or iMessage rendered a blank card — invisible in the build output,
// obvious the moment anyone shares the launch post.
console.log("\n6b. Social preview image");
const ogRef = [...Object.values(pages).join("").matchAll(/content="[^"]*?(\/media\/og\.png)"/g)][0];
if (!ogRef) bad("no og:image declared");
else existsSync(join(out, "media", "og.png"))
  ? ok("og:image is declared and the file exists")
  : bad("og:image is declared but the file is missing", "every shared link renders a blank card");

// 6c — every asset a page references must EXIST at the path it references.
// next/image with `unoptimized` bypasses the loader that applies basePath, so image srcs
// silently resolved to the domain root while every link and stylesheet resolved correctly.
// A page that is right apart from having no images survives a glance; it does not survive a
// reviewer.
console.log("\n6c. Every referenced asset resolves");
const refs = new Set();
for (const body of Object.values(pages)) {
  for (const m of body.matchAll(/(?:src|href)="(\/[^"]+\.(?:png|gif|jpg|jpeg|svg|webp|css|js|woff2?))"/g)) {
    refs.add(m[1]);
  }
}
const broken = [...refs].filter((r) => !existsSync(join(out, r.replace(BASE, "").replace(/^\//, ""))));
broken.length
  ? bad(`${broken.length} referenced asset(s) 404`, broken.slice(0, 5).join("\n        "))
  : ok(`all ${refs.size} referenced assets exist on disk`);

// 7 — a custom domain over HTTPS.
console.log("\n7. Custom domain");
const cname = join(out, "CNAME");
if (BASE) console.log("  note: a basePath build cannot be the reviewed site — remove PAGES_BASE_PATH once chutedev.com resolves");
existsSync(cname) && readFileSync(cname, "utf8").trim() === "chutedev.com"
  ? ok("CNAME → chutedev.com")
  : bad("CNAME missing or wrong", "GitHub Pages will not serve the custom domain");

// 8 — nothing unfinished may reach a reviewer.
console.log("\n8. No placeholder text shipped");
const PLACEHOLDERS = ["REPLACE_ME", "TODO", "FIXME", "lorem ipsum", "Lorem ipsum", "your-domain", "example.com/buy"];
let dirty = false;
for (const [route, body] of Object.entries(pages)) {
  for (const p of PLACEHOLDERS) if (body.includes(p)) { bad(`${route} contains "${p}"`); dirty = true; }
}
if (!dirty) ok("no placeholder strings in any rendered page");

console.log(
  failed
    ? `\n${failed} check(s) failed — do NOT submit the domain yet.\n`
    : "\nPaddle domain review: every mechanical check passes.\n"
);
process.exit(failed ? 1 : 0);
