#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/cleanmac-launch-tests.XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

xcrun swiftc \
    -swift-version 5 \
    -target "$(uname -m)-apple-macosx14.0" \
    -module-cache-path "$TEST_DIR/module-cache" \
    "$ROOT_DIR/CleanMac/Support/CleanMacLaunchContext.swift" \
    "$ROOT_DIR/Tests/CleanMacLaunchRegression.swift" \
    -o "$TEST_DIR/launch-regression"

"$TEST_DIR/launch-regression"
