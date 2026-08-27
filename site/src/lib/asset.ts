/**
 * Prefix a public-folder path with the build's base path.
 *
 * next/image applies the base path through its loader — but `unoptimized: true` bypasses that
 * loader entirely, so on a project-page build every <Image src="/media/…"> resolved to the
 * DOMAIN ROOT and 404'd while every link and stylesheet resolved correctly. The page looked
 * right apart from having no images, which is the sort of half-broken that survives a glance.
 *
 * NEXT_PUBLIC_BASE_PATH is set from next.config.ts, so this is "" on the custom domain and the
 * call is a no-op there. Use it for anything read out of public/.
 */
const BASE = process.env.NEXT_PUBLIC_BASE_PATH ?? "";

export function asset(path: string): string {
  return `${BASE}${path.startsWith("/") ? path : `/${path}`}`;
}
