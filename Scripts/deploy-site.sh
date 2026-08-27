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

echo "→ building"
npx next build

echo "→ checking before publishing"
# Every figure on the site is re-derived from the JTBD ledger before it can be published. A
# number nobody can trace is indistinguishable from one that was invented.
npm run check:cases
npm run check:paddle

BRANCH="main"
[ "${1:-}" = "--preview" ] && BRANCH="preview"

echo "→ deploying to Cloudflare Pages (branch: $BRANCH)"
npx wrangler pages deploy out --project-name "$PROJECT" --branch "$BRANCH" --commit-dirty=true
