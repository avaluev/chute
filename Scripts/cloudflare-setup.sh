#!/usr/bin/env bash
# Point chutedev.com at GitHub Pages, via the Cloudflare API. Idempotent — safe to re-run.
#
# THE TRAP THIS SCRIPT EXISTS TO AVOID: Cloudflare's orange-cloud proxy must be OFF on these
# records. With it on, GitHub cannot complete the ACME challenge, certificate provisioning fails
# silently, and the site serves a certificate error for the domain you just paid for. Every record
# below is created with "proxied": false, deliberately.
#
# CREDENTIAL. Never passed on the command line and never echoed — a token in shell history or a
# transcript is a token that must be rotated. Create one scoped to this zone only:
#
#   https://dash.cloudflare.com/profile/api-tokens  →  Create Token  →  Edit zone DNS
#     Permissions : Zone · DNS · Edit
#     Zone Resources : Include · Specific zone · chutedev.com
#
#   printf '%s' 'PASTE_TOKEN_HERE' > ~/.cf-token && chmod 600 ~/.cf-token
#
# USAGE
#   ./Scripts/cloudflare-setup.sh            apply
#   ./Scripts/cloudflare-setup.sh --dry-run  print what it would do, change nothing
set -euo pipefail

DOMAIN="chutedev.com"
PAGES_HOST="avaluev.github.io"
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1

# GitHub Pages apex addresses. https://docs.github.com/pages/configuring-a-custom-domain-for-your-github-pages-site
A_RECORDS=(185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153)
AAAA_RECORDS=(2606:50c0:8000::153 2606:50c0:8001::153 2606:50c0:8002::153 2606:50c0:8003::153)

TOKEN="${CLOUDFLARE_API_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -f "$HOME/.cf-token" ]; then TOKEN="$(cat "$HOME/.cf-token")"; fi
if [ -z "$TOKEN" ]; then
  cat >&2 <<'MSG'
cloudflare-setup: no API token.

  1. https://dash.cloudflare.com/profile/api-tokens → Create Token → "Edit zone DNS"
     Permissions      Zone · DNS · Edit
     Zone Resources   Include · Specific zone · chutedev.com
  2. printf '%s' 'PASTE_TOKEN_HERE' > ~/.cf-token && chmod 600 ~/.cf-token
  3. re-run this script
MSG
  exit 1
fi

api() { # METHOD PATH [BODY]
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    curl -sS -X "$method" "https://api.cloudflare.com/client/v4$path" \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" --data "$body"
  else
    curl -sS -X "$method" "https://api.cloudflare.com/client/v4$path" \
      -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json"
  fi
}

jq_get() { python3 -c "import json,sys; d=json.load(sys.stdin); print(eval('d'+sys.argv[1]) if d else '')" "$1" 2>/dev/null || true; }

step() { printf '\n\033[1m→ %s\033[0m\n' "$1"; }
die()  { echo "cloudflare-setup: $1" >&2; exit 1; }

# ---------------------------------------------------------------- the zone
step "Finding the zone for $DOMAIN"
ZONE_JSON="$(api GET "/zones?name=$DOMAIN")"
echo "$ZONE_JSON" | grep -q '"success":true' || die "the API rejected the token: $(echo "$ZONE_JSON" | head -c 300)"
ZONE_ID="$(printf '%s' "$ZONE_JSON" | python3 -c "
import json,sys
r=json.load(sys.stdin)['result']
print(r[0]['id'] if r else '')")"
[ -n "$ZONE_ID" ] || die "$DOMAIN is not in this Cloudflare account, or the token cannot see it"
echo "  zone ${ZONE_ID:0:8}…"

# ---------------------------------------------------------------- records
existing() { # TYPE NAME -> "id content proxied" lines
  api GET "/zones/$ZONE_ID/dns_records?type=$1&name=$2&per_page=100" | python3 -c "
import json,sys
for r in json.load(sys.stdin).get('result',[]):
    print(r['id'], r['content'], str(r.get('proxied',False)).lower())"
}

put_record() { # TYPE NAME CONTENT
  local type="$1" name="$2" content="$3"
  local body
  body="$(python3 -c "
import json,sys
print(json.dumps({'type':sys.argv[1],'name':sys.argv[2],'content':sys.argv[3],
                  'ttl':1,'proxied':False,'comment':'GitHub Pages — proxy MUST stay off'}))
" "$type" "$name" "$content")"

  local match
  match="$(existing "$type" "$name" | awk -v c="$content" '$2==c {print $1, $3}')"
  if [ -n "$match" ]; then
    local id proxied; id="${match%% *}"; proxied="${match##* }"
    if [ "$proxied" = "true" ]; then
      [ "$DRY" = "1" ] && { echo "  would UNPROXY $type $name $content"; return; }
      api PUT "/zones/$ZONE_ID/dns_records/$id" "$body" >/dev/null
      echo "  unproxied  $type $name → $content"
    else
      echo "  ok         $type $name → $content"
    fi
    return
  fi
  [ "$DRY" = "1" ] && { echo "  would CREATE $type $name $content"; return; }
  local out; out="$(api POST "/zones/$ZONE_ID/dns_records" "$body")"
  echo "$out" | grep -q '"success":true' \
    && echo "  created    $type $name → $content" \
    || echo "  FAILED     $type $name → $content : $(echo "$out" | head -c 200)"
}

step "Apex A records (proxy off)"
for ip in "${A_RECORDS[@]}"; do put_record A "$DOMAIN" "$ip"; done

step "Apex AAAA records (proxy off)"
for ip in "${AAAA_RECORDS[@]}"; do put_record AAAA "$DOMAIN" "$ip"; done

step "www → $PAGES_HOST (proxy off)"
put_record CNAME "www.$DOMAIN" "$PAGES_HOST"

# ---------------------------------------------------------------- records that would break it
step "Removing records that would fight these"
api GET "/zones/$ZONE_ID/dns_records?per_page=100" | python3 -c "
import json,sys
keep_a = set(sys.argv[1].split()); keep_aaaa = set(sys.argv[2].split())
for r in json.load(sys.stdin).get('result',[]):
    n, t, c = r['name'], r['type'], r['content']
    stale = (
        (t=='A'    and n=='$DOMAIN'      and c not in keep_a) or
        (t=='AAAA' and n=='$DOMAIN'      and c not in keep_aaaa) or
        (t=='CNAME'and n=='$DOMAIN') or
        (t=='CNAME'and n=='www.$DOMAIN'  and c!='$PAGES_HOST')
    )
    if stale: print(r['id'], t, n, c)
" "${A_RECORDS[*]}" "${AAAA_RECORDS[*]}" | while read -r id t n c; do
  [ -z "${id:-}" ] && continue
  if [ "$DRY" = "1" ]; then echo "  would DELETE $t $n → $c"; else
    api DELETE "/zones/$ZONE_ID/dns_records/$id" >/dev/null && echo "  deleted    $t $n → $c"
  fi
done
echo "  (nothing listed = nothing conflicting)"

# ---------------------------------------------------------------- TLS
# Flexible SSL terminates TLS at Cloudflare and talks HTTP to the origin. GitHub Pages redirects
# HTTP to HTTPS, so Flexible produces an infinite redirect loop. Full is the minimum that works;
# with the proxy off it is moot today, and correct the day anyone turns the proxy on.
step "SSL mode"
if [ "$DRY" = "1" ]; then echo "  would set SSL to full"; else
  api PATCH "/zones/$ZONE_ID/settings/ssl" '{"value":"full"}' \
    | grep -q '"success":true' && echo "  ssl = full" || echo "  could not set SSL (token may lack Zone Settings:Edit — set it by hand)"
fi

step "Done"
cat <<MSG
Next, in order:

  1. Wait for DNS, then confirm it resolves to GitHub:
       dig +short $DOMAIN

  2. Tell GitHub Pages about the domain (only AFTER step 1 answers with 185.199.x.x):
       gh api -X PUT repos/avaluev/chute/pages -f cname=$DOMAIN -F https_enforced=true

  3. Remove the temporary base path — the site moves to the root:
       delete the PAGES_BASE_PATH lines from .github/workflows/pages.yml, then
       gh workflow run pages.yml --ref main

  4. Verify:
       curl -sI https://$DOMAIN | head -1
MSG
