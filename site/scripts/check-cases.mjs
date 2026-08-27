#!/usr/bin/env node
/**
 * The landing page's arithmetic, checked against its own source.
 *
 * Every figure on the redesigned site comes from `src/lib/cases.ts`, and every figure in there is
 * supposed to come from `docs/03-JTBD-LEDGER.md`. Supposed to is not a guarantee: a number is the
 * easiest thing in a marketing page to nudge, and a nudged number is indistinguishable from an
 * invented one to anyone reading it. This re-derives each case from the ledger and fails if they
 * disagree — including the arithmetic itself, so a wrong row in the LEDGER is caught too.
 *
 * Run: node scripts/check-cases.mjs      (wired into the deploy gate, see Scripts/deploy-site.sh)
 */
import { readFileSync, readdirSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, resolve } from "node:path"
import { CASES } from "../src/lib/cases.ts"

const here = dirname(fileURLToPath(import.meta.url))
const LEDGER = resolve(here, "../../docs/03-JTBD-LEDGER.md")

let failed = 0
const ok = (m) => console.log(`  ok   ${m}`)
const bad = (m, detail) => { failed++; console.log(`  FAIL ${m}\n       ${detail}`) }

// ── the ledger, as data ────────────────────────────────────────────────────────────────────
// | 9 | Multi-file markdown → filesystem | 15 | 120 s | 6 s | **28.5 min** | M | **T1** |
const ledger = new Map()
for (const line of readFileSync(LEDGER, "utf8").split("\n")) {
  const cell = line.split("|").map((c) => c.trim())
  if (cell.length < 8) continue
  const jtbd = Number(cell[1])
  if (!Number.isInteger(jtbd) || jtbd === 0) continue
  const num = (s) => { const m = s.match(/-?[\d.]+/); return m ? Number(m[0]) : null }
  ledger.set(jtbd, {
    name: cell[2],
    perDay: num(cell[3]),
    manual: num(cell[4]),
    chute: num(cell[5]),
    // Row 12 reads "3.3 min **+ ~20 min/day risk-adjusted**" and row 24 "*prevents overflow*".
    // The FIRST number is the one on the clock; anything after it is commentary.
    saved: num(cell[6]),
  })
}
if (ledger.size < 20) {
  bad("the ledger parsed", `only ${ledger.size} rows found in ${LEDGER} — has the table changed shape?`)
} else {
  ok(`the ledger parsed — ${ledger.size} jobs`)
}

// ── every case matches its ledger row ──────────────────────────────────────────────────────
for (const c of CASES) {
  if (c.jtbd === 0) {
    if (c.savedMinutes !== null) {
      bad(`${c.slug} claims minutes`, "it has no ledger row, so it must not carry a figure")
    }
    continue
  }
  const row = ledger.get(c.jtbd)
  if (!row) { bad(`${c.slug} → JTBD ${c.jtbd}`, "no such row in the ledger"); continue }

  const same = (label, got, want) =>
    got === want || bad(`${c.slug} ${label}`, `cases.ts says ${got}, the ledger says ${want}`)

  same("perDay", c.perDay, row.perDay)
  same("manual seconds", c.seconds.manual, row.manual)
  same("chute seconds", c.seconds.chute, row.chute)
  if (c.savedMinutes !== null) same("savedMinutes", c.savedMinutes, row.saved)
}

// ── and the ledger's own arithmetic ────────────────────────────────────────────────────────
// saving = frequency × (manual − chute), in minutes. Stated at the top of the ledger; checked
// here so a typo in the table cannot propagate to the page through a "matching" case.
for (const c of CASES) {
  if (c.savedMinutes === null) continue
  const derived = Math.round((c.perDay * (c.seconds.manual - c.seconds.chute)) / 6) / 10
  if (Math.abs(derived - c.savedMinutes) > 0.1) {
    bad(`${c.slug} arithmetic`, `${c.perDay} × (${c.seconds.manual}s − ${c.seconds.chute}s) = ${derived} min, not ${c.savedMinutes}`)
  }
}
if (!failed) ok("every case matches the ledger, and the ledger matches its own method")

// ── structural rules the page depends on ───────────────────────────────────────────────────
const slugs = CASES.map((c) => c.slug)
new Set(slugs).size === slugs.length
  ? ok("slugs are unique — one page each")
  : bad("slugs are unique", "two cases would render to the same URL")

for (const c of CASES) {
  if (c.paid && c.surface === "cli") {
    bad(`${c.slug} is paid`, "but its surface is the CLI, which is free and MIT forever")
  }
  if (!c.paid && c.surface !== "cli") {
    bad(`${c.slug} is free`, `but it runs on the ${c.surface}, which is the paid app`)
  }
  if (!c.command) bad(`${c.slug} has no command`, "every case names its free CLI equivalent")
}

// THE SALES ARGUMENT, ASSERTED. The whole reason the four Finder actions were built is that the
// paid surface demonstrated less of the ledger than the free CLI did. If that ever inverts again,
// the page is arguing against itself and this must fail before it ships.
const minutes = (set) => Math.round(set.reduce((s, c) => s + (c.savedMinutes ?? 0), 0) * 10) / 10
const paid = minutes(CASES.filter((c) => c.paid))
const free = minutes(CASES.filter((c) => !c.paid))
paid > free
  ? ok(`the app carries ${paid} min/day, the free CLI ${free} — the paid surface is the larger half`)
  : bad("the paid surface is the larger half", `app ${paid} min/day vs free CLI ${free} min/day`)

// ── the stopwatch beats the estimate ───────────────────────────────────────────────────────
// Every `seconds` figure above started life as an estimate of how long the manual ritual takes.
// demo/gui records BOTH paths and times them, writing out/gui/<slug>.json. Where a measurement
// exists it wins: an estimate that survives next to a contradicting stopwatch is how a landing
// page ends up overstating in good faith. The tolerance is for run-to-run jitter, not for
// disagreement — if the ritual really is faster than the ledger says, fix the LEDGER.
const TIMINGS = resolve(here, "../../demo/out/gui")
let measured = 0, partial = 0
for (const c of CASES) {
  let m
  try { m = JSON.parse(readFileSync(resolve(TIMINGS, `${c.slug}.json`), "utf8")).measured }
  catch { continue }
  measured++
  const near = (got, want) => Math.abs(got - want) <= Math.max(3, want * 0.15)
  // A null side was not performed. Only the race tape runs the manual ritual; the other seven
  // film the Chute path alone, and comparing the ledger's own estimate against itself would
  // report agreement while proving nothing.
  if (m.manual !== null && !near(m.manual, c.seconds.manual)) {
    bad(`${c.slug} manual seconds`, `the stopwatch read ${m.manual}s, the page claims ${c.seconds.manual}s — quote the recording`)
  }
  if (m.chute !== null && !near(m.chute, c.seconds.chute)) {
    bad(`${c.slug} chute seconds`, `the stopwatch read ${m.chute}s, the page claims ${c.seconds.chute}s — quote the recording`)
  }
  if (m.manual === null) partial++
}
if (measured) {
  ok(`${measured} case(s) backed by a stopwatch, not an estimate`)
  if (partial) {
    console.log(`  note ${partial} of those timed only the Chute side — the manual ritual is`)
    console.log(`       performed by the race tape alone, so those savings remain ledger estimates`)
  }
} else {
  console.log("  note no recordings timed yet — every figure is still an estimate from the ledger")
}

// The reverse of the missing-demo note, and just as much a defect: a recording that was made,
// committed, and then never referenced. It costs bytes in the repo, it is not on the page it was
// shot for, and nobody finds out because nothing renders it.
const MEDIA = resolve(here, "../public/media")
try {
  const referenced = new Set(CASES.map((c) => c.demo).filter(Boolean).map((d) => d.replace("/media/", "")))
  const orphans = readdirSync(MEDIA)
    .filter((f) => /\.(gif|mp4|webm)$/.test(f) && !referenced.has(f) && !f.startsWith("card-") && f !== "og.png")
  if (orphans.length) {
    console.log(`  note ${orphans.length} recording(s) in public/media that no case refers to:`)
    console.log(`       ${orphans.join(", ")}`)
  }
} catch { /* no media directory yet */ }

// Recorded demos are optional until they are shot (see demo/verify.sh), but a case that claims
// one must point somewhere real — check-paddle.mjs proves the file resolves in the built site.
const undemoed = CASES.filter((c) => !c.demo)
if (undemoed.length) {
  console.log(`  note ${undemoed.length}/${CASES.length} cases still have no recording:`)
  console.log(`       ${undemoed.map((c) => c.slug).join(", ")}`)
}

console.log(`\ncases: ${CASES.length} checked, ${failed} failed`)
process.exit(failed ? 1 : 0)
