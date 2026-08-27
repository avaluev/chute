import type { NextConfig } from "next";

/**
 * Static export, because the host is GitHub Pages: no Node runtime, no image optimiser, no
 * middleware. Everything the site does is either HTML or a Paddle overlay opened by the browser.
 */
/**
 * Static export. The host is Cloudflare Pages, which serves the site at the ROOT of
 * chutedev.com — so there is no base path, and the PAGES_BASE_PATH kludge that a GitHub project
 * page needed is gone with it.
 *
 * It stays readable from the environment for one reason only: a preview deployment served from a
 * subpath would break every asset the same way, silently, and leaving the hook costs one line.
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
