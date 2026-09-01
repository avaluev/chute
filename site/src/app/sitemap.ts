import type { MetadataRoute } from "next"
import { CASES } from "@/lib/cases"
import { CONFIG } from "@/lib/config"

/**
 * DERIVED FROM THE ROUTES, not hand-listed. A sitemap someone maintains by hand is the same
 * failure as a claim someone maintains by hand: the 19 case pages are generated from `CASES`, so
 * the sitemap is too, and a new case cannot appear on the site without appearing here.
 *
 * `trailingSlash: true` in next.config.ts means Cloudflare Pages serves `/buy/`, not `/buy.html`.
 * The URLs below must match that or every one of them is a redirect Google has to follow.
 */
const STATIC = ["", "cases", "cli", "docs", "buy", "changelog", "building-with-agents",
                "support", "privacy", "terms", "refunds"]


// `output: "export"` has no server to run this at request time, so it must be declared
// static or the build refuses to collect the route. Measured: without it, `next build`
// fails with "export const dynamic = force-static not configured on route /sitemap.xml".
export const dynamic = "force-static"

export default function sitemap(): MetadataRoute.Sitemap {
  const base = `https://${CONFIG.domain}`
  const now = new Date()
  return [
    ...STATIC.map((p) => ({
      url: p ? `${base}/${p}/` : `${base}/`,
      lastModified: now,
      // The home page is the one a stranger lands on; the legal pages are not competing for
      // anything. Priorities are a hint, not a ranking factor — but a flat sitemap tells a
      // crawler nothing at all.
      priority: p === "" ? 1 : ["cases", "cli", "buy"].includes(p) ? 0.8 : 0.3,
    })),
    ...CASES.map((c) => ({
      url: `${base}/cases/${c.slug}/`,
      lastModified: now,
      priority: 0.6,
    })),
  ]
}
