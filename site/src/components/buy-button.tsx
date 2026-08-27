"use client";

import Script from "next/script";
import { useState } from "react";
import { buttonVariants } from "@/components/ui/button";
import { CONFIG } from "@/lib/config";

/**
 * The checkout, and its honest fallback.
 *
 * Paddle is not configured until the seller account exists. Rather than render a button that
 * opens nothing — the worst possible state for a page whose entire job is taking money — this
 * checks for the price ID and, when it is missing, sends people to the free trial instead and
 * says so plainly.
 */
export function BuyButton() {
  const [ready, setReady] = useState(false);
  const configured = Boolean(CONFIG.paddle.token && CONFIG.paddle.priceId);

  if (!configured) {
    return (
      <div className="rounded-[var(--radius)] border border-border bg-card p-6">
        <p className="text-foreground">
          Checkout is not open yet — Chute is still in its trial-only release.
        </p>
        <p className="mt-2 text-sm">
          Take the {CONFIG.trialDays}-day trial now; it is the full app, and you will be able to
          buy a key from inside it the moment this opens.
        </p>
        <a href={CONFIG.download}
           className={buttonVariants({ size: "lg" }) + " mt-5 h-11 px-5 text-base font-medium"}>
          Download for macOS — free {CONFIG.trialDays}-day trial
        </a>
      </div>
    );
  }

  return (
    <>
      <Script src="https://cdn.paddle.com/paddle/v2/paddle.js" strategy="afterInteractive"
              onLoad={() => {
                if (!window.Paddle) return;
                if (CONFIG.paddle.environment === "sandbox") window.Paddle.Environment.set("sandbox");
                window.Paddle.Initialize({ token: CONFIG.paddle.token });
                setReady(true);
              }} />
      <div className="rounded-[var(--radius)] border border-[var(--color-accent-chute)] bg-card p-6">
        <p className="font-[family-name:var(--font-mono-loaded)] text-3xl font-semibold text-foreground">
          {CONFIG.price} <span className="text-base font-normal text-muted-foreground">once</span>
        </p>
        <button
          disabled={!ready}
          onClick={() => window.Paddle?.Checkout.open({
            items: [{ priceId: CONFIG.paddle.priceId, quantity: 1 }],
          })}
          className={buttonVariants({ size: "lg" }) + " mt-5 h-11 w-full px-5 text-base font-medium disabled:opacity-60"}
        >
          {ready ? "Buy Chute" : "Loading checkout…"}
        </button>
        <p className="mt-3 text-center text-xs text-muted-foreground">
          {CONFIG.refundDays}-day refund, no questions asked. VAT handled by Paddle.
        </p>
      </div>
    </>
  );
}
