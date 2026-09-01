# Pricing and demo

## Price: Free 14-day trial. $19 one-time after trial ends.
Trial includes full app features; the app locks after 14 days, but the free CLI remains available. No subscription, no account.

| Option | Verdict |
|---|---|
| Free | Leaves money on the table; this saves an hour a day for the exact people who bill by the hour |
| $9 one-time | Lower-priced option; superseded 2026-08-27 when Developer ID signature improved |
| $29/yr | The MagicMenu model. Invites the "another subscription?" objection Chute wins against |
| **$19 one-time** | **Chosen.** Defensible on value and trust now that app is signed and notarized. Trial removes purchase friction. |

Rationale: Developer ID and notarization are now in place; the trust premise supports the price.

**Store:** Paddle Billing (merchant of record, handles EU VAT). Licensing via offline Ed25519 keys minted by Cloudflare Worker.
**Refund:** 30 days, no questions. Say so on the button.

## Demo video — 20 seconds, no narration

> Rewritten 2026-09-01: the 10–14 s shot was *Unpack Markdown Here*, a command deleted on
> 2026-08-31. The replacement shots are the Basket and the menu bar — the two surfaces nothing
> else on the Mac ships, which is what a demo is for.
| Time | Shot |
|---|---|
| 0–3 s | Finder, 8 TypeScript files selected. Right-click. |
| 3–6 s | *Services ▸ Chute – Bundle Context (XML)*. Notification: "8 files · ~14k tokens". |
| 6–10 s | Cut to Claude Code. ⌘V. The whole codebase lands in one message. |
| 10–14 s | Cut back to Finder, a DIFFERENT folder. Right-click → *Add to Context Basket*. Then a third folder, same thing. Menu bar → *Copy Basket as @mentions* → ⌘V. Three folders, one hand-over. |
| 14–18 s | Menu bar opens: five terminals, one badged as waiting. Click it — that window comes forward. |
| 18–20 s | Wordmark: **Chute — drop context into your agent.** chutedev.com · free 14-day trial, then $19. |

Rules: real speed, no time-lapse. No cursor highlights, no zoom effects, no music.
The speed is the pitch; anything added to it reads as compensation.

## Channels, in order
1. Personal X account with the 20-second video — the demo is the whole ad.
2. Show HN with the two implementation notes (the `git stash create` gap and the APFS collision).
3. r/macapps, r/ClaudeAI, r/LocalLLaMA.
4. Product Hunt once notarization lands — not before; an unsigned download tanks PH conversion.

## First metrics to watch
| Metric | Meaning |
|---|---|
| Download → first `bundle` run | The activation event. If they run it once, they keep the app. |
| `bundle` vs `paths` ratio | Confirms whether bundling is really the wedge |
| Refund rate > 5 % | Positioning is overpromising — fix the landing page, not the price |
