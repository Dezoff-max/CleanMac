#!/bin/bash
set -euo pipefail

# Compile the real app preferences/catalog against an existing Xcode core build.
# Optional argument: the Debug or Release Build/Products directory to validate.
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PRODUCTS_DIR="${1:-$REPO_ROOT/build/XcodeData/Build/Products/Debug}"
if [[ ! -f "$PRODUCTS_DIR/CleanMacCore.o" ]]; then
    echo "Build CleanMac first, or pass its Build/Products/Debug or Release directory." >&2
    exit 1
fi

TEST_DIR="$(mktemp -d /private/tmp/cleanmac-preferences-tests.XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

xcrun swiftc \
    -swift-version 5 \
    -target "$(uname -m)-apple-macosx14.0" \
    -module-cache-path "$TEST_DIR/module-cache" \
    -I "$PRODUCTS_DIR" \
    "$REPO_ROOT/CleanMac/Support/CleanMacPreferences.swift" \
    "$REPO_ROOT/CleanMac/Models/CleanMacModels.swift" \
    "$REPO_ROOT/CleanMac/Support/CleanMacFormatters.swift" \
    "$REPO_ROOT/CleanMac/Support/Localizer.swift" \
    "$REPO_ROOT/CleanMac/Support/FullDiskAccessChecker.swift" \
    "$REPO_ROOT/CleanMac/Support/CleanMacAutomationService.swift" \
    "$REPO_ROOT/Tests/CleanMacPreferencesRegression.swift" \
    "$PRODUCTS_DIR/CleanMacCore.o" \
    -o "$TEST_DIR/preferences-regression"

"$TEST_DIR/preferences-regression"
