# Chute Marketing Site

The Next.js site for chutedev.com. Hosted on **Cloudflare Pages** at the root domain.

## Development

```bash
npm run dev
```

Opens http://localhost:3000. The page reloads as you edit.

## Build

```bash
npm run build
```

Exports static HTML to `out/`. The site does not need a runtime.

## Content

- **Cases** (`site/src/lib/cases.ts`): Job listings and customer stories.
- **Guides** (`docs/BUILDING-WITH-AGENTS.md`): Rendered at `/building-with-agents`.
- **Claims** (`docs/FACT-SHEET.md`): Drives the fact-check gate.

## Deployment

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/deploy-site.sh
```

Regenerates design tokens, builds, runs gates (`npm run check:cases`, `npm run check:claims`), and deploys to Cloudflare Pages. See [DEPLOY.md](./DEPLOY.md) for details.
