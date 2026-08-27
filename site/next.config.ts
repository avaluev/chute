import type { NextConfig } from "next";

/**
 * Static export, because the host is GitHub Pages: no Node runtime, no image optimiser, no
 * middleware. Everything the site does is either HTML or a Paddle overlay opened by the browser.
 */
const nextConfig: NextConfig = {
  output: "export",
  images: { unoptimized: true },   // no optimiser exists on Pages; unoptimised or broken
  trailingSlash: true,             // Pages serves /buy/ as a directory, not /buy.html
};

export default nextConfig;
