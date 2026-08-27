import { CopyLine } from "@/components/copy-line";
import { CONFIG } from "@/lib/config";

/**
 * How to install the free CLI, told truthfully for the state we are actually in.
 *
 * `brew install avaluev/tap/chute` was on every launch asset and in every draft post for a day
 * before the tap existed. A visitor who ran it got an error, and the visitor most likely to run
 * it is the sceptic deciding whether to trust a $19 utility from a stranger. So the command is
 * printed only while CONFIG.brewLive says it works; otherwise this renders the install that does.
 *
 * One flag, one component, and nothing else on the site has to know. It is true now — the tap was
 * published on 2026-08-28 — but the fallback stays, because the next thing this site will claim
 * before it is true is "notarized".
 */
export function InstallCli() {
  if (CONFIG.brewLive) return <CopyLine text={CONFIG.brew} />;
  return (
    <div>
      <CopyLine text={`git clone ${CONFIG.repo} && cd chute && swift build -c release`} />
      <p className="mt-2 text-sm text-muted-foreground">
        Zero dependencies, so that is the whole build. The Homebrew tap goes up with the release —
        until then this is the honest install, and the source is right there to read first.
      </p>
    </div>
  );
}
