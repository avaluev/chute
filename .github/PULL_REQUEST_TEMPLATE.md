## What this changes, and why

<!-- One or two sentences. Link an issue if there is one. -->

## Gates run locally

Check off what applies — see [`docs/SCRIPTS.md`](../docs/SCRIPTS.md) for what each one measures
and what it cannot catch. Paste the tallied output, not just a checkmark; a skip is not a pass.

- [ ] `swift build -c release`
- [ ] `swift run -c release chutetests` → `<paste "N assertions passed">`
- [ ] `CHUTE_HEADLESS=1 ./Scripts/smoke.sh` → `<paste "N passed, N failed">`
- [ ] `./Scripts/check-untested-logic.sh` — only if you touched `Sources/ChuteApp/` or
      `Sources/ChuteFinder/`
- [ ] `./Scripts/acceptance.sh` — only if you touched a Finder action
- [ ] `./Scripts/check-focus.sh` — only if you touched `README.md` or `site/src/app/**`
- [ ] `cd site && npm run check:claims` (against a built site) — only if you touched published
      copy or a number it verifies
- [ ] `./Scripts/screens.sh` and looked at the PNGs — only if you changed what a window shows

CI (`.github/workflows/macos-matrix.yml`) runs the build, `chutetests`, and a headless
`smoke.sh` on macOS 15 and macOS 26 automatically; it does not run the gates above that need a
real desktop or a built site.

## Anything a reviewer should know

<!-- A deliberate trade-off, a follow-up you're not doing here, a decision worth a second look. -->
