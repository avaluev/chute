import Image from "next/image";
import Link from "next/link";
import { Badge } from "@/components/ui/badge";
import { asset } from "@/lib/asset";
import type { Case } from "@/lib/cases";

/**
 * The pieces every case is drawn from. One implementation, used by the landing page, the /cases
 * index and the 25 case pages — the same reason ChuteCore has one action table.
 */

/** Which column this belongs to. The split IS the sales argument, so it is never implied. */
export function SurfaceBadge({ paid }: { paid: boolean }) {
  return paid ? (
    <Badge className="rounded-[4px] border-[var(--color-accent-chute)]/40 bg-transparent text-[var(--color-accent-chute)]">
      Part of the app
    </Badge>
  ) : (
    <Badge className="rounded-[4px] border-border bg-transparent text-muted-foreground">
      Free, forever
    </Badge>
  );
}

/**
 * The cost, spelled out so it can be checked rather than believed: how often, times how long,
 * is the figure. A case with no honest number says so instead of showing a zero — see the
 * `savedMinutes: null` note in lib/cases.ts.
 */
export function DailyCost({ c }: { c: Case }) {
  if (c.savedMinutes === null) {
    return (
      <p className="text-sm text-muted-foreground">
        No figure for this one. It buys back attention rather than seconds, and a number invented
        for it would make the other twenty-four less believable.
      </p>
    );
  }
  return (
    <p className="font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
      <span className="text-foreground">{c.perDay}× a day</span>
      {" · "}
      {c.seconds.manual}s by hand, {c.seconds.chute}s with Chute
      {" · "}
      <span className="text-[var(--color-accent-chute)]">
        {c.savedMinutes} min a day
      </span>
    </p>
  );
}

/** A recorded demo, or nothing at all. Never a placeholder: a fake screenshot is a lie with a
 *  border around it, and every image on this site is real recorded output.
 *
 *  Two shapes, one branch. The free CLI shorts are GIFs from VHS; the paid app is filmed off a
 *  real screen by demo/gui and arrives as mp4 + webm + a poster frame. Which one a case gets is
 *  decided by its own file extension, so publishing a recording is the only step — nothing here
 *  has to be told that a case graduated from a GIF to a video.
 *
 *  The video carries no controls and no sound: it is an illustration, not a player, and a
 *  play button on a landing page is a decision the reader did not ask to make. `poster` is the
 *  first frame, so the block never renders as a hole while the video loads. */
const FRAME = "w-full rounded-[4px] border border-border";

export function Demo({ c }: { c: Case }) {
  if (!c.demo) return null;

  if (c.demo.endsWith(".mp4")) {
    const webm = c.demo.replace(/\.mp4$/, ".webm");
    return (
      <video
        aria-label={c.fix}
        poster={c.poster ? asset(c.poster) : undefined}
        width={1200}
        height={750}
        autoPlay
        muted
        loop
        playsInline
        preload="metadata"
        className={FRAME}
      >
        <source src={asset(webm)} type="video/webm" />
        <source src={asset(c.demo)} type="video/mp4" />
      </video>
    );
  }

  return (
    <Image
      src={asset(c.demo)}
      alt={c.fix}
      width={1200}
      height={750}
      unoptimized
      className={FRAME}
    />
  );
}

export function CaseCard({ c }: { c: Case }) {
  return (
    <Link
      href={`/cases/${c.slug}`}
      className="group flex flex-col gap-3 rounded-[4px] border border-border p-5 transition-colors duration-150 hover:border-[var(--color-accent-chute)]/50"
    >
      <div className="flex items-start justify-between gap-3">
        <h3 className="text-[15px] leading-snug text-foreground">{c.pain}</h3>
      </div>
      <p className="text-sm text-muted-foreground">{c.fix}</p>
      <div className="mt-auto flex items-center justify-between gap-3 pt-2">
        <SurfaceBadge paid={c.paid} />
        {c.savedMinutes !== null && (
          <span className="font-[family-name:var(--font-mono-loaded)] text-sm text-muted-foreground">
            {c.savedMinutes} min/day
          </span>
        )}
      </div>
    </Link>
  );
}
