# BR — Chute

## Positioning
**Chute — drop context into your agent.**
A native macOS utility that turns the Finder selection into agent-ready context, and turns agent
output back into files.

## Target persona: the 10h/day AI product builder
Rarely writes code line-by-line. Scaffolds workspaces, curates context, prompts agents, reviews
diffs, extracts artifacts, cleans up agent messes. Runs Claude Code / Codex / Cursor / Aider all
day. Lives in Finder + Terminal + a web chat, and pays a tax on every hop between them.

## Problem
macOS Finder is built for manual work, not for feeding machines. Measured across the 24 JTBDs in
`03-JTBD-LEDGER.md`: **~90–120 min/day of pure micro-friction** per builder.

## Why now
CLI coding agents became the default workflow in 2025–26. Every existing context-menu utility was
designed for the pre-agent era: they create empty files from static templates. Nobody ships
"select 8 files → XML bundle with token count on the clipboard".

## Competitive landscape
| Product | Price | Why it does not solve this |
|---|---|---|
| NewFile / MacNewFile / RightMenu (OSS) | free | Static template cloning only. No clipboard, no agents, no bundling. |
| New File Menu (Langui) | ~$2–5 one-time | 2015-era UI, file creation only. |
| iBoysoft MagicMenu | $29.99/yr | Generic Windows-style suite; heavyweight; nothing agent-aware. |
| iRightMouse | freemium | Cluttered, mixed localization, privacy concerns. |
| QSpace Pro | ~$13.99 | Full Finder replacement, not a companion. |
| PopClip | ~$17 | Triggers on selected *text*, not on a Finder selection. |
| Raycast | freemium | Spotlight overlay, not the Finder right-click surface. |

**Gap:** none of them serve the agent loop. That gap is the product.

## Success metrics (v0.1)
| Metric | Target |
|---|---|
| Time-to-first-win after install | < 60 s |
| Commands used per builder per day | > 20 |
| Median time saved per builder per day | > 45 min |
| Crash-free command executions | > 99.5 % |

## Monetization
**$19 one-time** via Paddle Billing. Licensing via offline Ed25519 keys minted by Cloudflare Worker on Paddle webhook.
No network verification — the app never contacts a network to check keys.
Requires an Apple Developer ID ($99/yr) before public distribution — tracked in `06-BACKLOG.md`.

## Out of scope for v0.1
Cloud sync, accounts, telemetry, team features, Windows/Linux, an LLM API of our own.
Chute is a local, offline, zero-telemetry utility. That is a feature, not a limitation.
