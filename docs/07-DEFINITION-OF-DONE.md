# DoD — Chute v0.1

A JTBD is **done** only when every box is true. No partial credit, no "mostly done".

## Per command
- [ ] Unit test written **before** the implementation (RED → GREEN → refactor)
- [ ] `swift test` green, and the new test was perturbed to prove it can fail
- [ ] Handles: empty input, missing file, no permission, binary content, unicode, spaces in paths
- [ ] Destructive behaviour previews by default; writing requires `--force`
- [ ] `--help` lists the command with one example
- [ ] Errors are actionable sentences, never a raw Swift error dump
- [ ] Committed on its own (`feat: …`), pushed

## Per release
- [ ] `swift build -c release` clean, zero warnings
- [ ] `swift test --enable-code-coverage` ≥ 80 % on `ChuteCore`
- [ ] `Scripts/smoke.sh` exits 0 and its tally was read, not assumed
- [ ] Manual Finder gate passed: right-click actually produced a file (verified by a human, not by the file existing)
- [ ] `Chute.app` launches, hotkey fires, HUD acts on the real Finder selection
- [ ] Zero secrets in the repo; `git log -p | grep -E 'sk-|ghp_|AKIA'` empty
- [ ] README documents install, uninstall, and every command
- [ ] `handoff/NEXT.md` current
- [ ] Tagged `v0.1.0`, pushed, working tree clean
