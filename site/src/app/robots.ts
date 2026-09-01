import type { MetadataRoute } from "next"
import { CONFIG } from "@/lib/config"

/**
 * EVERY CRAWLER IS WELCOME, INCLUDING THE AI ONES — deliberately, and this is the decision worth
 * writing down rather than the file.
 *
 * A publisher with an ad business blocks GPTBot, ClaudeBot and PerplexityBot because a cited
 * answer replaces a visit they were selling. Chute sells a $19 download to people who ask a
 * coding agent how to get their codebase into Claude Code. Being the thing that answer names IS
 * the distribution. Blocking those crawlers would remove the product from the exact conversation
 * it exists to win, in exchange for page views nobody is monetising.
 *
 * So there is no `Disallow` here beyond the build artefacts, and no allow-list either: an
 * allow-list is a list to keep in sync, and a new crawler this file has not heard of is one this
 * site wants.
 */

// `output: "export"` has no server to run this at request time, so it must be declared
// static or the build refuses to collect the route. Measured: without it, `next build`
// fails with "export const dynamic = force-static not configured on route /robots.txt".
export const dynamic = "force-static"

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: "*", allow: "/" }],
    sitemap: `https://${CONFIG.domain}/sitemap.xml`,
  }
}
