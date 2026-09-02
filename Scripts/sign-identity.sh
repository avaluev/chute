#!/usr/bin/env bash
# Creates ONE stable self-signed code-signing identity, so every build of Chute has the same
# identity as the last one.
#
# WHY: an ad-hoc signature (`codesign -s -`) has no identity at all. macOS therefore sees every
# rebuild as a different app: it re-asks "Chute is from an unidentified developer and differs from
# previously opened versions", and — worse — the Finder extension's sandbox container stops
# recognising the new build, so the Chute menu silently disappears.
#
# This is NOT the $99 Apple Developer ID. It removes the repeat prompts for the person who builds
# Chute; a stranger downloading it still gets the first-open warning until the app is notarised.
set -euo pipefail
NAME="Chute Local Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usable() { security find-identity -v -p codesigning 2>/dev/null | grep -q "$NAME"; }

if usable; then
  echo "ready: \"$NAME\" is a valid code-signing identity"
  exit 0
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# A certificate can be in the keychain and still not be an IDENTITY — that needs trust for code
# signing. Re-running this script must finish the job rather than stopping at "already exists".
if security find-certificate -c "$NAME" >/dev/null 2>&1; then
  echo "certificate exists but is not trusted for code signing — fixing that"
  security find-certificate -c "$NAME" -p > "$TMP/cert.pem"
else
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -subj "/CN=$NAME" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
  # -legacy and the SHA1 algorithms are required: OpenSSL 3 defaults to an AES/SHA-256 PKCS#12
  # that macOS `security import` cannot read — it fails with "MAC verification failed".
  openssl pkcs12 -export -legacy -out "$TMP/id.p12" -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -name "$NAME" -macalg sha1 -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES \
    -passout pass:chute 2>/dev/null
  # -T codesign only. `-A` granted EVERY application unprompted use of a key this Mac is then
  # told to trust for code signing.
  security import "$TMP/id.p12" -k "$KEYCHAIN" -P chute -T /usr/bin/codesign >/dev/null
  echo "created certificate: $NAME"
fi

echo "macOS will now ask for your login password to trust it for code signing."
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$TMP/cert.pem"

if usable; then
  echo "ready: \"$NAME\" is now a valid code-signing identity"
  echo "next:  cd $ROOT && ./Scripts/build-app.sh && ./Scripts/install.sh"
else
  echo "the certificate is still not usable for signing — Chute keeps working with an ad-hoc"
  echo "signature; macOS will just keep asking about the app after each rebuild."
  exit 1
fi
