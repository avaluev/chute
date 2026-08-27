# Publishing the Homebrew tap

`chute.rb` is written to live at `Formula/chute.rb` inside a separate repo,
`avaluev/homebrew-tap` — Homebrew requires the tap repo to be named
`homebrew-<name>` and taps aren't nested inside the product repo.

## 1. Cut the release tag in the chute repo

```
cd /Users/sxope/Documents/2026/Development/37.chute && git tag v0.1.0 && git push origin v0.1.0
```

Expected output: `* [new tag]         v0.1.0 -> v0.1.0`

Use whatever version is currently in
`/Users/sxope/Documents/2026/Development/37.chute/Sources/ChuteCore/Version.swift` — do not hardcode a different number here.

## 2. Compute the real sha256

```
cd /Users/sxope/Documents/2026/Development/37.chute && curl -L https://github.com/avaluev/chute/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
```

Expected output: a 64-char hex digest followed by `-`.

## 3. Create the tap repo (one-time)

```
cd /Users/sxope/Documents/2026/Development/37.chute && gh repo create avaluev/homebrew-tap --public --description "Homebrew tap for chute"
```

Expected output: `https://github.com/avaluev/homebrew-tap`

## 4. Clone it and copy the formula in

```
cd /Users/sxope/Documents/2026/Development/37.chute && git clone https://github.com/avaluev/homebrew-tap.git /tmp/homebrew-tap
mkdir -p /tmp/homebrew-tap/Formula
cp /Users/sxope/Documents/2026/Development/37.chute/packaging/homebrew/chute.rb /tmp/homebrew-tap/Formula/chute.rb
```

## 5. Paste in the real sha256 from step 2

Edit `/tmp/homebrew-tap/Formula/chute.rb`, replacing the placeholder
`sha256 "000...000"` line with the digest from step 2.

## 6. Commit and push the tap

```
cd /tmp/homebrew-tap && git add Formula/chute.rb && git commit -m "chute 0.1.0" && git push -u origin main
```

Expected output: `main -> main`

## 7. Verify installation

```
brew install avaluev/tap/chute && chute --version
```

Expected output: `chute 0.1.0`
