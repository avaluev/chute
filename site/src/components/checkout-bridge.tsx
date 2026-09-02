"use client";

/**
 * Opens a checkout when Paddle redirects a buyer back here with a transaction.
 *
 * WHY THIS EXISTS. Paddle's "default payment link" is a REQUIRED account setting — without it,
 * creating a transaction fails outright with "Something went wrong." It names the page Paddle
 * sends buyers to whenever it needs a checkout rendered that did not start in our own UI: an
 * invoice link, a card update, a checkout opened through the API. Paddle appends `?_ptxn=txn_…`.
 *
 * With that setting pointed at a page that does NOT mount this, the buyer lands on a pricing page
 * with no checkout and no explanation — worse than the error it replaced.
 *
 * IT RENDERS NOTHING in the ordinary case, and that is the point: the parameter is absent on every
 * normal visit, so this costs one URLSearchParams read and stops. The SDK loads only when a
 * transaction is actually present, so someone reading /buy never downloads a payment SDK.
 *
 * IT NEVER FAILS SILENTLY. If a buyer arrives WITH a transaction and checkout will not open, they
 * are told so and given somewhere to go. A blank page after clicking "pay" is the worst outcome
 * available here: the customer concludes it half-worked, then either retries (duplicate charge) or
 * disputes it (chargeback fee).
 */

import { useEffect, useState } from "react";
import { CONFIG } from "@/lib/config";

type State =
  | { status: "idle" }
  | { status: "opening" }
  | { status: "open" }
  | { status: "failed"; reason: string };

/** Paddle's parameter name. Exported so the check script can assert it is still handled. */
export const TRANSACTION_PARAM = "_ptxn";

export function transactionIdFromSearch(search: string): string | null {
  const id = new URLSearchParams(search).get(TRANSACTION_PARAM);
  return id && id.startsWith("txn_") ? id : null;
}

export function CheckoutBridge() {
  const [state, setState] = useState<State>({ status: "idle" });

  useEffect(() => {
    const transactionId = transactionIdFromSearch(window.location.search);
    if (!transactionId) return;

    // Guards a state update after unmount: React StrictMode mounts effects twice in development,
    // and loading the SDK is async.
    let live = true;

    (async () => {
      // After a tick, not synchronously in the effect body — a state update there re-renders
      // before the first paint has settled, and the lint rule for it is an error, not a style.
      await Promise.resolve();
      if (live) setState({ status: "opening" });
      if (!CONFIG.paddle.token) {
        if (live) setState({ status: "failed", reason: "Checkout is not configured yet." });
        return;
      }
      try {
        await loadPaddle();
        const paddle = window.Paddle;
        if (!paddle) throw new Error("SDK did not attach");
        if (CONFIG.paddle.environment === "sandbox") paddle.Environment.set("sandbox");
        paddle.Initialize({ token: CONFIG.paddle.token });
        paddle.Checkout.open({ transactionId });
        if (live) setState({ status: "open" });
      } catch {
        if (live) setState({ status: "failed", reason: "The checkout could not be opened." });
      }
    })();

    return () => { live = false; };
  }, []);

  if (state.status === "idle" || state.status === "open") return null;

  if (state.status === "opening") {
    return (
      <p role="status" aria-live="polite" className="rounded-[var(--radius)] border border-border bg-card p-4 text-sm">
        Opening your checkout…
      </p>
    );
  }

  return (
    <p role="alert" className="rounded-[var(--radius)] border border-destructive bg-card p-4 text-sm">
      {state.reason} Nothing has been charged. Email{" "}
      <a className="text-foreground underline underline-offset-4" href={`mailto:${CONFIG.contact}`}>
        {CONFIG.contact}
      </a>{" "}
      and it will be sorted out by hand.
    </p>
  );
}

function loadPaddle(): Promise<void> {
  if (window.Paddle) return Promise.resolve();
  return new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = "https://cdn.paddle.com/paddle/v2/paddle.js";
    s.onload = () => resolve();
    s.onerror = () => reject(new Error("paddle.js failed to load"));
    document.head.appendChild(s);
  });
}

declare global {
  interface Window {
    Paddle?: {
      Environment: { set: (e: string) => void };
      Initialize: (o: { token: string }) => void;
      Checkout: { open: (o: { transactionId?: string; items?: { priceId: string; quantity: number }[] }) => void };
    };
  }
}
