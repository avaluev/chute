# Backlog — post v0.1

## v0.2 — designed, ready to build
| Item | Spec |
|---|---|
| Finder context menu via FinderSync extension | `docs/superpowers/specs/2026-08-26-findersync-context-menu-design.md` |
| Agent session switcher in the menu bar | `docs/superpowers/specs/2026-08-26-session-switcher-design.md` |

## v0.3 — distribution (blocked on money/tooling, not on code)
| Item | Blocker | Effort |
|---|---|---|
| Developer ID signing + notarization | Apple Developer Program, $99/yr | 2 h once the cert exists |
| Sparkle auto-update | Needs a signed build first | 3 h |
| Licensing / paywall (Paddle keys via Cloudflare Worker) | Monetization decision deferred | 4 h |

## v0.3 — reach
- Raycast extension wrapping the same CLI (~2 h — the CLI already is the API)
- Homebrew tap: `brew install avaluev/tap/chute`
- Setapp submission
- `chute watch` — auto-checkpoint before each agent run
- Per-JTBD local usage counters (opt-in, on-device only, never uploaded)

## Explicitly rejected
| Idea | Why not |
|---|---|
| Cloud sync of templates | Contradicts the offline/zero-telemetry promise, which is the trust asset |
| Built-in LLM calls | Users already pay for agents; we are plumbing, not another API bill |
| Mac App Store | Sandbox forbids launching Terminal and arbitrary agent CLIs — kills the flagship feature |
| Plugin system | One user, 24 commands. YAGNI until someone asks. |
