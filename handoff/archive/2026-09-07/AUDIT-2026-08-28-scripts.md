# AUDIT — install/build/release scripts — 2026-08-28

**VERDICT:** Ship-blocking: `Scripts/release.sh` currently cannot even reach `--dry-run` (the
tag-exists preflight fires unconditionally), and its tag→push→gh-release sequence has no
rollback, so a mid-sequence failure can leave a pushed tag with no GitHub release. `Scripts/uninstall.sh`
has the classic empty-`$HOME` `rm -rf` exposure on every destructive line, with no guard anywhere
in the file. `Scripts/build-app.sh` can silently downgrade to an ad-hoc signature on a genuine
codesign error and still print "built" as if nothing was wrong. Nothing here is a proven live
incident — all four require an unusual precondition (empty `$HOME`, a `git push`/`gh release`
failure mid-publish, a codesign error) — but all four sit exactly on the paths the task named.

Checks run: `bash -n` on all 7 shell scripts — all pass. `shellcheck` — **not installed**
(`command -v shellcheck` found nothing); this audit is manual line-by-line review only, no
static-analysis tool was available. No script was executed. No file was modified.

Severity counts: **CRITICAL 1 · HIGH 4 · MEDIUM 4 · LOW 7**

---

## CRITICAL

### C1 — `uninstall.sh` has no guard against an empty/malformed `$HOME` before four destructive ops
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/uninstall.sh:10-14`

```
10  rm -rf "$HOME/Applications/Chute.app"
11  rm -f "$HOME/.local/bin/chute"
12  rm -rf "$HOME/.chute"
14  find "$HOME/Library/Services" -maxdepth 1 -name "Chute*" -exec rm -rf {} + 2>/dev/null || true
```

`set -u` (line 2) only catches an **unset** `$HOME` — it does nothing for `$HOME` set to the
**empty string**. That happens in practice: a `.pkg` postinstall phase, a LaunchAgent, or any
sanitized-environment wrapper (`env -i …`, some Automator actions) can hand this script a blank
`HOME` while still running it as the logged-in user with normal filesystem permissions.

**Failure scenario:** `HOME=""` at invocation. `"$HOME/Applications/Chute.app"` collapses to
`/Applications/Chute.app` — line 10 becomes `rm -rf /Applications/Chute.app`, deleting whatever
is at that exact path system-wide, no confirmation, no dry check. This is precisely the drop
location the DMG install flow tells customers to use (`Scripts/release.sh:101-103`: "drag Chute
to Applications"), so on a machine with `HOME=""` this line deletes the customer's actual,
properly-installed app instead of a per-user copy that likely never existed. Line 14's `find
"$HOME/Library/Services"` similarly becomes `find /Library/Services` — a system-wide directory —
though it is at least guarded by `|| true` so a permission failure there won't abort the script
(but a permission-SUCCESS, i.e. an admin user, would still delete matching entries there).

**Smallest fix:** one line after `set -euo pipefail`:
```sh
[ -n "$HOME" ] && [ "$HOME" != "/" ] || { echo "uninstall: \$HOME is not sane ('$HOME') — refusing to run" >&2; exit 1; }
```
Same guard belongs at the top of `Scripts/install.sh` (see M-equivalent note under H/M below) since
it has the identical `rm -rf "$HOME/Applications/Chute.app"` at
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh:10` — install.sh's blast
radius is smaller (it's a `cp -R` overwrite, not a pure delete-and-stop) but the same collapse
applies.

---

## HIGH

### H1 — `release.sh` preflight blocks `--dry-run` even though dry-run never touches the tag
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:19-32,91-94`

```
19  DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
...
32  git rev-parse "$TAG" >/dev/null 2>&1 && die "$TAG already exists; bump Sources/ChuteCore/Version.swift"
...
91  if [ "$DRY" = "1" ]; then
92    step "--dry-run: stopping before the tag and the GitHub release"
93    exit 0
94  fi
```
`$TAG` is only read/written at lines 32, 97, 98, 99, 105 — all in the tag/push/release path that
`--dry-run` explicitly skips (91-94). But the tag-exists check at line 32 runs unconditionally in
Preflight, before `$DRY` is ever consulted. Right now this is not hypothetical:
`Sources/ChuteCore/Version.swift` reads `0.2.0` and `v0.2.0` is already pushed (confirmed via
`git tag -l`), so **`./Scripts/release.sh --dry-run` dies at line 32 today**, before it builds,
signs, or notarises anything — defeating the one flag whose entire purpose (per the file's own
header comment, line 14) is to test the pipeline without cutting a release.

**Fix:** gate the tag check behind `$DRY`:
```sh
[ "$DRY" = "1" ] || { git rev-parse "$TAG" >/dev/null 2>&1 && die "$TAG already exists; bump Sources/ChuteCore/Version.swift"; }
```

### H2 — `release.sh` tag→push→release has no rollback: a failure after the push leaves a pushed tag with no release
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:96-99`

```
96  step "Tagging and publishing $TAG"
97  git tag -a "$TAG" -m "Chute $VERSION"
98  git push origin "$TAG"
99  gh release create "$TAG" "$DMG" --title "Chute $VERSION" --notes "..."
```
Three unguarded steps in sequence, no trap, no `grep repos/…/releases` recovery path, no
`git tag -d`/`git push origin :refs/tags/$TAG` anywhere in the file (confirmed by grep — zero
hits).

**Failure scenario A (push fails, e.g. transient network/auth):** line 97 succeeds — a local tag
now exists — line 98 fails, `set -e` aborts. `$TAG` now exists **locally only**. Any re-run of
`release.sh` hits the H1 check at line 32 and dies with `"$TAG already exists"`, which is
misleading: the tag was never published, but the message reads as if it was. Recovery requires
manually knowing to run `git tag -d $TAG`.

**Failure scenario B — exactly "a pushed tag with no release":** line 98 succeeds (tag now on
`origin`) — line 99 fails (`gh` not authenticated, rate-limited, DMG upload hiccup, network drop).
Script aborts. State: a tag is live on the remote, no GitHub release exists for it, and the same
preflight (line 32) blocks any clean retry — the operator must manually delete the tag both
locally and on the remote before `release.sh` can run again.

**Fix (smallest):** on failure of line 99, roll back the tag automatically:
```sh
git push origin "$TAG" || die "tag push failed — run: git tag -d $TAG"
gh release create "$TAG" "$DMG" --title "Chute $VERSION" --notes "..." \
  || { git push origin ":refs/tags/$TAG" 2>/dev/null; git tag -d "$TAG"; die "gh release create failed — tag rolled back, safe to re-run"; }
```

### H3 — `release.sh` final `gh release view` can turn a fully successful release into a reported failure
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:105`

```
105  echo "released: $(gh release view "$TAG" --json url -q .url)"
```
This runs only after line 99 (`gh release create`) has already succeeded — the release is real at
this point. But the command substitution here is unguarded; if `gh release view` fails for any
transient reason (API propagation lag, a hiccup), `set -e` aborts the script on its very last
line, after all real work is done. The operator sees a script failure and may try to re-run
`release.sh`, immediately hitting the H1/H2 "tag already exists" block for a release that in fact
already shipped cleanly. Low likelihood, confusing outcome. **Fix:** `|| true` this line, or fall
back to printing the known GitHub URL pattern directly instead of re-querying the API.

### H4 — `build-app.sh`'s `sign()` silently falls back to ad-hoc on ANY codesign failure, not just a hung keychain prompt, and still reports "built" as success
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/build-app.sh:142-174`

The function is written to handle exactly one failure mode — a hung "codesign wants to use your
key" dialog (comment at lines 137-141) — with a 120-second wait loop:
```
142  sign() {  # target [entitlements]
143    local target="$1"; shift
144    if [ "$IDENTITY" != "-" ]; then
145      ( codesign --force --sign "$IDENTITY" "${HARDEN[@]+"${HARDEN[@]}"}" "$@" "$target" 2>/dev/null ) & local pid=$!
...
154      if kill -0 "$pid" 2>/dev/null; then
155        kill -9 "$pid" >/dev/null 2>&1 || true
156        echo "note: no answer to the keychain prompt — falling back to an ad-hoc signature."
...
162        IDENTITY="-"
163      else
164        wait "$pid" 2>/dev/null && return 0
165      fi
166    fi
167    codesign --force --sign - "$@" "$target" 2>/dev/null \
168      || echo "note: signing unavailable for $target; it still runs locally"
169  }
```
If the backgrounded `codesign` at line 145 fails **quickly** for a real reason (expired
certificate, wrong/missing entitlements, locked keychain, revoked identity — anything that isn't
"waiting on a human click") the `for` loop's `kill -0 "$pid"` sees the process already dead on the
first iteration, so `waited` never reaches `3` and the "macOS is asking permission…" message
(line 151, not shown above) never prints either. Control falls to the `else` branch: `wait "$pid"
… && return 0` — `wait` returns the real nonzero exit code, so `&& return 0` does **not** fire,
and execution falls all the way through to the ad-hoc fallback at line 167. Since ad-hoc signing
almost always succeeds locally, `sign()` returns 0 — **no message at all** is printed (the `||
echo "note: …"` at line 168 only fires if even the ad-hoc attempt fails). The function called at
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/build-app.sh:171-172` (`sign "$APPEX"
…`, `sign "$APP"`) returns success either way, and the script's final output is unconditionally:
```
173  echo "built $APP"
174  du -sh "$APP" | awk '{print "size: " $1}'
```
No distinction between "signed with Developer ID / Chute Local Dev" and "silently downgraded to
ad-hoc mid-run." Run standalone (or via `install.sh:7`), nothing downstream checks the actual
signing identity — `release.sh` is the one caller that does verify
(`codesign -dvv dist/Chute.app | grep -q "Developer ID Application" || die`, lines 52-53), so the
release pipeline specifically is protected for the outer app bundle (not the appex). Any other
caller is not.

**Fix (smallest):** don't let a fast failure fall through unremarked — distinguish "still running"
from "exited": 
```sh
else
  if wait "$pid" 2>/dev/null; then return 0; fi
  echo "note: signing with \"$IDENTITY\" failed — falling back to ad-hoc for $target"
fi
```
and have the final summary print the identity actually used, e.g. `codesign -dvv "$APP" 2>&1 |
grep Authority | head -1`, instead of a bare "built $APP".

---

## MEDIUM

### M1 — `install.sh` has two unguarded `open` calls that can hard-abort mid-script after the real install already succeeded
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh:27` and `:65`

Line 27: `open "$HOME/Applications/Chute.app" 2>/dev/null || { sleep 2; open "$HOME/Applications/Chute.app"; }`
— if the retry `open` also fails, it is the last command in that block and is not guarded by `||
true`; under `set -e` the whole script aborts right there. By this point the app is already
copied to `~/Applications` and the CLI is already symlinked (lines 9-12) — i.e. the install
substantively succeeded — but the script reports total failure and never reaches the Finder-
extension repair block (lines 53-79) or the completion banner (lines 83-103).

Line 65 (inside the extension-repair branch) is the same pattern with no fallback at all: `open
"$HOME/Applications/Chute.app"` unguarded. A failure there aborts the repair silently mid-way,
after already having deregistered the extension (line 62) and killed the app (line 63) — leaving
the extension in a worse state (deregistered, not re-registered) than before the repair started,
with no completion message explaining why.

**Fix:** wrap both in `|| echo "note: could not open Chute.app — launch it manually from ~/Applications" ` (non-fatal) rather than letting them abort the script bare.

### M2 — `cloudflare-setup.sh` swallows real DNS/SSL API failures into the process exit code
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/cloudflare-setup.sh:82-83,87-89,100-102`

```
82   api PUT "/zones/$ZONE_ID/dns_records/$id" "$body" | grep -q '"success":true' \
83     && echo "  updated  $name → $TARGET (proxied)" || echo "  FAILED   $name"
...
100  api PATCH "/zones/$ZONE_ID/settings/ssl" '{"value":"full"}' | grep -q '"success":true' \
102    && echo "  ssl = full" || echo "  could not set SSL (token lacks Zone Settings:Edit — set it in the dashboard)"
```
Each of these is a complete `cmd && echo ok || echo FAILED` statement — its own exit status is
always that of whichever `echo` ran last, i.e. always 0. If the Cloudflare API call genuinely
fails (wrong token scope, network error, zone permission issue) the script prints `FAILED $name`
or `could not set SSL…` to stdout but still exits 0 overall and proceeds to print the "Next"
success banner (lines 105-111) as if everything worked. This is the same class of problem the
task calls out for `cmd | tail`/`| head` — the measured exit status is decoupled from whether the
actual operation succeeded. Not consumed by CI today (this is a one-time interactive setup
script per its own header), but anyone scripting around it (or just checking `$?` after) would
get a false pass.

**Fix:** track failures and exit nonzero at the end, e.g. accumulate a `FAILED=1` flag in
`put_cname` and the SSL step, then `[ "$FAILED" = 1 ] && exit 1` before the final "Next" banner.

### M3 — `release.sh`: unclear whether a notarization rejection is even reachable past the `tee` pipe
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/release.sh:67-74`

```
67  xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait \
68    | tee /tmp/chute-notary.log
69  grep -q "status: Accepted" /tmp/chute-notary.log || {
70    ID="$(sed -n 's/ *id: *\([a-f0-9-]*\)/\1/p' /tmp/chute-notary.log | head -1)"
71    echo "--- Apple's reasons ---" >&2
72    [ -n "$ID" ] && xcrun notarytool log "$ID" --keychain-profile "$PROFILE" >&2
73    die "notarisation was not Accepted"
74  }
```
`release.sh` has `pipefail` set (line 15), so if `xcrun notarytool submit --wait` itself returns a
**non-zero exit status when the notarization is rejected** (not just on a transport/auth error —
this needs verifying against the current `notarytool` behavior, and this audit did not execute
anything to check it), the pipeline at 67-68 would fail and `set -e` would abort the script
*before* line 69's diagnostic block ever runs — meaning the code that prints Apple's actual
rejection reasons (70-72), the whole reason this block exists, would never execute on a real
rejection. The fact the author wrote 69-74 as a manual `grep`-based check at all suggests they
believed `notarytool` exits 0 regardless of Accepted/Invalid — if that belief is wrong, this is a
dead diagnostic path. **Recommend verifying** `xcrun notarytool submit --wait`'s exit code on a
known-rejected submission, or defensively wrapping line 67-68 as
`... | tee /tmp/chute-notary.log || true` so line 69 is always reached regardless.

### M4 — `install.sh` reuses a stale `dist/Chute.app` without checking its version
`/Users/sxope/Documents/2026/Development/37.chute/Scripts/install.sh:7`

```
7  [ -d "$APP" ] || "$ROOT/Scripts/build-app.sh"
```
Only builds if `dist/Chute.app` is entirely absent. If a developer pulls newer source and runs
`install.sh` without first deleting `dist/`, the previously-built (now stale) app gets installed
with no rebuild and no warning — `install.sh` will report success while installing old code. Not
in the six named hunt categories but adjacent to "ships a broken build." **Fix:** compare the
bundle's `CFBundleShortVersionString` against `Sources/ChuteCore/Version.swift`'s current value,
or just always rebuild.

---

## LOW

- **`build-app.sh:110-116`** — identity detection (`security find-identity … | sed … | head -1`)
  is a plain, unguarded assignment; unlike the rest of the script's graceful ad-hoc fallback
  philosophy, a hard `security` failure here would abort the whole build via `set -e` instead of
  falling back to `-` (ad-hoc) like every other branch in this file does.
- **`build-app.sh:174`** — `du -sh "$APP" | awk '{print "size: " $1}'` is a pipe; under
  `pipefail`, a `du` failure right here fails the *entire script* on its last line even though the
  build, sign, and install already fully succeeded — purely cosmetic but misleading exit code.
- **`release.sh:76-78`** — `xcrun stapler staple dist/Chute.app` / `staple "$DMG"` are unguarded
  (no `|| die`). A failure aborts cleanly via `set -e` but with no labeled error message. If
  `staple dist/Chute.app` succeeds and `staple "$DMG"` then fails, the local state is
  inconsistent, but this self-heals: any re-run rebuilds `dist/Chute.app` from scratch via
  `build-app.sh`'s `rm -rf "$APP"` (line 13), so nothing persists across a retry.
- **`release.sh:51`** — `codesign --verify --deep --strict --verbose=2 dist/Chute.app 2>&1 | tail
  -2` has no `|| die`. Because `pipefail` is set, a `codesign --verify` failure does correctly
  abort the script (this is NOT a silent-pass bug) — it's just an unfriendly raw-output stop
  instead of a clean `release: …` message.
- **No "dmg left mounted" finding** — confirmed `release.sh` never calls `hdiutil attach`;
  `hdiutil create -srcfolder` mounts and unmounts its own transient staging volume internally, so
  this named risk does not apply to this script.
- **`sign-identity.sh`** — no CRITICAL/HIGH/MEDIUM findings. `trap 'rm -rf "$TMP"' EXIT` is
  registered immediately after `mktemp -d` succeeds (line 24), all destructive operations are
  scoped to `$TMP`, and the PKCS#12 export password is a fixed string (`chute`, line 42) — low
  real risk since the `.p12` is ephemeral, local-only, and deleted by the trap, but worth noting.
- **`deploy-site.sh`** — no CRITICAL/HIGH/MEDIUM findings; consistently quoted, full `set -euo
  pipefail`, and gates the deploy behind `check:cases`/`check:claims`/`check:paddle` before
  publishing.
- **`packaging/homebrew/chute.rb:19`** — `system "swift", "build", "-c", "release", "--product",
  "chute", "--disable-sandbox"` has no comment explaining why the sandbox is disabled, unlike
  nearly everything else in this codebase's heavily "WHY"-commented style. `Package.swift:4`
  confirms zero external dependencies (`swift build stays offline and instant`), so the usual
  "SwiftPM needs network to resolve deps" justification for `--disable-sandbox` does not obviously
  apply here — worth a one-line comment recording the actual reason (likely SwiftPM writing into
  `~/Library/org.swift.swiftpm` or similar state Homebrew's sandbox blocks). Homebrew's `system`
  DSL raises on failure automatically (confirmed standard behavior — no missing error check).
  `depends_on macos: :ventura` correctly uses the version form only (matches the comment
  explaining why a bare `depends_on :macos` beside it would trigger a deprecation warning). The
  `sha256` value is a well-formed 64-char hex string; this audit could not verify it matches the
  real `v0.2.0` tarball (no network access used), but a mismatch fails loudly and safely at
  install time via Homebrew's own checksum verification, not silently. No hardcoded path or
  identifier specific to this developer's machine was found anywhere in the 8 audited files
  (checked via `grep -rn "sxope\|/Users/[a-z]"`).

---

## Area-by-area summary (per the task's 6 numbered hunts)

1. **Destructive ops hitting the wrong path** — C1 (`uninstall.sh`, empty `$HOME`) is the finding;
   `install.sh` shares the same root cause at a lower severity (overwrite, not pure delete). All
   `pkill -x ChuteApp` / `killall Finder` calls use exact-name matching, not a path variable, and
   are all `2>/dev/null || true` guarded — no findings there.
2. **Unquoted expansions** — none found. Every path-bearing variable across all 7 scripts is
   double-quoted; the one genuinely unquoted expansion (`build-app.sh:36`,
   `"$ROOT"/.build/release/ChuteCore.build/*.o`) is a deliberate glob that must stay unquoted to
   expand, and the unquoted portion contains no user-controlled or space-bearing path segment.
3. **`set -euo pipefail` discipline** — all 7 scripts have it (confirmed by grep, no exceptions).
   Silent-failure-as-success spots found anyway: M2 (`cloudflare-setup.sh`'s `grep -q … && … || …`
   pattern swallows real API failures into an always-0 exit), and H4 (`build-app.sh`'s `sign()`
   swallowing a real codesign error into a silent ad-hoc fallback). The literal `cmd | tail`/`|
   head` instances found (`release.sh:51`, `:35`, `:70`; `build-app.sh:111`) are all protected by
   `pipefail` and do propagate failure correctly — flagged as LOW only for unfriendly messaging.
4. **`release.sh` half-finished-state trace** — H1 (dry-run currently unusable), H2 (pushed tag,
   no release — and the inverse, local tag, not pushed), H3 (successful release reported as
   failure on the last line). DMG-left-mounted does not apply (see LOW section). Notarization
   failure and mid-build failures both self-heal on retry since `build-app.sh` rebuilds `dist/`
   from scratch every time.
5. **`build-app.sh` version stamping / silent ad-hoc** — version stamping is correct: one `sed`
   read of `Sources/ChuteCore/Version.swift` (line 8) feeds the identical `$VERSION` into both the
   appex's Info.plist (lines 49-50) and the app's Info.plist (lines 77-78) — no drift possible. The
   ad-hoc question is answered yes: see H4.
6. **`chute.rb` environment assumptions** — no hardcoded paths or credentials found; the one
   env-shaped question (`--disable-sandbox`) is flagged LOW for lacking a documented reason, not
   because it is wrong.
