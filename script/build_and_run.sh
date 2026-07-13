#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="CleanMac"
BUNDLE_ID="com.codex.cleanmac"
PROJECT_NAME="CleanMac.xcodeproj"
SCHEME_NAME="CleanMac"
CONFIGURATION="Debug"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DATA_DIR="$ROOT_DIR/build/XcodeData"
APP_BUNDLE="$BUILD_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
ENTITLEMENTS_PATH="$ROOT_DIR/CleanMac/CleanMac.entitlements"

sanitize_app_bundle() {
  local app_path="$1"
  xattr -cr "$app_path"
  if command -v SetFile >/dev/null 2>&1; then
    SetFile -a bc "$app_path" 2>/dev/null || true
  fi
  xattr -dr com.apple.FinderInfo "$app_path" 2>/dev/null || true
  xattr -dr com.apple.ResourceFork "$app_path" 2>/dev/null || true
}

codesign_clean_bundle() {
  local app_path="$1"
  shift
  local attempt

  for attempt in 1 2 3; do
    sanitize_app_bundle "$app_path"
    if codesign "$@" "$app_path"; then
      return 0
    fi

    if [[ "$attempt" -lt 3 ]]; then
      echo "codesign metadata race; retrying ($attempt/3)..." >&2
      sleep 0.2
    fi
  done

  return 1
}

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodebuild \
  -project "$PROJECT_NAME" \
  -scheme "$SCHEME_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DATA_DIR" \
  build \
  ENABLE_DEBUG_DYLIB=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY=""

codesign_clean_bundle "$APP_BUNDLE" \
  --force \
  --options runtime \
  --entitlements "$ENTITLEMENTS_PATH" \
  --sign -
codesign_clean_bundle "$APP_BUNDLE" --verify --deep --strict --verbose=2

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
