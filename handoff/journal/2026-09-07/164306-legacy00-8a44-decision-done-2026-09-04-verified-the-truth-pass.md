---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: decision
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:66
---
DONE 2026-09-04 (verified) — the truth pass
Full record: `handoff/HANDOFF-2026-09-04-truth-pass.md`. One theme — every claim the repo makes
about itself was checked against the thing it describes, and five were false.

| What was wrong | Commit |
|---|---|
| Two ratchet extractions still deferred — `SessionMenu` 29, `ChuteFinderSync` 20 | `03ede90` |
| Four fact-sheet numbers had drifted, one of them sold to a reader | `8da1614` |
| `chute doctor` said "all 10 checks passed" about an app not on the disk | `d9bd5ff` |
| The menu said `Working (7)` with nothing working | `87c2cef` |
| Settings carried a forbidden claim, a dead domain and three overclaims | `815be8a` |
| The hooks apply command could overwrite settings.json with status text | `8494f99` |
| **The session status removed entirely** — the menu is a list of terminals | `2849347` |
| Reviewed, dead code deleted, a plaintext token moved out of the tree | `49ca130` |

**Antigravity** (`agy`) is recognised and named. It ships no hooks, so Chute can never know what it
is doing — which is half the reason the status went.

**Ratchet 172 → 154.** Three gates added or fixed, each perturbed to red: the CLI binary size
(±2%), the forbidden-claims sweep over `Sources/**/*.swift`, and the app-location existence check.

**CRITICAL, from the review:** a live Cloudflare API token sat in the repo root
(`CloudFlare_API+.md`) — never committed, gitignored, but readable by every agent session, and one
day after a leaked one. Moved to `~/.secrets/` (0700/0600). **ROTATE IT.**
