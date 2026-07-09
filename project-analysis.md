# Project Analysis

## Purpose

CleanMac is a fresh macOS menu bar and windowed app shell for a custom system cleanup tool. The project was intentionally reset from the original upstream code so new cleanup behavior can be built safely.

## Current Structure

- `CleanMac/`: macOS SwiftUI application and asset catalog.
- `CleanMacCore/`: SwiftPM library for reusable cleanup/scanning logic.
- `script/build_and_run.sh`: local Debug build and launch entrypoint.
- `script/package_release.sh`: local Release `.app`, `.zip`, and `.sha256` packaging.
- `.github/workflows/ci.yml`: private GitHub CI for core tests, Debug app build, and unsigned Release artifact.
- `.github/workflows/release.yml`: tag-driven GitHub Release workflow for unsigned/ad-hoc zip and sha256 assets, with optional Developer ID signing/notarization when private secrets are configured.
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
- App icon, menu bar icon, Dashboard brand icon, status menu brand icon, design assets, and docs icon use the supplied detailed broom artwork from `Design/source-icon.png`.
- Private GitHub repository and CI were configured.
- Local `dist/` packaging exists and is ignored by git.
- Main Dashboard/Scan/Results/Permissions/Settings window builds and launches.
- Main content pages use the supplied light technology background while preserving the native macOS sidebar.
- Sidebar footer now has persistent RU/EN language and light/dark appearance controls; language still defaults from system preferences when no override exists.
- Menu bar Open focuses the existing main window before creating a new one.
- `CleanMacCore` has a read-only scanner for user caches, logs, temporary files, Trash, Downloads review, Xcode Derived Data, browser caches, Node/npm/Yarn/pnpm caches, SwiftPM cache, and downloaded installers.
- Results UI is backed by real scanner output, safe results are selected by default, and cleanup requires explicit confirmation.
- Results now explain why each item was suggested, using structured reasons produced by the scanner rules.
- Cleanup planning validates paths against category roots and moves accepted items to Trash instead of permanently deleting them.
- Results UI now has compact category groups, risk-aware item review, a selected-item detail panel, and current-session Trash history with restore actions.
- Restore logic refuses to overwrite existing original paths and reports missing Trash/original locations without deleting anything.
- Scan UI has all/safe/review filters plus safe/review/clear selection presets.
- Scan UI shows a modern animated activity surface during active scans, with Reduce Motion support and selected-area chips.
- Scan UI now binds to real scanner progress, including current area, percentage, found count, and measured size while scanning.
- Downloads, logs, and temporary files use conservative smart rules to reduce noisy candidates from recent small downloads and likely active files.
- Permissions UI checks live Full Disk Access status by probing protected metadata/readability and can refresh the result.
- English and Russian app localizations are included; macOS selects the language from system preferences.
- The selected language override applies through the app's localizer, and the selected appearance applies to both the main window and menu bar popover.
- The menu bar popover shows current disk usage, scan-in-progress state, last scan source/time, and last scan result summary.
- Settings can enable a read-only daily auto scan at a selected time while the app is running; it uses the currently selected scan areas and updates menu bar status.
- Private GitHub Release `v0.1.0` exists with unsigned zip and sha256 assets.
- Release packaging can optionally sign with Developer ID, enable hardened runtime, submit to Apple notary service, staple, and re-zip when credentials are configured.

## Unfinished Or Risky Parts

- This Mac has `0 valid identities found`, so actual Developer ID signing/notarization cannot be performed locally yet; macOS Gatekeeper rejects the current ad-hoc zip as expected.
- Permissions are live for Full Disk Access status, but the app still relies on System Settings for granting access.
- The scanner is intentionally conservative and capped; deeper stale-file heuristics and persistent cleanup previews are future work.
- Cleanup is intentionally Trash-based; permanent deletion is still out of scope.
- Cleanup history is current-session only; persistent history across app launches is still future work.
- Scheduled auto scan currently runs only while the CleanMac app process is running; launch-at-login or a privileged background agent is still future work.
- Local Xcode emits a CoreSimulator warning; it does not currently block macOS builds.

## Strengths

- Small codebase with clean ownership boundaries.
- Separate core package is ready for testable scanning logic.
- CI, local packaging, and tag-based GitHub Release packaging are already working, with private signing secrets documented for later.
- Menu bar plus window lifecycle is a good fit for a cleanup utility.

## Problems

- Distribution automation is ready for signing/notarization, but no Developer ID certificate is installed on this Mac yet.
- Full Disk Access can be checked, but there is no in-app permission grant flow because macOS requires System Settings.
- Toolbar Accessibility exposes descriptions, but SwiftUI does not give stable button names for every automation path.

## Recommended Next Work

1. Configure Apple Developer signing secrets and cut a signed/notarized release.
2. Persist cleanup history safely across app launches.
3. Add launch-at-login support so scheduled scans can happen after reboot/login without manually opening CleanMac.
4. Add deeper cleanup previews for large downloads and developer caches.
5. Add more permission-specific scanner hints when protected roots are unavailable.
