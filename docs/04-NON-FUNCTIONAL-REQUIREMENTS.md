# NFR — Chute v0.1

| ID | Requirement | Verification |
|---|---|---|
| NFR-01 Latency | Any command completes in < 300 ms for ≤ 50 files | `time chute paths …` in smoke |
| NFR-02 Footprint | CLI binary < 5 MB; app bundle < 15 MB; no background CPU when idle | `du -h` in smoke |
| NFR-03 Privacy | Zero telemetry, zero network calls except explicit `chute gist`. Fully offline. | `grep -r URLSession Sources/` returns only the gist path |
| NFR-04 Dependencies | Zero third-party Swift packages | `Package.swift` has no `.package(` |
| NFR-05 Safety | Destructive commands (`unpack`, `clean`) preview by default; writes require `--force` | Smoke asserts no writes without `--force` |
| NFR-06 Path safety | `unpack` rejects absolute paths and any path resolving outside the target dir | Unit test with `../../etc/passwd` |
| NFR-07 Secrets | `env inject` reads Keychain only; never logs a value; aborts if `.env` is not gitignored | Unit test + manual review |
| NFR-08 No data loss | `checkpoint` only ever adds commits/branches; `new` never overwrites | Unit test on name collision |
| NFR-09 Test coverage | ≥ 80 % line coverage on `ChuteCore` | `swift test --enable-code-coverage` |
| NFR-10 Compatibility | macOS 13+, arm64 + x86_64, builds with Command Line Tools only (no Xcode) | CI on macos-14 |
| NFR-11 Degradation | Missing optional tools (`gh`, Ghostty, agents) produce a clear message, never a crash | Unit test with a stubbed runner |
| NFR-12 Encoding | UTF-8 throughout; binary files skipped in `bundle`, not corrupted | Unit test with a PNG fixture |
