# Project Analysis

## Purpose

CleanMac is a fresh macOS menu bar and windowed app shell for a custom system cleanup tool. The project was intentionally reset from the original upstream code so new cleanup behavior can be built safely.

## Current Structure

- `CleanMac/`: macOS SwiftUI application and asset catalog.
- `CleanMacCore/`: SwiftPM library for reusable cleanup/scanning logic.
- `script/build_and_run.sh`: local Debug build and launch entrypoint.
- `script/package_release.sh`: local Release `.app`, `.zip`, and `.sha256` packaging.
- `.github/workflows/ci.yml`: private GitHub CI for core tests, Debug app build, and unsigned Release artifact.
- `.github/workflows/release.yml`: tag-driven GitHub Release workflow for unsigned zip and sha256 assets.
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
- Main Dashboard/Scan/Results/Permissions/Settings window builds and launches.
- Menu bar Open focuses the existing main window before creating a new one.
- `CleanMacCore` has a read-only scanner for user caches, logs, temporary files, Trash, Downloads review, and Xcode Derived Data.
- Results UI is backed by real scanner output, safe results are selected by default, and cleanup requires explicit confirmation.
- Cleanup planning validates paths against category roots and moves accepted items to Trash instead of permanently deleting them.
- Scan UI has all/safe/review filters plus safe/review/clear selection presets.
- English and Russian app localizations are included; macOS selects the language from system preferences.
- Private GitHub Release `v0.1.0` exists with unsigned zip and sha256 assets.

## Unfinished Or Risky Parts

- Release builds are unsigned and not notarized; macOS Gatekeeper may warn.
- Permissions are still an informational UI, not a deep permission workflow.
- The scanner is intentionally conservative and capped; deeper categories and stale-file heuristics are future work.
- Cleanup is intentionally Trash-based; permanent deletion is still out of scope.
- Local Xcode emits a CoreSimulator warning; it does not currently block macOS builds.

## Strengths

- Small codebase with clean ownership boundaries.
- Separate core package is ready for testable scanning logic.
- CI, local packaging, and tag-based GitHub Release packaging are already working.
- Menu bar plus window lifecycle is a good fit for a cleanup utility.

## Problems

- Distribution is not signed or notarized yet.
- Permission handling is not connected to system authorization checks yet.
- Toolbar Accessibility exposes descriptions, but SwiftUI does not give stable button names for every automation path.

## Recommended Next Work

1. Add Developer ID signing and notarization for a smoother install flow.
2. Connect permission state to real system access checks where useful.
3. Add deeper scanner heuristics for stale files, large downloads, and developer caches.
4. Add richer cleanup previews and restore guidance for Trash-moved items.
