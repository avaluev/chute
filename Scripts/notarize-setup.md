# Notarisation — the one-time setup

Enrolling in the Apple Developer Program does **not** give you a signing certificate. It gives you
the right to create one. These five steps are done once per Mac; after them
`./Scripts/release.sh` runs end to end with no further input.

Verify where you stand first:

```bash
security find-identity -v -p codesigning
```

If no line says `Developer ID Application: …`, start at step 1.

---

### 1. Create the certificate request

Keychain Access → menu **Certificate Assistant → Request a Certificate From a Certificate
Authority…**

- User Email Address: your Apple ID email
- Common Name: `Alexandr Valuev`
- CA Email Address: leave empty
- Select **Saved to disk**, and tick **Let me specify key pair information**
- Key Size 2048, Algorithm RSA

Save it as `~/Desktop/CertificateSigningRequest.certSigningRequest`.

**Do not skip the "let me specify" tick.** Without it the private key can be generated in a way
that later refuses to sign, and the failure appears three steps later as an unexplained codesign
error.

### 2. Turn it into a certificate

Go to <https://developer.apple.com/account/resources/certificates/add>.

- Choose **Developer ID Application** — *not* "Mac Development", *not* "Mac App Distribution".
  Developer ID is the only type that lets a stranger open the app.
- Upload the `.certSigningRequest` from step 1.
- Download the resulting `developerID_application.cer`.

### 3. Install it

Double-click the downloaded `.cer`. Then confirm:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && security find-identity -v -p codesigning
```

Expected: a line containing `"Developer ID Application: Alexandr Valuev (TEAMID)"`.
Note the ten-character `TEAMID` in the brackets — step 4 needs it.

### 4. Create an app-specific password and store the notary credentials

Apple will not accept your normal Apple ID password here.

1. Go to <https://appleid.apple.com/account/manage> → **App-Specific Passwords** → **+**
2. Name it `chute notarytool`. Copy the `xxxx-xxxx-xxxx-xxxx` value.
3. Store it once, in the keychain, so it never appears in a script or a shell history:

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && xcrun notarytool store-credentials chute \
  --apple-id "valuev.alexandr@gmail.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Expected output: `This process stores your credentials securely in the Keychain.` followed by
`Validating your credentials...` and `Success. Credentials validated.`

### 5. Prove the whole path without publishing anything

```bash
cd /Users/sxope/Documents/2026/Development/37.chute && ./Scripts/release.sh --dry-run
```

This builds, signs, packages, notarises, staples and verifies — and stops before the git tag and
the GitHub release. The line that matters is the last one:

```
notarised, stapled, and accepted by Gatekeeper: …/dist/Chute-0.1.0.dmg
```

Until that line appears, every stranger who downloads Chute hits a Gatekeeper wall.

---

## When it goes wrong

| Symptom | Cause | Fix |
|---|---|---|
| `notarisation was not Accepted` | Apple's reasons are printed underneath by `notarytool log` | Almost always a missing hardened runtime or timestamp on a nested binary. `Scripts/build-app.sh` adds both for Developer ID only. |
| `The signature does not include a secure timestamp` | Signed while offline | The timestamp is fetched from Apple's server at signing time. Reconnect and rebuild. |
| codesign hangs, then falls back to ad-hoc | The keychain is locked and the "allow" dialog was never answered | `security unlock-keychain ~/Library/Keychains/login.keychain-db`, or click **Always Allow**. |
| The Finder menu disappears after a release build | The appex sandbox container ACL pins the cdhash that created it, and the identity changed | `./Scripts/install.sh` detects and repairs this. See the TRAPS ledger in `handoff/NEXT.md`. |
