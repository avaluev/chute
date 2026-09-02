#!/usr/bin/env bash
# Point chutedev.com at the Cloudflare Pages project. Idempotent — safe to re-run.
#
# PROXY ON, DELIBERATELY. An earlier version of this script targeted GitHub Pages, where the
# orange cloud MUST be off or certificate provisioning fails. Cloudflare Pages is the opposite:
# the record is proxied, Cloudflare terminates TLS itself, and there is no ACME challenge to
# break. Do not carry the old advice across — it is correct for the other host and wrong here.
#
# CNAME AT THE APEX is legal here because Cloudflare flattens it. On a registrar without
# flattening this would need A records instead.
#
# CREDENTIAL. `wrangler login` grants pages:write but NOT dns_records:write, so wrangler cannot
# do this. Create a token scoped to this zone only:
#
#   https://dash.cloudflare.com/profile/api-tokens → Create Token → "Edit zone DNS"
#     Permissions     Zone · DNS · Edit
#     Zone Resources  Include · Specific zone · chutedev.com
#
#   printf '%s' 'PASTE_TOKEN_HERE' > ~/.cf-token && chmod 600 ~/.cf-token
#
# It is read from a 0600 file or the environment, never an argument — a token in shell history is
# a token awaiting publication. This repository already leaked one credential; once was enough.
set -euo pipefail

DOMAIN="chutedev.com"
TARGET="chute.pages.dev"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

TOKEN="${CLOUDFLARE_API_TOKEN:-}"
[ -z "$TOKEN" ] && [ -f "$HOME/.cf-token" ] && TOKEN="$(cat "$HOME/.cf-token")"
if [ -z "$TOKEN" ]; then
  cat >&2 <<'MSG'
cloudflare-setup: no DNS token.

  `wrangler login` is not enough — it grants pages:write but not dns_records:write.

  1. https://dash.cloudflare.com/profile/api-tokens → Create Token → "Edit zone DNS"
     Permissions     Zone · DNS · Edit
     Zone Resources  Include · Specific zone · chutedev.com
  2. printf '%s' 'PASTE_TOKEN_HERE' > ~/.cf-token && chmod 600 ~/.cf-token
  3. re-run this script
MSG
  exit 1
fi

# The token reaches curl through a config on stdin, never as an argument: `-H "Bearer …"` is
# readable by every local process through `ps` for the life of the request, which is exactly
# what the file mode above was protecting against.
api() {
  local method="$1" path="$2" body="${3:-}"
  {
    printf 'header = "Authorization: Bearer %s"\n' "$TOKEN"
    printf 'header = "Content-Type: application/json"\n'
    [ -n "$body" ] && printf 'data = %s\n' "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$body")"
    true
  } | curl -sS -X "$method" "https://api.cloudflare.com/client/v4$path" --config -
}
RC=0
step() { printf '\n\033[1m→ %s\033[0m\n' "$1"; }
die()  { echo "cloudflare-setup: $1" >&2; exit 1; }

step "Zone"
ZONE_ID="$(api GET "/zones?name=$DOMAIN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
if not d.get('success'):
    sys.stderr.write('; '.join(e.get('message','?') for e in d.get('errors',[]))+'\n'); sys.exit(1)
r=d['result']; print(r[0]['id'] if r else '')")" || die "the API rejected the token"
[ -n "$ZONE_ID" ] || die "$DOMAIN is not in this account, or the token cannot see it"
echo "  ${ZONE_ID:0:8}…"

put_cname() { # NAME
  local name="$1"
  local body; body="$(python3 -c "
import json,sys
print(json.dumps({'type':'CNAME','name':sys.argv[1],'content':sys.argv[2],
                  'ttl':1,'proxied':True,'comment':'Cloudflare Pages — proxied on purpose'}))
" "$name" "$TARGET")"
  local id; id="$(api GET "/zones/$ZONE_ID/dns_records?name=$name" | python3 -c "
import json,sys
r=json.load(sys.stdin).get('result') or []
print(r[0]['id'] if r else '')")"
  if [ -n "$id" ]; then
    [ "$DRY" = "1" ] && { echo "  would UPDATE $name → $TARGET"; return; }
    api PUT "/zones/$ZONE_ID/dns_records/$id" "$body" | grep -q '"success":true' \
      && echo "  updated  $name → $TARGET (proxied)" || { echo "  FAILED   $name"; RC=1; }
  else
    [ "$DRY" = "1" ] && { echo "  would CREATE $name → $TARGET"; return; }
    local out; out="$(api POST "/zones/$ZONE_ID/dns_records" "$body")"
    echo "$out" | grep -q '"success":true' \
      && echo "  created  $name → $TARGET (proxied)" \
      || { echo "  FAILED   $name : $(echo "$out" | head -c 200)"; RC=1; }
  fi
}

step "Records"
put_cname "$DOMAIN"
put_cname "www.$DOMAIN"

step "SSL mode"
# Full, not Flexible. Flexible talks HTTP to the origin and Pages redirects HTTP to HTTPS, which
# is an infinite redirect loop.
if [ "$DRY" = "1" ]; then echo "  would set full"; else
  api PATCH "/zones/$ZONE_ID/settings/ssl" '{"value":"full"}' | grep -q '"success":true' \
    && echo "  ssl = full" || echo "  could not set SSL (token lacks Zone Settings:Edit — set it in the dashboard)"
fi

step "Next"
cat <<MSG
  dig +short $DOMAIN                       expect a Cloudflare address
  curl -sI https://$DOMAIN | head -1       expect HTTP/2 200

Certificates are issued by Cloudflare within a few minutes of the record appearing.
MSG
# A failed record write above set RC; the "Next" block is only advice if it is 0.
exit "$RC"
