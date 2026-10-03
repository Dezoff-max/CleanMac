# Signing And Notarization

CleanMac can build unsigned releases by default and can produce Developer ID signed/notarized releases when private Apple credentials are configured.

## Local Signing

Check available identities:

```sh
security find-identity -p codesigning -v
```

Build a local unsigned app, drag-to-Applications DMG, and fallback ZIP. The
script still applies an ad-hoc signature so the bundle can be verified locally,
but Gatekeeper distribution still requires a Developer ID certificate and
notarization.

```sh
./script/package_release.sh
```

Build Developer ID signed app, DMG, and ZIP artifacts:

```sh
CLEANMAC_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./script/package_release.sh
```

Build, notarize, staple, and recreate the DMG and ZIP:

```sh
CLEANMAC_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
CLEANMAC_NOTARIZE=1 \
CLEANMAC_NOTARY_PROFILE="cleanmac-notary" \
./script/package_release.sh
```

The script also supports notarytool API key variables:

```sh
CLEANMAC_NOTARY_KEY_PATH="/path/AuthKey_KEYID.p8"
CLEANMAC_NOTARY_KEY_ID="KEYID"
CLEANMAC_NOTARY_ISSUER="ISSUER_UUID"
```

## GitHub Release Secrets

For GitHub Releases, add these private repository secrets when signing is ready:

- `CLEANMAC_SIGN_IDENTITY`: Developer ID Application identity name.
- `CLEANMAC_CERTIFICATE_P12_BASE64`: base64-encoded `.p12` Developer ID certificate.
- `CLEANMAC_CERTIFICATE_PASSWORD`: password for the `.p12` certificate.
- `CLEANMAC_KEYCHAIN_PASSWORD`: temporary CI keychain password.
- `CLEANMAC_NOTARIZE`: set to `1` to submit to Apple notary service.
- `CLEANMAC_NOTARY_KEY_BASE64`: base64-encoded App Store Connect API key `.p8`.
- `CLEANMAC_NOTARY_KEY_ID`: App Store Connect API key id.
- `CLEANMAC_NOTARY_ISSUER`: App Store Connect issuer UUID.

If these secrets are absent, the Release workflow keeps producing an ad-hoc signed DMG and ZIP with checksums.

## Validation

```sh
codesign -dvvv --entitlements :- dist/CleanMac.app
codesign --verify --deep --strict --verbose=2 dist/CleanMac.app
spctl -a -vv dist/CleanMac.app
```

Without a Developer ID certificate, `spctl` is expected to report that the app is not accepted for distribution.
