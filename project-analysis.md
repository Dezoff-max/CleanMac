# Project Analysis

## Purpose

CleanMac is a fresh macOS menu bar and windowed app shell for a custom system cleanup tool. The project was intentionally reset from the original upstream code so new cleanup behavior can be built safely.

## Current Structure

- `CleanMac/`: macOS SwiftUI application and asset catalog.
- `CleanMacCore/`: SwiftPM library for reusable cleanup/scanning logic.
- `script/build_and_run.sh`: local Debug build and launch entrypoint.
- `script/package_release.sh`: local Release `.app`, `.zip`, and `.sha256` packaging.
- `.github/workflows/ci.yml`: private GitHub CI for core tests, Debug app build, and unsigned Release artifact.
- `docs/` and `Design/`: icon and project assets.

## Tech Stack

- SwiftUI for macOS 14+.
- Xcode project for the macOS app.
- SwiftPM for `CleanMacCore`.
- GitHub Actions on macOS runners.

## Discovered Commands

- Install: none required.
- Run/dev: `./script/build_and_run.sh`
- Verify launch: `./script/build_and_run.sh --verify`
- Package: `./script/package_release.sh`
- Test: `swift test --package-path CleanMacCore`
- Build: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
- Lint/typecheck: no dedicated lint command found.

## Completed Parts

- Repository was cleaned and renamed to CleanMac.
- App icon and menu bar icon were replaced.
- Private GitHub repository and CI were configured.
- Local `dist/` packaging exists and is ignored by git.
- Minimal menu bar app shell builds and launches.

## Unfinished Or Risky Parts

- Main UI is still skeletal.
- No real scanner, cleanup engine, permission workflow, or file deletion safety layer exists yet.
- Any future cleanup implementation must avoid deleting files until scan results, previews, and confirmations are in place.
- Local Xcode emits a CoreSimulator warning; it does not currently block macOS builds.

## Strengths

- Small codebase with clean ownership boundaries.
- Separate core package is ready for testable scanning logic.
- CI and packaging are already working.
- Menu bar plus window lifecycle is a good fit for a cleanup utility.

## Problems

- UI does not yet communicate a useful workflow.
- `CleanMacCore` currently exposes only a placeholder status.
- No permission or safety model is implemented.

## Recommended Next Work

1. Build a complete non-destructive UI shell: Dashboard, Scan, Results, Permissions, Settings.
2. Add a real read-only scanner in `CleanMacCore`.
3. Add scan result previews and tests.
4. Add safe cleanup planning with explicit confirmation, then real deletion only after review.
5. Add release tagging and signed/notarized distribution later.
