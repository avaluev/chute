# JTBD Ledger — ranked by time saved per day

Method: `daily saving = frequency (midpoint) × (manual seconds − Chute seconds)`.
Manual timings are the workarounds you described. Chute timings are the design target (NFR-01).
**Priority = daily saving ÷ build cost.** That ratio, not raw pain, decided the tier.

| # | JTBD | Freq/day | Manual | Chute | Saved/day | Build cost | Tier |
|---|---|---|---|---|---|---|---|
| 9 | Multi-file markdown → filesystem | 15 | 120 s | 6 s | **28.5 min** | M | **T1** |
| 2 | Multi-file context bundle (XML) | 17 | 150 s | 5 s | **41.1 min** | S | **T1** |
| 3 | Clipboard → file in target folder | 25 | 35 s | 4 s | **12.9 min** | S | **T1** |
| 1 | Multi-file path extraction | 32 | 20 s | 3 s | **9.1 min** | S | **T1** |
| 6 | Agent sandbox initialization | 11 | 45 s | 5 s | **7.3 min** | M | **T1** |
| 8 | Open terminal / IDE here | 27 | 15 s | 2 s | **5.9 min** | S | **T1** |
| 24 | Token estimator before attaching | 15 | 0 s* | 2 s | *prevents overflow* | S | **T1** |
| 12 | Pre-agent checkpoint | 9 | 25 s | 3 s | 3.3 min **+ ~20 min/day risk-adjusted** | S | **T1** |
| 4 | Syntax auto-detection | 12 | 10 s | 0 s | 2.0 min | S | **T1** |
| 14 | Safe `.env` key injection | 7 | 120 s | 5 s | **13.4 min** | M-sec | T2 |
| 7 | Seed agent rule files | 7 | 90 s | 5 s | **9.9 min** | S | T2 |
| 22 | Context buffer / clipboard ring | 12 | 45 s | 4 s | **8.2 min** | S | T2 |
| 5 | Directory tree skeleton | 10 | 30 s | 3 s | 4.5 min | S | T2 |
| 11 | Diff snapshot before commit | 14 | 25 s | 4 s | 4.9 min | S | T2 |
| 10 | Reveal latest artifact | 20 | 15 s | 2 s | 4.3 min | S | T2 |
| 15 | Zombie port killer | 11 | 30 s | 3 s | 4.9 min | S | T2 |
| 16 | Scratchpad "where I left off" | 15 | 40 s | 5 s | **8.8 min** | S | T2 |
| 21 | Multi-agent broadcast | 6 | 60 s | 5 s | 5.5 min | S | T2 |
| 17 | Micro-task decomposition prompt | 8 | 120 s | 3 s | **15.6 min** | XS | T2 |
| 18 | Ponytail anti-bloat prompt | 10 | 60 s | 3 s | **9.5 min** | XS | T2 |
| 13 | Clean agent junk artifacts | 11 | 40 s | 4 s | 6.6 min | S | T2 |
| 19 | Copy redacted | 4 | 90 s | 3 s | 5.8 min | S | T2 |
| 23 | Image → base64 / data URL | 7 | 25 s | 2 s | 2.7 min | XS | T2 |
| 20 | Secret gist from Finder | 3 | 60 s | 4 s | 2.8 min | XS | T2 |

\* JTBD 24 saves no direct time; it prevents context-overflow failures that cost a full retry.

## Totals
- **Tier 1 (9 JTBDs): ≈ 110 min/day** of friction removed — this alone justifies the product.
- **Tier 2 (15 JTBDs): ≈ 108 min/day** additional.
- Overlap and context-switch recovery are excluded, so both figures are conservative.

## The three that decide the product
1. **JTBD 2 — context bundling (41 min/day).** The single largest saving and the clearest wedge:
   no competitor does it.
2. **JTBD 9 — markdown unpacker (28 min/day).** The inverse direction. Owning both directions of
   the loop is the positioning: *context in, artifacts out*.
3. **JTBD 12 — checkpoint.** Small on the clock, enormous on risk: it is what makes `--yolo`
   psychologically safe, which is what makes the sandbox launcher get used.

## Cognitive load (Category 6) is not a nice-to-have
JTBDs 16, 17, 18 cost almost nothing to build (they are text templates plus a clipboard write) and
together return ~34 min/day. Highest ROI per line of code in the entire ledger.
