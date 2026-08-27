import type { NextConfig } from "next";

/**
 * Static export, because the host is GitHub Pages: no Node runtime, no image optimiser, no
 * middleware. Everything the site does is either HTML or a Paddle overlay opened by the browser.
 */
/**
 * BASE PATH — temporary, and delete it the day chutedev.com resolves.
 *
 * A GitHub project page is served from /<repo>/, not from the root. Next emits ABSOLUTE asset
 * URLs, so a default build asks for /_next/static/… while the files actually live at
 * /chute/_next/static/… — the HTML returns 200 and every stylesheet, script and image 404s.
 * The result is a page of unstyled serif text, which is what was published earlier today.
 *
 * On the custom domain the site IS at the root and basePath must be empty again. So it is an
 * environment variable, set only by the Pages workflow, with the removal step written down:
 * when chutedev.com is live, delete PAGES_BASE_PATH from .github/workflows/pages.yml.
 */
const basePath = process.env.PAGES_BASE_PATH ?? "";

const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },   // no optimiser exists on Pages; unoptimised or broken
  trailingSlash: true,             // Pages serves /buy/ as a directory, not /buy.html
  basePath,
  env: { NEXT_PUBLIC_BASE_PATH: basePath },
};

export default nextConfig;
