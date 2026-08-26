# Backlog — post v0.1

## v0.2 — distribution (blocked on money/tooling, not on code)
| Item | Blocker | Effort |
|---|---|---|
| True `FIFinderSync` extension — top-level Finder menu, no "Quick Actions" nesting | Xcode not installed (~10 GB) | 1 day |
| Developer ID signing + notarization | Apple Developer Program, $99/yr | 2 h once the cert exists |
| Sparkle auto-update | Needs a signed build first | 3 h |
| Licensing / paywall (LemonSqueezy keys) | Monetization decision deferred | 4 h |

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
