import { cn } from "@/lib/utils";
import { Mark } from "@/components/chrome";
import styles from "./menu-loop.module.css";

/**
 * THE HERO ANIMATION — a stylised Chute menu, not a recording.
 *
 * Every other image on this site is real captured output (see case-bits.tsx's own note on that).
 * This is the one deliberate exception: a live CSS illustration of the product's actual dot
 * language, built from the real per-state geometry (`Sources/ChuteCore/SessionDot.swift`,
 * `MenuBarMark.swift`) and real row strings pulled from the recorded screenshots in
 * `site/public/media/screens/cases/`. It says so — see the screen-reader description below —
 * because a landing page with one illustrated shot next to twenty real ones has to be honest
 * about which is which.
 *
 * No JS: this is a server component. The whole loop is `menu-loop.module.css` cross-fading
 * three stacked layers per changing value, so there is nothing to hydrate and nothing that can
 * jank on a slow device — the browser is doing the same opacity compositing it would for a CSS
 * hover state.
 */

type State = "working" | "blocked" | "ready";

const DOT: Record<State, string> = {
  working: styles.shapeRing,
  blocked: styles.shapeBlocked,
  ready: styles.shapeReady,
};
const PIP: Record<State, string> = {
  working: styles.pipRing,
  blocked: styles.pipShapeBlocked,
  ready: styles.pipShapeReady,
};
const LAYER: Record<State, string> = {
  working: styles.dotWorking,
  blocked: styles.dotBlocked,
  ready: styles.dotReady,
};
const LINE: Record<State, string> = {
  working: styles.lineWorking,
  blocked: styles.lineBlocked,
  ready: styles.lineReady,
};
const PIP_LAYER: Record<State, string> = {
  working: styles.pipWorking,
  blocked: styles.pipBlocked,
  ready: styles.pipReady,
};

const STATES: State[] = ["working", "blocked", "ready"];

const th =
  "font-[family-name:var(--font-mono-loaded)] text-xs font-semibold uppercase tracking-[0.14em] text-muted-foreground";

/** A row that never changes state — the "several sessions working" backdrop. */
function WorkingRow({ project, path, state, agent, load, load2 }: {
  project: string; path: string; state: string; agent: string; load: string; load2?: string;
}) {
  return (
    <div className="flex items-start gap-3 border-t border-border px-4 py-3 first:border-t-0">
      <span className={cn("mt-[3px]", styles.dotStack)}>
        <span className={cn(styles.shapeRing, styles.ringBreath)} />
      </span>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-foreground">{project}</p>
        <p className="truncate font-[family-name:var(--font-mono-loaded)] text-xs text-muted-foreground">{path}</p>
      </div>
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-foreground">{state}</p>
        <p className="truncate text-xs text-muted-foreground">{agent}</p>
      </div>
      <div className="w-[104px] shrink-0 text-right">
        <p className="font-[family-name:var(--font-mono-loaded)] text-xs text-foreground">{load}</p>
        {load2 && <p className="font-[family-name:var(--font-mono-loaded)] text-xs text-muted-foreground">{load2}</p>}
      </div>
    </div>
  );
}

export function MenuLoop() {
  return (
    <div className="mx-auto w-full max-w-xl">
      {/* The animation is decorative — everything a sighted visitor needs from it is restated as
          plain text here, read by a screen reader whether or not the illustration renders. */}
      <p className="sr-only">
        Animated illustration of the Chute menu bar. Three sessions are listed, each a project,
        its state and agent, and its load. Two keep working, shown as a hollow orange square. The third,
        37.chute, goes from working to blocked — a big solid red square — and lifts to ask for you;
        the menu bar icon&rsquo;s own corner pip turns red at the same moment. A click turns it
        ready, a smaller solid green square, and it settles back to working before the loop repeats.
      </p>

      <div aria-hidden="true">
        {/* the menu bar sliver the popover hangs from, pip synced to row1 */}
        <div className="flex justify-end pr-5">
          <div className="relative flex h-6 w-9 items-center justify-center rounded-t-[3px] border border-b-0 border-border bg-card">
            <Mark size={14} />
            <span className={styles.pipStack}>
              {STATES.map((s) => (
                <span key={s} className={PIP_LAYER[s]}>
                  <span className={PIP[s]} />
                </span>
              ))}
            </span>
          </div>
        </div>

        {/* the popover itself — three columns, two lines, matching
            site/public/media/screens/cases/mixed.webp row for row */}
        <div className="overflow-hidden rounded-[var(--radius)] border border-border bg-card shadow-hero">
          <div className="flex items-center gap-3 px-4 py-2.5">
            <span className={th} style={{ width: 12 }} />
            <span className={cn(th, "min-w-0 flex-1")}>Project</span>
            <span className={cn(th, "min-w-0 flex-1")}>Agent · State</span>
            <span className={cn(th, "w-[104px] shrink-0 text-right")}>Load</span>
          </div>

          {/* row 1 — the one the whole demo is about */}
          <div className={cn("relative flex items-start gap-3 border-t border-border px-4 py-3", styles.row1)}>
            <span className={styles.glow} />
            <span className={cn("relative mt-[3px]", styles.dotStack)}>
              {STATES.map((s) => (
                <span key={s} className={LAYER[s]}>
                  <span className={DOT[s]} />
                </span>
              ))}
              <span className={styles.ripple} />
              <span className={styles.pointer} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-foreground">37.chute</p>
              <p className="truncate font-[family-name:var(--font-mono-loaded)] text-xs text-muted-foreground">
                ~/Documents/…/37.chute/site
              </p>
            </div>
            <div className="min-w-0 flex-1">
              <span className={cn("block text-sm font-semibold text-foreground", styles.lineStack)}>
                <span className={LINE.working}>working 4 min</span>
                <span className={LINE.blocked}>blocked 22 min</span>
                <span className={LINE.ready}>ready 0 min</span>
              </span>
              <p className="truncate text-xs text-muted-foreground">Claude Code · Opus 5 · xhigh</p>
            </div>
            <div className="w-[104px] shrink-0 text-right">
              <p className="font-[family-name:var(--font-mono-loaded)] text-xs text-foreground">177% · 3.0 GB</p>
            </div>
          </div>

          {/* rows 2-3 — steady, so the reader sees "several sessions working" while row 1 moves */}
          <WorkingRow project="studylock" path="~/Dev/studylock"
                      state="working 8 min" agent="Claude Code · Opus 5"
                      load="88% · 2.4 GB" load2="peaked 6.1 GB" />
          <WorkingRow project="37.sntz" path="~/Dev/37.sntz"
                      state="working 1 min" agent="Claude Code · Opus 5"
                      load="40% · 1.1 GB" />
        </div>
      </div>
    </div>
  );
}
