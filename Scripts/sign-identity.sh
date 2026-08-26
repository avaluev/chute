#!/usr/bin/env bash
# Creates ONE stable self-signed code-signing identity, so every build of Chute has the same
# identity as the last one.
#
# WHY: an ad-hoc signature (`codesign -s -`) has no identity at all, so macOS sees every rebuild as
# a different app and asks "Chute is from an unidentified developer and differs from previously
# opened versions" EVERY time. A stable certificate answers that question once.
#
# This is NOT the $99 Apple Developer ID. It removes the repeat prompt for the person who builds
# Chute; a stranger downloading it still gets the first-open warning until the app is notarised.
set -euo pipefail
NAME="Chute Local Dev"

if security find-certificate -c "$NAME" >/dev/null 2>&1; then
  echo "identity already exists: $NAME"
  exit 0
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -subj "/CN=$NAME" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
# -legacy and the SHA1 algorithms are required: OpenSSL 3 defaults to an AES/SHA-256 PKCS#12 that
# macOS `security import` cannot read — it fails with "MAC verification failed".
openssl pkcs12 -export -legacy -out "$TMP/id.p12" -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "$NAME" -macalg sha1 -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES \
  -passout pass:chute 2>/dev/null

security import "$TMP/id.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
  -P chute -T /usr/bin/codesign -A >/dev/null

# An imported certificate is not yet an IDENTITY: codesign only accepts it once it is trusted for
# code signing. This step asks for your login password once, through the macOS security prompt.
security add-trusted-cert -r trustRoot -p codeSign \
  -k "$HOME/Library/Keychains/login.keychain-db" "$TMP/cert.pem"

if security find-identity -v -p codesigning | grep -q "$NAME"; then
  echo "created and trusted: $NAME"
  echo "Rebuild to use it:  cd $(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd) && ./Scripts/build-app.sh && ./Scripts/install.sh"
else
  echo "imported but NOT trusted — codesign will keep using an ad-hoc signature."
  echo "Chute still works; macOS will keep asking about the app after each rebuild."
  exit 1
fi
