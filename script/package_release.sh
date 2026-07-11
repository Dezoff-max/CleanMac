#!/usr/bin/env bash
set -euo pipefail

APP_NAME="CleanMac"
PROJECT_NAME="CleanMac.xcodeproj"
SCHEME_NAME="CleanMac"
CONFIGURATION="Release"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DATA_DIR="$ROOT_DIR/build/XcodeData"
DIST_DIR="$ROOT_DIR/dist"
BUILT_APP="$BUILD_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
DIST_APP="$DIST_DIR/$APP_NAME.app"
ENTITLEMENTS_PATH="$ROOT_DIR/CleanMac/CleanMac.entitlements"
SIGN_IDENTITY="${CLEANMAC_SIGN_IDENTITY:-}"
NOTARIZE="${CLEANMAC_NOTARIZE:-0}"
NOTARY_PROFILE="${CLEANMAC_NOTARY_PROFILE:-}"
NOTARY_KEY_PATH="${CLEANMAC_NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID="${CLEANMAC_NOTARY_KEY_ID:-}"
NOTARY_ISSUER="${CLEANMAC_NOTARY_ISSUER:-}"
NOTARY_APPLE_ID="${CLEANMAC_NOTARY_APPLE_ID:-}"
NOTARY_PASSWORD="${CLEANMAC_NOTARY_PASSWORD:-}"
NOTARY_TEAM_ID="${CLEANMAC_NOTARY_TEAM_ID:-}"

if [[ -n "${GITHUB_SHA:-}" ]]; then
  BUILD_ID="${GITHUB_SHA:0:7}"
else
  BUILD_ID="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
fi

ZIP_KIND="unsigned"
if [[ -n "$SIGN_IDENTITY" ]]; then
  ZIP_KIND="signed"
fi
if [[ "$NOTARIZE" == "1" || "$NOTARIZE" == "true" ]]; then
  ZIP_KIND="notarized"
fi

ZIP_PATH="$DIST_DIR/$APP_NAME-$BUILD_ID-$ZIP_KIND.zip"
NOTARY_ARGS=()

sanitize_app_bundle() {
  local app_path="$1"
  xattr -cr "$app_path"
  xattr -dr com.apple.FinderInfo "$app_path" 2>/dev/null || true
  xattr -dr com.apple.ResourceFork "$app_path" 2>/dev/null || true
}

create_zip() {
  local zip_path="$1"
  local zip_root="$DIST_DIR/.ziproot"
  local zip_app="$zip_root/$APP_NAME.app"
  rm -f "$zip_path" "$zip_path.sha256"
  rm -rf "$zip_root"
  mkdir -p "$zip_root"
  COPYFILE_DISABLE=1 ditto --norsrc --noextattr "$DIST_APP" "$zip_app"
  sanitize_app_bundle "$zip_app"
  COPYFILE_DISABLE=1 ditto -c -k --norsrc --noextattr --keepParent "$zip_app" "$zip_path"
  rm -rf "$zip_root"
}

verify_zip() (
  local zip_path="$1"
  local verify_root
  verify_root="$(mktemp -d "${TMPDIR:-/tmp}/cleanmac-release-verify.XXXXXX")"
  trap 'rm -rf "$verify_root"' EXIT

  ditto -x -k "$zip_path" "$verify_root"
  codesign --verify --deep --strict --verbose=2 "$verify_root/$APP_NAME.app"
)

build_notary_args() {
  if [[ -n "$NOTARY_PROFILE" ]]; then
    NOTARY_ARGS=(--keychain-profile "$NOTARY_PROFILE")
    return
  fi

  if [[ -n "$NOTARY_KEY_PATH" && -n "$NOTARY_KEY_ID" && -n "$NOTARY_ISSUER" ]]; then
    NOTARY_ARGS=(--key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER")
    return
  fi

  if [[ -n "$NOTARY_APPLE_ID" && -n "$NOTARY_PASSWORD" && -n "$NOTARY_TEAM_ID" ]]; then
    NOTARY_ARGS=(--apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$NOTARY_TEAM_ID")
    return
  fi

  return 1
}

cd "$ROOT_DIR"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

xcodebuild \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DATA_DIR" \
  build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=""

if [[ ! -d "$BUILT_APP" ]]; then
  echo "error: expected app bundle was not created: $BUILT_APP" >&2
  exit 1
fi

COPYFILE_DISABLE=1 ditto --norsrc --noextattr "$BUILT_APP" "$DIST_APP"
sanitize_app_bundle "$DIST_APP"

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Signing $DIST_APP with: $SIGN_IDENTITY"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$DIST_APP"
  codesign --force --options runtime --timestamp --entitlements "$ENTITLEMENTS_PATH" --sign "$SIGN_IDENTITY" "$DIST_APP"
  sanitize_app_bundle "$DIST_APP"
  codesign --verify --deep --strict --verbose=2 "$DIST_APP"
else
  echo "No CLEANMAC_SIGN_IDENTITY configured; applying ad-hoc signature for local validation."
  codesign --force --deep --options runtime --sign - "$DIST_APP"
  codesign --force --options runtime --entitlements "$ENTITLEMENTS_PATH" --sign - "$DIST_APP"
  sanitize_app_bundle "$DIST_APP"
  codesign --verify --deep --strict --verbose=2 "$DIST_APP"
fi

create_zip "$ZIP_PATH"

if [[ "$NOTARIZE" == "1" || "$NOTARIZE" == "true" ]]; then
  if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "error: CLEANMAC_NOTARIZE requires CLEANMAC_SIGN_IDENTITY." >&2
    exit 1
  fi

  build_notary_args || {
    echo "error: notarization requires CLEANMAC_NOTARY_PROFILE, API key variables, or Apple ID variables." >&2
    exit 1
  }

  echo "Submitting $ZIP_PATH for notarization..."
  xcrun notarytool submit "$ZIP_PATH" --wait "${NOTARY_ARGS[@]}"
  xcrun stapler staple "$DIST_APP"
  xcrun stapler validate "$DIST_APP"
  sanitize_app_bundle "$DIST_APP"
  create_zip "$ZIP_PATH"
fi

# Reading the app while creating the archive can make File Provider attach
# Finder metadata again. Remove it on a best-effort basis; verify the actual
# distributable ZIP from a fresh extraction below.
sanitize_app_bundle "$DIST_APP"
verify_zip "$ZIP_PATH"

shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "Created:"
echo "  $DIST_APP"
echo "  $ZIP_PATH"
echo "  $ZIP_PATH.sha256"
