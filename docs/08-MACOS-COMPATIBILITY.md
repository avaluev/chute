# macOS compatibility — capability boundaries per version

Written 2026-08-26 after four failed integration attempts, every one caused by assuming an API's
behaviour instead of verifying it. **This file is the antidote: nothing goes in it that was not
either read in Apple's documentation or executed on a real machine.**

## Development machine
macOS **14.6.1** Sonoma · Command Line Tools only, no Xcode · no code-signing identity.
Current shipping macOS is **26.x** — this machine is two major versions behind, so anything
verified here is verified for the OLDEST supported target, not the newest.

## The Finder context menu: what works on which version

| macOS | FinderSync (`FIFinderSync`) | Enable UI location | Verdict |
|---|---|---|---|
| 10.10 – 14.x | Supported, stable | System Settings → Privacy & Security → Extensions → Finder | **Baseline.** Verified locally. |
| **15.0 – 15.1** | Works, but **the Extensions configuration UI was REMOVED** | *Nowhere* | **Trap.** A user on these versions cannot enable the extension through documented steps. |
| 15.2 – 15.x | Supported; UI restored | Back in System Settings | OK |
| 26.x | Supported and used by shipping apps (SwiftyMenu) | System Settings | OK, with reported load failures on 26.3.1 beta |

**Consequence for onboarding:** never *instruct* a user to tick a box. For two full OS releases
that box did not exist. Onboarding must **verify the outcome** (`pluginkit -m -p com.apple.FinderSync`)
and adapt, not recite a click path.

## Mechanisms considered, and why each was rejected or chosen

| Mechanism | Availability | Verdict |
|---|---|---|
| **`FIFinderSync` app extension** | 10.10+ | **CHOSEN.** Documented, supported, top-level menu, works on empty background. What every competitor uses. |
| App-declared `NSServices` | All | Rejected — lands in the buried *Services* submenu. Verified: registered correctly, never appeared. |
| Automator `.workflow` Quick Actions | 10.14+ | Rejected — undocumented `document.wflow` format. Verified: `pbs` registers it, Finder ignores it, `FinderActive` never lists it. |
| Shortcuts.app Quick Actions | 13+ | Rejected — user must manually add each shortcut. Breaks "install and it works". |
| Accessibility API scraping | All | Rejected — fragile, permission-gated, breaks on every OS update. |

## Verified API behaviours (executed, not assumed)

| Claim | How verified | Result |
|---|---|---|
| `FinderSync.framework` is in the CLT SDK | `ls $(xcrun --show-sdk-path)/System/Library/Frameworks/` | Present — **Xcode not required to compile** |
| Swift can link it without Xcode | `swiftc` a file importing `FinderSync` | Binary produced, 52 KB |
| `NSExtensionMain` is available | `grep Foundation.tbd` | Exported |
| `pgrep -x Terminal` finds Terminal.app | Ran it | **NO MATCH** — `comm` is the full executable path |
| `ps -Ao comm` finds Terminal.app | Ran it | Matches. **This is the portable check.** |
| `ps -o tty= -p N` returns empty with no tty | Ran `ps -o tty= -p 1` | Returns `??`, **not** empty — a guard on emptiness never fires |
| A worktree inherits `.build` | Created one | It does not — each compiles independently |
| APFS is case-sensitive | Named two files `Chute`/`chute` | **Case-INSENSITIVE** — one silently overwrote the other |

## Hard requirements that are not code problems

| Requirement | Gate |
|---|---|
| Extension loads on another person's Mac | **Developer ID signature** — $99/yr Apple Developer Program |
| No Gatekeeper warning on download | **Notarization** — requires the same membership |
| Distribution as a DMG | Both of the above |

Ad-hoc signing works only on the machine that built it. There is no way around this; it is the
price of touching Finder at all.

## Minimum target

**macOS 13 Ventura.** Rationale: `FIFinderSync` predates it comfortably, SwiftUI and modern
AppKit APIs are available, and 13 is old enough to cover essentially every Mac an AI builder
uses. Going lower buys nothing and costs testing surface.

## The rule this file exists to enforce

Every macOS behaviour this product depends on is listed above with the command that proved it.
**If a behaviour is not in this table, it has not been verified — and it must not be assumed.**
Four integration failures came from skipping exactly that step.
