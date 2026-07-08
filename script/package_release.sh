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

if [[ -n "${GITHUB_SHA:-}" ]]; then
  BUILD_ID="${GITHUB_SHA:0:7}"
else
  BUILD_ID="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
fi

ZIP_PATH="$DIST_DIR/$APP_NAME-$BUILD_ID-unsigned.zip"

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

ditto "$BUILT_APP" "$DIST_APP"
COPYFILE_DISABLE=1 ditto -c -k --norsrc --noextattr --keepParent "$DIST_APP" "$ZIP_PATH"
shasum -a 256 "$ZIP_PATH" > "$ZIP_PATH.sha256"

echo "Created:"
echo "  $DIST_APP"
echo "  $ZIP_PATH"
echo "  $ZIP_PATH.sha256"
