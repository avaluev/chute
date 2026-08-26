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

---

# Reference implementation teardown — Google Drive's FinderSync extension

Read on 2026-08-26 from the copy installed on this machine. Bundle layout, `Info.plist` and the
shipped `.entitlements` file are public metadata of an installed app; this is interop research,
not decompilation. **It answered in ten minutes what three failed attempts could not.**

Path:
```
/Applications/Google Drive.app/
  Contents/Applications/FinderHelper.app/          ← a nested HELPER app, LSUIElement
    Contents/PlugIns/FinderSyncExtension.appex/    ← the extension lives in the HELPER
```

## What the working `Info.plist` contains

| Key | Google Drive | My plan had it? |
|---|---|---|
| `CFBundlePackageType` | `XPC!` | ✅ yes |
| `NSExtensionPointIdentifier` | `com.apple.FinderSync` | ✅ yes |
| `NSExtensionPrincipalClass` | `DFSFinderSync` | ✅ yes |
| `LSMinimumSystemVersion` | `13.0.0` | ✅ same floor |
| **`LSUIElement`** | **`1`** | ❌ **MISSING** |
| **`NSPrincipalClass`** | **`NSApplication`** | ❌ **MISSING** |
| `NSExtensionAttributes` | `{}` (present, empty) | ❌ missing |

## The finding that breaks my architecture

```
com.apple.security.app-sandbox                                  = 1
com.apple.security.automation.apple-events                      = com.apple.finder
com.apple.security.temporary-exception.apple-events             = com.apple.finder
com.apple.security.temporary-exception.files.absolute-path.read-write = "/"
```

**The extension is sandboxed**, and needs a *temporary exception* just to read and write outside
its own container. macOS app extensions are always sandboxed — this is not a Google choice.

**Consequence:** the FinderSync plan has the appex spawning the `chute` binary via `Process` to do
the actual work. A child process inherits its parent's sandbox, so that `chute` could not write
a file to `~/Desktop`, create a sandbox folder, or launch Terminal. **Every action in the menu
would fail, after the menu finally appeared.**

That is the same shape of failure as the `pgrep` bug: correct-looking code, green tests, and a
feature that cannot work — discovered only by looking at reality instead of reasoning about it.

Note also what Google Drive does NOT do: its extension performs no file work itself. It talks to
the already-running main application. That is the pattern to copy.

## Revised architecture for the Finder menu

```
ChuteFinder.appex   (sandboxed, minimal)   builds the menu, captures the selection
        │  IPC — mechanism to be VERIFIED, not assumed
        ▼
ChuteApp            (unsandboxed, running) receives the request, runs the CLI
        │
        ▼
chute               (unsandboxed)          does the work
```

Candidate IPC mechanisms, in order of preference, **all to be tested before one is chosen**:
1. `DistributedNotificationCenter` — no entitlement to post; sandbox may strip `userInfo` on the
   receiving side, which is exactly the sort of thing that must be measured, not assumed.
2. A Mach service via `NSXPCConnection` — the robust, Apple-sanctioned route; more setup.
3. A request file in a group container watched by the app — needs an app-group entitlement,
   which needs a Developer ID.

## Consequences for the plan

1. **Task 1's feasibility gate now has a second question**, ahead of "does it register": *can a
   sandboxed appex reach the app at all?* Answer that with a throwaway probe before writing menu code.
2. Add `LSUIElement`, `NSPrincipalClass` and `NSExtensionAttributes` to the appex `Info.plist`.
3. **Delete the "shell out to `chute` from the appex" design.** It cannot work.
4. Ad-hoc signing may not satisfy the sandbox at all — the entitlements above require a signing
   identity. This may pull the $99 Developer ID membership forward from "before distribution" to
   "before the Finder menu works at all". **Verify early; it is a budget decision, not a code one.**

## Method note

Three integration attempts failed on guesses. One teardown of a shipping product settled the
format, the entitlements, and a fatal architectural assumption. **When a working example exists on
disk, read it before writing anything.**
