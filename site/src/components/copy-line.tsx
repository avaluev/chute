"use client";

import { useState } from "react";

/**
 * An install command you can take without selecting it by hand.
 *
 * The clipboard write is wrapped: it throws in a non-secure context and in some embedded
 * browsers, and an uncaught throw here would leave the button looking broken for the one visitor
 * most likely to be technical enough to notice.
 *
 * LONG COMMANDS SCROLL; THEY DO NOT WRAP AND THEY DO NOT PUSH THE BUTTON OUT.
 * The first version had neither `min-w-0` nor an overflow rule, so `git clone <url> && cd chute
 * && swift build -c release` broke out of its card, wrapped onto four ragged lines and shoved
 * "copy" past the border into the next column. A flex child's default `min-width: auto` means it
 * refuses to shrink below its content, which is why the container — not the text — was the thing
 * that had to be told it may be narrower than what is inside it.
 *
 * `whitespace-pre` keeps the command on one line where a reader can recognise its shape;
 * `overflow-x-auto` lets them drag it on a phone. Neither matters much, because the button
 * copies the whole string whether or not it is all on screen — which is the actual job.
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
      className="group flex w-full items-center gap-3 rounded-[var(--radius)] border border-border bg-card py-3 pl-4 pr-3 text-left transition-colors hover:border-[var(--color-accent-chute)]"
    >
      {/* min-w-0 is the whole fix: without it this flex child will not shrink below its content. */}
      <code className="min-w-0 flex-1 overflow-x-auto whitespace-pre font-[family-name:var(--font-mono-loaded)] text-[13px] text-foreground sm:text-sm [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        <span className="select-none text-muted-foreground">$ </span>
        {text}
      </code>
      <span className="shrink-0 rounded border border-border px-2 py-1 font-[family-name:var(--font-mono-loaded)] text-[11px] uppercase tracking-wide text-muted-foreground transition-colors group-hover:border-[var(--color-accent-chute)] group-hover:text-[var(--color-accent-chute)]">
        {copied ? "copied" : "copy"}
      </span>
    </button>
  );
}
