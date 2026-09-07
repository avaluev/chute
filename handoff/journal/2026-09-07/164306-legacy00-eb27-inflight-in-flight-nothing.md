---
session: legacy
pid: 0
host: legacy
at: 2026-09-07T16:43:06Z
commit: legacy
kind: inflight
legacy-src: /Users/sxope/Documents/2026/Development/37.chute/handoff/archive/NEXT-2026-09-07-full.md:92
---
IN FLIGHT — nothing
The narrowed appex entitlement is **proved at runtime**, not just at build time. `uninstall.sh`
deleted `~/.chute` at 12:51 on 2026-09-01; the SANDBOXED extension recreated it and wrote
`~/.chute/extension-loaded.txt` at 12:52, from inside its sandbox, under
`home-relative-path.read-write = /.chute/` and nothing wider. `chute doctor` on the fresh install:
**9 of 10 checks pass**, the tenth being the agent-status hooks, which Chute deliberately never
writes (see below).

**The Mac now runs a from-scratch DMG install.** `~/Applications/Chute.app` and `~/.chute` were
removed, the extension unregistered, the app rebuilt, `dist/Chute-0.2.0.dmg` (1.6 MB) created and
mounted, and `Chute.app` copied to **`/Applications`** — the location the DMG actually tells a
customer to use, and the one `uninstall.sh` could not clean until today. Installed stamp
`84da70d` == HEAD.

**The hooks are wired — this is no longer an open item.** All four blocks are back in
`~/.claude/settings.json` and `chute hooks status` reports `✓ PermissionRequest · SessionStart ·
Stop · UserPromptSubmit`; `chute doctor` is 10/10 with `Agent status hooks — wired`. Chute still
never writes that file. The one-command path for the next machine is `chute hooks merged`, not the
snippet-and-merge-by-hand route this file used to describe.
