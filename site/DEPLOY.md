# Deploying chutedev.com to GitHub Pages

The workflow (`/Users/sxope/Documents/2026/Development/37.chute/.github/workflows/pages.yml`)
builds and uploads the site. These are the one-time repo and DNS steps it depends on.

## 1. Make the repo public (if still private)

```
cd /Users/sxope/Documents/2026/Development/37.chute && gh repo edit avaluev/chute --visibility public --accept-visibility-change-consequences
```

Expected output: no error; `gh repo view avaluev/chute --json visibility` prints `"PUBLIC"`.

## 2. Enable Pages, source = GitHub Actions

```
cd /Users/sxope/Documents/2026/Development/37.chute && gh api -X PUT repos/avaluev/chute/pages -f build_type=workflow
```

Expected output: JSON with `"build_type": "workflow"`. (Equivalent UI path: repo Settings →
Pages → Build and deployment → Source → "GitHub Actions".)

## 3. Add the custom domain

```
cd /Users/sxope/Documents/2026/Development/37.chute && gh api -X PUT repos/avaluev/chute/pages -f cname=chutedev.com
```

Expected output: JSON with `"cname": "chutedev.com"`. (UI path: Settings → Pages → Custom
domain → enter `chutedev.com` → Save. This also writes `site/public/CNAME`, which the repo
already carries at
`/Users/sxope/Documents/2026/Development/37.chute/site/public/CNAME` — don't let GitHub's
auto-commit fight with the checked-in one; they should agree.)

## 4. DNS records on Cloudflare

Apex `chutedev.com` → four GitHub Pages A records. `www` → GitHub's Pages hostname.

| Type  | Name | Value              |
|-------|------|---------------------|
| A     | @    | 185.199.108.153      |
| A     | @    | 185.199.109.153      |
| A     | @    | 185.199.110.153      |
| A     | @    | 185.199.111.153      |
| CNAME | www  | avaluev.github.io    |

```
cd /Users/sxope/Documents/2026/Development/37.chute && for ip in 185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153; do
  echo "add A @ -> $ip"
done
```

(Run the equivalent `A`/`CNAME` creates in the Cloudflare dashboard or via the Cloudflare API —
the loop above is just the list to enter, Cloudflare has no bulk-add CLI here.)

## 5. THE TRAP — proxy must be OFF (grey cloud / DNS-only)

Cloudflare defaults new records to **Proxied** (orange cloud). Leave that on and GitHub's
Let's Encrypt certificate challenge for `chutedev.com` cannot validate — Pages will sit
forever on "the certificate is being provisioned" with no error, because Cloudflare's edge is
answering for the domain instead of letting GitHub's ACME challenge and the Pages origin
through.

For **all five records above** (the four apex A records and the `www` CNAME): click the cloud
icon in the Cloudflare DNS table until it is **grey ("DNS only")**, not orange ("Proxied").

Expected: the Cloudflare DNS table shows a grey cloud on each of the 5 rows.

## 6. Verify

```
cd /Users/sxope/Documents/2026/Development/37.chute && dig +short chutedev.com A
```

Expected output: the four `185.199.10x.153` addresses, directly — not a Cloudflare IP (`104.x`
or `172.x`), which is the tell that a record is still proxied.

```
cd /Users/sxope/Documents/2026/Development/37.chute && gh api repos/avaluev/chute/pages | grep -A2 https_certificate
```

Expected output: `"status": "approved"` once DNS propagates and GitHub issues the cert
(can take a few minutes to a few hours).
