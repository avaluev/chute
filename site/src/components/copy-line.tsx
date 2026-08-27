"use client";

import { useState } from "react";

/**
 * An install command you can take without selecting it by hand.
 *
 * The clipboard write is wrapped: it throws in a non-secure context and in some embedded
 * browsers, and an uncaught throw here would leave the button looking broken for the one visitor
 * most likely to be technical enough to notice.
 */
export function CopyLine({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 1600);
    } catch {
      setCopied(false);
    }
  }

  return (
    <button
      onClick={copy}
      aria-label={`Copy: ${text}`}
      className="group flex w-full items-center justify-between gap-4 rounded-[var(--radius)] border border-border bg-card px-4 py-3 text-left transition-colors hover:border-[var(--color-accent-chute)]"
    >
      <code className="font-[family-name:var(--font-mono-loaded)] text-sm text-foreground">
        <span className="select-none text-muted-foreground">$ </span>
        {text}
      </code>
      <span className="shrink-0 font-[family-name:var(--font-mono-loaded)] text-xs text-muted-foreground group-hover:text-[var(--color-accent-chute)]">
        {copied ? "copied" : "copy"}
      </span>
    </button>
  );
}
