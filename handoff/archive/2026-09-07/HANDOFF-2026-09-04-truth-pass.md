# HANDOFF — the truth pass — 2026-09-04

> A record of finished work, not a plan. The canonical entry point is `handoff/NEXT.md`.
> One theme ran through all of it: every claim this repo makes about itself was checked
> against the thing it describes, and five were false.

## DONE 2026-09-04 (verified) — the ratchet's next two extractions, and four drifted numbers

**161 decision points, down from 172.** The two extractions the ratchet named — and that had each
already been deferred once — are done. Three rules moved out of `Sources/ChuteApp` and
`Sources/ChuteFinder`, which `chutetests` cannot link, into ChuteCore, which it can:

| Rule | Now at | Why it was worth moving |
|---|---|---|
| Which commands a session offers | `Sources/ChuteCore/SessionCommands.swift:52` | offering `--resume` for an agent whose syntax we guess puts a failing command on a clipboard |
| Which modifier reveals each one | `Sources/ChuteCore/SessionCommands.swift:41` | AppKit draws ONE alternate per distinct mask — two commands sharing one means the second row is built, is correct, and is never seen. Nothing in the drawing code can notice |
| The hex parse | `Sources/ChuteCore/SessionColor.swift:34` | it draws every session dot, and it had a live bug: `UInt32(_:radix:)` accepts a leading sign, so `"+ABCDE"` was six characters that parsed to a colour |
| What a Finder click means | `Sources/ChuteCore/ActionRequest.swift:51` | three of its four answers are sentences the user reads, and none were reachable — the shape that shipped the `.pyc` bug |

`SessionMenu` 29 → 19, `ChuteFinderSync` 20 → 19. **+41 assertions, 1,073 total.** Every new guard
was perturbed to red before it was believed — five for five, listed in `03ede90`.

**The size gate caught its own next drift.** Moving code into ChuteCore means it ships in all three
binaries rather than one: **+112 KB**, measured against a worktree build of HEAD, so the bundle is
**2.9 MB**. That is the price of the coverage and it was paid deliberately. Nine present-tense
claims of 2.8 MB were updated with it.

**Three more numbers in the fact sheet had drifted, ungated.** The file whose whole job is gated
numbers was carrying: CLI binary **727 KB claimed / 747 KB shipped at HEAD** — and that number was
being sold to a reader in `marketing/02-LANDING-COPY.md`; Lines of Swift **11,975 / 12,619**; unit
assertions **1,005 / 1,073**. All three corrected. The CLI binary row is now gated the same way the
bundle row is, and the gate was perturbed red. The other two are deliberately NOT gated — see
OPEN QUESTIONS.

**`chute doctor` said "all 10 checks passed" about an app that was not on the disk.** Found while
verifying the above, and it is the sharpest false pass this repo has had, because it is in the tool
whose entire job is telling you the truth about your install. `Diagnostics.resolvedAppPath` GUESSED
`~/Applications/Chute.app` whenever the CLI is not inside a bundle — which is the Homebrew CLI, the
copy customers install. The founder's app is in `/Applications`, where the DMG says to drag it, so
doctor reported a path that does not exist AND `✓ Finder extension actually starts — not installed`,
a tick whose own detail contradicts it. The probe read a bundle that is not there, got nil, and nil
means "no extension installed, someone else's check" — so it auto-passed. Fixed at the shared
function: `resolvedAppPath` answers with the copy that EXISTS (same candidate list, same order, as
`Scripts/build-app.sh:289`), and `app-location` asks whether the app is there rather than only
whether its parent folder is named Applications. `d9bd5ff`.

**The menu said `Working (7)` when nothing was working.** Reported by the founder from his own
menu bar; one of the seven rows was `38.LifespanOS · no agent running`. Two proxies were being read
as evidence of what an agent is doing and BOTH are wrong: Terminal's `busy` flag only means "a
process other than the shell is running in this tab", and the glyph Claude Code writes into the
title (`✳`, `◑`) is **never cleared when a turn ends** — three of the seven had hook records saying
`waiting` at 02:06, 02:34 and 03:10 and still carried a working glyph at 10:37. The glyph was
consulted exactly when the hook aged out, which is when it is most stale. Both deleted, with
`GlyphTable` and the `busy`/`title` parameters, so neither can be consulted again. **A hook, or
nothing.** `.unknown` gets its own menu group, `Running — no status`, rather than being filed under
Idle — which is the same lie pointing the other way, and idle rows collapse into a submenu above
three, so a running session could hide behind a disclosure triangle. The badge stopped lying too:
`.waiting` feeds it and was being guessed for any agent tab Terminal did not call busy. `87c2cef`.

**Antigravity is recognised.** `agy` → "Antigravity", matched as a substring because an update
renames the binary under the running process (`agy.1788445358670789000.old`). It ships **no hooks**
— `agy help` has no such subcommand — so it sits under "Running — no status" permanently. That is
the whole of what a terminal can tell Chute about it. `--conversation <ID>` exists as a resume
syntax, but the ID only ever arrives through a hook, so `ResumeCommand` was deliberately NOT given
an `agy` entry: it could never fire.

**The Settings window was carrying a forbidden claim, a dead domain and three overclaims.**
Reported by the founder from his own window. About said *"Nothing is uploaded, ever, except by the
`gist` command"* — and "nothing is uploaded, ever" is the string the fact sheet has forbidden IN
BOLD since 2026-08-28. The site, the README and every marketing file are swept for it on each
deploy; **the README sweep was added on 2026-09-02 for this exact string, and nobody swept the
app** — the one surface a paying customer reads. About also printed `chutedev.com`, which does not
resolve. License promised Chute "never contacts a server … and never will", a promise nobody can
check. General claimed `doctor` checks "every prerequisite" over ten checks — the same sentence
was in `chute help` and in `README.md`, which generates the site's command table. All rewritten
against the source, every count now READ (`ChuteActions.all.count`, `Diagnostics.all.count`) rather
than typed. The About copy is `Sources/ChuteCore/AboutText.swift` now, because the ratchet was
right: that text had been unreadable by any test for its whole life. `815be8a`.

**`check-claims.mjs` sweeps `Sources/**/*.swift` now**, comments stripped so it cannot fire on its
own documentation. Perturbed: the string planted in `Panel.swift` is found and named. Also
`README.md` was missing `chute resume` and `chute onboard` — 24 rows against 26 in `chute help` —
so the site's command table silently omitted two real commands. Both added; 26 and 26.

**`site/src/lib/commands.json` was stale**, still describing `hooks snippet|uninstall|status`. It is
generated from the binary but only when someone runs the site build. Regenerated.

---

# Later the same day — the status removed, reviewed and cleaned

## DONE 2026-09-04 (verified) — the truth pass

Full record: `handoff/HANDOFF-2026-09-04-truth-pass.md`. One theme — every claim the repo makes
about itself was checked against the thing it describes, and five were false.

| What was wrong | Where | Commit |
|---|---|---|
| Two ratchet extractions still deferred | `SessionMenu` 29, `ChuteFinderSync` 20 → **161 total, was 172** | `03ede90` |
| Four fact-sheet numbers had drifted, one of them sold to a reader | bundle, CLI binary, lines, assertions | `8da1614` |
| `chute doctor` said "all 10 checks passed" about an app not on the disk | `resolvedAppPath` guessed `~/Applications` | `d9bd5ff` |
| The menu said `Working (7)` with nothing working | Terminal's `busy` flag and a title glyph that is never cleared | `87c2cef` |
| Settings carried a forbidden claim, a dead domain and three overclaims | About, License, General — and `chute help`, and `README.md` | `815be8a` |

**Reinstalled clean at the founder's request, 2026-09-04.** `uninstall.sh` left nothing — both
app folders, `~/.chute`, the CLI symlink, the appex registration — and correctly KEPT the trial
file (`~/Library/Application Support/Chute/trial.json`, outside `~/.chute`) and the Homebrew CLI.
Reinstalled with `CHUTE_APP_DIR=/Applications` so it stayed where the Dock points; without that
env var an uninstall-then-install RELOCATES it to `~/Applications`, which is what the variable
exists for. Installed stamp == HEAD, `chute doctor` 9/10 — the tenth is the hooks the uninstall
strips and Chute never writes. The sandboxed extension recreated `~/.chute` on load, so the
narrowed-entitlement runtime proof still holds on a from-scratch install.

**THE ONE THAT NEARLY COST THE FOUNDER HIS SETTINGS.** The command `chute hooks snippet` prints
began with the bare word `chute`. PATH resolves that to Homebrew's **0.2.0**, which does not know
`hooks merged`, falls through to `status`, prints `→ settings: …` and **exits zero**. Every link
in that chain is `&&`. Pasted, it would have written status text over a 33 KB `settings.json`
carrying eleven hooks from other tools. Fixed at the cause (`hooks snippet` names the binary that
printed it, as ChuteApp already did for the menu row) and at the class (`applyCommand` refuses
anything not starting with `{`, checked before the backup and the move). `8494f99`.

**Then the status was removed entirely, at the founder's request** (`2849347`). Fixing the states
was correct and still left five of seven sessions reading `—`, which is honest and useless. The
four groups, the header line, the "Every state below is a guess" nag row, the collapsing idle
submenu, the "waited 4m" suffix and **the menu bar badge count** are all gone. The menu is a flat
list of terminals sorted by project: what Chute can see for itself when it opens — project, agent,
what that terminal costs — and clicking one brings it forward. Hooks still earn their keep through
the session id (resume, tmux, cost); they just no longer put a word on screen. Ratchet 161 → 156.

**Reviewed, cleaned and reinstalled** (`49ca130`). Code review of the day's 16 commits: no
hardcoded credentials in tracked source, no TODO/FIXME, no `print`/`console`, nothing over 800
lines or 50 lines per function. Two findings, both fixed. **CRITICAL: a live Cloudflare API token
sat in the repo root** as `CloudFlare_API+.md` — never committed, gitignored, but readable by every
agent session, and `~/.secrets/` already held `CloudFlare_API.LEAKED.md` from the day before at the
same size. Moved to `~/.secrets/` (0700/0600). **ROTATE IT.** MEDIUM: two force-unwraps in
`HookInstallerSuite` — a `!` crashes the harness and a crash prints no tally.

Dead code deleted, all orphaned by removing the status: `HookState.attention`/`liveTTYs`,
`SessionPhrasing.waitedFor`, and `MenuNode.header` with its renderer — each had tests, and a
function whose only caller is its own test is dead code wearing a coverage badge. 1,078 → 1,065
assertions, ratchet 156 → 154. Four stale scratch files removed from `handoff/`; **the six AUDIT
files were kept deliberately** — they carry unresolved findings.

**Antigravity** (`agy`) is recognised and named. It ships no hooks, so it sits under
"Running — no status" permanently; that is the whole of what a terminal can tell Chute about it.

**Three gates added or fixed**, each perturbed to red: the CLI binary size (±2%, after an exact
compare cried wolf on a 1 KB move within the hour), the forbidden-claims sweep over
`Sources/**/*.swift`, and the app-location existence check.

