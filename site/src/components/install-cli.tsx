import { CopyLine } from "@/components/copy-line";
import { CONFIG } from "@/lib/config";

/**
 * How to install the free CLI, told truthfully for the state we are actually in.
 *
 * `brew install avaluev/tap/chute` is on every launch asset and in every draft post, and the tap
 * does not exist yet. A visitor who runs it gets an error, and the visitor most likely to run it
 * is the sceptical one deciding whether to trust a $19 utility from a stranger. So until
 * CONFIG.brewLive is true this renders the install that does work.
 *
 * One flag, flipped the day the tap is published. Nothing else on the site has to change.
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
