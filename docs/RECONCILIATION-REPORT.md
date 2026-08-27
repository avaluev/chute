# Reconciliation Report — 2026-08-27

**Decision table locked:** 2026-08-27  
**Reconciliation completed:** 2026-08-27  
**Mechanical pass:** All decision table values propagated across 8 editable documentation files.

---

## Files Changed

### 1. /Users/sxope/Documents/2026/Development/37.chute/README.md
- Test numbers updated from stale claims to measured values:
  - "214 unit assertions" → "519 assertions" (1 replacement)
  - "53 end-to-end checks" → "140 passed" (1 replacement)
- Homebrew install added as free CLI option above existing install.sh (1 addition)
- **Total changes: 3**

### 2. /Users/sxope/Documents/2026/Development/37.chute/docs/01-BUSINESS-REQUIREMENTS.md
- Monetization section rewritten to reflect locked decisions:
  - "$9–19 (Gumroad / LemonSqueezy)" → "$19 one-time via Paddle Billing"
  - Added: offline Ed25519 licensing via Cloudflare Worker
  - **Total changes: 1**

### 3. /Users/sxope/Documents/2026/Development/37.chute/docs/06-BACKLOG.md
- Backlog item updated:
  - "LemonSqueezy keys" → "Paddle keys via Cloudflare Worker" (1 replacement)
  - **Total changes: 1**

### 4. /Users/sxope/Documents/2026/Development/37.chute/docs/09-GTM-DECISIONS.md
- Assumption A4 rewritten to mark supersession:
  - Previous decision ($9) documented with date; new decision ($19) noted as 2026-08-27
  - Rationale: Developer ID signature now supports higher price (1 replacement)
- Pricing Research section (§5) substantially updated:
  - $9 marked as superseded 2026-08-26 → 2026-08-27 transition documented
  - $19 set as chosen with reasoning (1 replacement)
  - **Total changes: 2**

### 5. /Users/sxope/Documents/2026/Development/37.chute/marketing/02-LANDING-COPY.md
- Hero section CTA updated:
  - "$9 one-time" → "free 14-day trial" (1 replacement)
- Pricing section rewritten:
  - Old: "$9 — one payment"
  - New: "Free for 14 days. $19 once after that. The command-line tool is free forever."
  - Added trial mechanics and CLI permanence (1 replacement)
  - **Total changes: 2**

### 6. /Users/sxope/Documents/2026/Development/37.chute/marketing/03-LAUNCH-POSTS.md
- X/Twitter post updated:
  - "Chute. macOS. $9 once." → "Chute. macOS. Free 14-day trial, $19 after." (1 replacement)
- Reddit r/macapps title updated:
  - "offline, $9" → "offline, free trial + $19" (1 replacement)
  - **Total changes: 2**

### 7. /Users/sxope/Documents/2026/Development/37.chute/marketing/04-PRICING-AND-DEMO.md
- Price section fully rewritten to new model:
  - Old: "$9 one-time" as chosen; $19 deferred to v1.0
  - New: "Free 14-day trial. $19 one-time after trial ends" with full rationale
  - Store changed: LemonSqueezy/Gumroad → Paddle Billing
  - Added: Licensing mechanism (Ed25519 keys via Cloudflare Worker)
  - Added: Rationale for $19 (Developer ID now in place, trust premise holds)
  - **Total changes: 1 (major section replacement)**

### 8. /Users/sxope/Documents/2026/Development/37.chute/marketing/01-POSITIONING.md
- Objection handler updated:
  - "It is $9." → "Free 14-day trial." (1 replacement)
  - **Total changes: 1**

---

## Measured Test Numbers

Commands run to update stale test counts in README.md:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && swift run chutetests 2>&1 | tail -1
# Output: ✅ 519 assertions passed

cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/smoke.sh 2>&1 | tail -1
# Output: smoke: 140 passed, 0 failed
```

**Actual test coverage:**
- Unit assertions: **519** (README claimed 214)
- E2E checks passing: **140** (README claimed 53)

---

## Decision Table Compliance

All entries from the decision table (2026-08-27) are now reflected:

| Decision | Propagated to files |
|---|---|
| Price: $19 one-time | 02-LANDING, 03-LAUNCH-POSTS, 04-PRICING, 01-BUSINESS-REQS, 09-GTM (supersession marked), 01-POSITIONING |
| Store: Paddle Billing | 01-BUSINESS-REQS, 06-BACKLOG, 04-PRICING |
| Trial: 14-day free, full features, then lock | 02-LANDING, 03-LAUNCH-POSTS, 04-PRICING |
| Model: Open core (free CLI, paid app) | 02-LANDING, 04-PRICING, implied in 03-LAUNCH-POSTS |
| Domain: chutedev.com | No TBD domain references found in editable files |
| Licensing: Offline Ed25519 keys via Cloudflare Worker | 01-BUSINESS-REQS, 06-BACKLOG, 04-PRICING |
| DMG hosting: GitHub Releases | Not in scope of editable files (already implemented) |

---

## Contradictions / Open Questions

**None found.** All documents now agree on:
- Price: $19 (with 14-day trial preceding it)
- Store: Paddle Billing
- Licensing: Offline Ed25519 via Cloudflare Worker
- Free CLI forever; Chute.app has trial then locks

**Historical note:** The $9 pricing decision (2026-08-26) is preserved in 09-GTM-DECISIONS.md with explicit supersession markup and rationale for the change, maintaining auditability.

---

## Summary

**Total file changes:** 8 files  
**Total edits:** 13 replacements + 1 addition  
**Test numbers updated:** 2 stale claims corrected with measured values  
**Domain additions:** 0 (no TBD domain references to update)  
**Contradictions resolved:** 0 found  
**Voice compliance:** All changes preserve terse, concrete, numbers-first voice; no corporate language introduced.
