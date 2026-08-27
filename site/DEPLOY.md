# Deploying chutedev.com

Host: **Cloudflare Pages**. The DNS for `chutedev.com` already lives at Cloudflare, so Pages
attaches the custom domain and provisions TLS itself — no A records to copy, no AAAA records, and
no chance of the grey-cloud trap that silently fails certificate provisioning when the proxy is
left on.

It also serves at the **root**, which is why the site no longer needs a base path. A GitHub
project page is served from `/<repo>/`, and Next emits absolute asset URLs, so that build returned
HTTP 200 on the document while every stylesheet, script and image 404'd. That whole class of bug
does not exist here.

## Once

1. **Authenticate.** This opens a browser and stores the token in your OS keychain — never in this
   repository, never in shell history.

   ```bash
   npx wrangler login
   ```

   Expected: `Successfully logged in.` Confirm with:

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute/site && npx wrangler whoami
   ```

2. **Create the project** (first deploy creates it; this only names it explicitly).

   ```bash
   cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/deploy-site.sh
   ```

   Expected: a `https://chute-<hash>.pages.dev` URL.

3. **Attach the domain.** Dashboard → Workers & Pages → `chute` → Custom domains → Set up a custom
   domain → `chutedev.com`. Add `www.chutedev.com` too. Because the zone is already on Cloudflare,
   the DNS record and the certificate are created for you; there is nothing to paste.

   Expected: both domains reach **Active** within a few minutes.

4. **Turn off GitHub Pages**, so there is exactly one live copy of this site and no stale one to
   confuse a search engine or a reviewer:

   ```bash
   gh api -X DELETE repos/avaluev/chute/pages
   ```

## Every time

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/deploy-site.sh
```

It regenerates the design tokens and the social card from `brand/tokens.json`, builds, runs
`check:paddle`, and refuses to publish if any check fails. `--preview` deploys to a preview URL
and leaves production alone.

## Before submitting the domain to Paddle

A rejected domain review costs 5–7 business days on resubmission, and every documented failure
mode is mechanical. Run the gate, then confirm the live site:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute/site && npm run check:paddle
```

```bash
for p in "" terms/ refunds/ privacy/ buy/ support/ docs/; do \
  printf "%-40s %s\n" "https://chutedev.com/$p" \
  "$(curl -s -o /dev/null -w '%{http_code}' -L "https://chutedev.com/$p")"; done
```

Expected: `200` on every line. Then check the one thing no script can: open the page and look at
it. Twice today a build that compiled and returned 200 was visibly broken — once rendering with no
CSS at all, once with every image missing.

## Not used any more

`Scripts/cloudflare-setup.sh` creates the A/AAAA/CNAME records GitHub Pages would have needed. It
is kept for the day the host changes back, and it is not part of this flow.
