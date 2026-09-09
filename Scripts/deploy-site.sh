#!/usr/bin/env bash
# Build and publish chutedev.com to Cloudflare Pages.
#
# WHY CLOUDFLARE PAGES AND NOT GITHUB PAGES. The DNS for chutedev.com already lives at
# Cloudflare, so Pages attaches the custom domain and provisions TLS itself — no A records, no
# AAAA records, and no chance of the grey-cloud trap that silently fails certificate provisioning
# when the proxy is left on. It also serves at the ROOT, which removes the base-path workaround a
# GitHub project page needs and the entire class of asset-404 bugs that came with it.
#
# WHY NOT A CI WORKFLOW, YET. Deploying from CI means putting a Cloudflare API token into GitHub
# secrets. This repository leaked a credential once today already. One command locally, with the
# token in the OS keychain via `wrangler login`, is both safer and faster at this cadence. Move it
# to CI when the cadence justifies the exposure.
#
#   ./Scripts/deploy-site.sh              deploy to production
#   ./Scripts/deploy-site.sh --preview    a preview URL, nothing touched in production
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="chute"
cd "$ROOT/site"

npx wrangler whoami >/dev/null 2>&1 || {
  echo "not authenticated. Run this once, in your own terminal, and approve in the browser:" >&2
  echo "  npx wrangler login" >&2
  exit 1
}

echo "→ regenerating design tokens and social assets"
npm run tokens
npm run assets

# ONE SOURCE FOR THE INSTALL SCRIPT. chutedev.com/install.sh is what the site tells people to
# pipe into a shell; it must be the file in this repo that CI can see, not a second copy someone
# edits and forgets.
cp "$ROOT/Scripts/get.sh" public/install.sh

echo "→ building"
npx next build

echo "→ checking before publishing"
# Every figure on the site is re-derived from the JTBD ledger before it can be published. A
# number nobody can trace is indistinguishable from one that was invented.
npm run check:cases
# The fact sheet's FALSE table, enforced against the rendered pages. Three false claims reached
# the live site before this existed; a rule a human has to remember gets broken.
npm run check:claims
# `next build` type-checks but does not lint; an eslint ERROR was sitting in checkout-bridge
# with nothing failing on it.
npm run lint

BRANCH="main"
[ "${1:-}" = "--preview" ] && BRANCH="preview"

echo "→ deploying to Cloudflare Pages (branch: $BRANCH)"
npx wrangler pages deploy out --project-name "$PROJECT" --branch "$BRANCH" --commit-dirty=true

# ── THE DEPLOY IS NOT DONE UNTIL THE LIVE PAGE CAN STYLE ITSELF ────────────────────────────
#
# On 2026-09-09 a deploy published an index.html referencing a stylesheet that had not been
# uploaded. Cloudflare answers a missing file with the fallback HTML page — 200, text/html — so
# the browser refused to apply it and the site rendered as UNSTYLED HTML: body in Times, every
# grid blown out, 578px of horizontal overflow. It stayed that way, live, while three separate
# checks reported success.
#
# THE STATUS CODE CANNOT SEE THIS. Every asset returned 200, because a fallback page IS a 200.
# Only the CONTENT-TYPE distinguishes "here is your stylesheet" from "here is a page saying I
# could not find your stylesheet". This checks what the deployed HTML actually asks for, and
# that each answer is the kind of thing it asked for.
#
# Same shape as the Homebrew trap in packaging/homebrew/chute.rb: the obvious check (brew
# install / HTTP 200) is structurally incapable of detecting the failure.
[ "$BRANCH" = "main" ] || exit 0
echo "→ verifying the live page can style itself"
SITE="https://chutedev.com"
sleep 5
fail=0
for attempt in 1 2 3 4 5 6 7 8 9 10; do
  fail=0
  html="$(curl -fsS "$SITE/?deploycheck=$RANDOM" || true)"
  if [ -z "$html" ]; then fail=1; else
    refs="$(printf '%s' "$html" | grep -oE '/_next/static/[^"]+\.(css|js)' | sort -u)"
    [ -n "$refs" ] || fail=1
    for ref in $refs; do
      ct="$(curl -fsS -o /dev/null -w '%{content_type}' "$SITE$ref" || echo none)"
      case "$ref" in
        *.css) case "$ct" in text/css*) ;; *) fail=1; bad="$ref → $ct";; esac ;;
        *.js)  case "$ct" in *javascript*) ;; *) fail=1; bad="$ref → $ct";; esac ;;
      esac
    done
  fi
  [ "$fail" -eq 0 ] && break
  echo "   not consistent yet (attempt $attempt/10) — edges still rolling out"
  sleep 12
done
if [ "$fail" -ne 0 ]; then
  echo "deploy-site: THE LIVE SITE IS SERVING A BROKEN ASSET: ${bad:-no assets found}" >&2
  echo "             The page will render unstyled. Re-run this script; if it persists, the" >&2
  echo "             upload dropped a file — check 'npx wrangler pages deployment list'." >&2
  exit 1
fi
echo "   every stylesheet and script the live page references answers with its own type"
# NOT CHECKED HERE, AND WORTH KNOWING: /media/* filenames carry no content hash, and Cloudflare
# serves them `max-age=14400` — so for up to FOUR HOURS after a deploy an edge can still hand out
# the OLD image or video while the HTML around it is new. On 2026-09-09 that looked exactly like
# a failed upload: the site had just been redeployed with cropped recordings and the live .mp4
# still measured 1280x800. It was stale, not missing, and `?cb=$RANDOM` returned the new file.
# Before concluding a media file did not deploy, re-request it with a query string.
