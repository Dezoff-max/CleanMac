# Project Analysis

## Purpose

CleanMac is a macOS menu bar and windowed system cleanup utility. The project was intentionally reset from the original upstream code so cleanup behavior can be built safely.

## Current Structure

- `CleanMac/`: macOS SwiftUI application and asset catalog.
- `CleanMacCore/`: SwiftPM library for reusable cleanup/scanning logic.
- `script/build_and_run.sh`: local Debug build and launch entrypoint.
- `script/package_release.sh`: local Release `.app`, `.zip`, and `.sha256` packaging.
- `.github/workflows/ci.yml`: GitHub CI for core tests, Debug app build, and unsigned Release artifact.
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

- First launch now opens a localized four-step system-adaptive onboarding inside the primary window. It introduces only shipped CleanMac capabilities, checks Full Disk Access without prompting, opens privacy settings only from an explicit button, and persists completion or skip so later launches open the main UI directly.
- Repository was cleaned and renamed to CleanMac.
- App icon, menu bar icon, Dashboard brand icon, status menu brand icon, design assets, and docs icon use the supplied detailed broom artwork from `Design/source-icon.png`.
- Public GitHub repository and CI were configured.
- Local `dist/` packaging exists and is ignored by git.
- Main Dashboard/Scan/Results/Applications/Permissions/Settings window builds and launches.
- Main content pages use the supplied light technology background while preserving the native macOS sidebar.
- Sidebar navigation uses subtle modern hover, click, and keyboard focus feedback while preserving the selected accent row, and the footer has persistent RU/EN language and light/dark appearance controls; language still defaults from system preferences when no override exists.
- Menu bar Open focuses the existing main window before creating a new one.
- `CleanMacCore` has a read-only scanner for user caches, logs, temporary files, Trash, Downloads review, Xcode Derived Data, browser caches, Node/npm/Yarn/pnpm caches, SwiftPM cache, and downloaded installers.
- Disk Analysis is a separate read-only workspace with whole-disk (`/` with no path exclusions), Home, Downloads, and custom-folder sources. One cancellable scan powers a bounded multi-ring folder map plus a non-selected large-file list with 50 MB, 100 MB, 500 MB, and 1 GB filters, size/date/type sorting, and Finder/Open actions. Its data never enters cleanup reports, junk totals, history, or scheduled scans.
- Results UI is backed by real scanner output, safe results are selected by default, and cleanup requires explicit confirmation.
- Safe Mode now keeps review-risk results visible but unselectable, clears stale review selections when enabled, and rechecks risk immediately before cleanup execution.
- Results now explain why each item was suggested, using structured reasons produced by the scanner rules.
- Results now lists unavailable scan areas with localized names and exact paths, distinguishes missing optional folders from read failures, and links permission-related failures to the in-app Permissions screen.
- Cleanup planning validates paths against category roots and moves accepted items to Trash instead of permanently deleting them.
- Applications has a separate safe uninstaller for direct third-party `.app` bundles in `/Applications` and `~/Applications`; native checkboxes support multi-selection, exact bundle-ID leftover choices remain isolated per app, one batch confirmation shows the reviewed count and size, and every app still moves first so its failed move cannot touch leftovers.
- Results UI now has compact category groups, risk-aware item review, a selected-item detail panel, and locally persisted Trash history with restore actions.
- Cleanup history uses a versioned atomic JSON store with private permissions, unique operation IDs, a 100-record cap, fail-closed decoding, multi-window read-merge-write updates, and visible persistence errors. Persisted restores revalidate a direct child of the current user's Trash and a canonical destination inside the saved category allowlist, then open every directory component without following symlinks and use descriptor-relative exclusive rename.
- Restore logic refuses to overwrite existing original paths and reports missing Trash/original locations without deleting anything.
- Scan UI has all/safe/review filters plus safe/review/clear selection presets.
- Scan UI shows a modern animated activity surface during active scans, with Reduce Motion support and selected-area chips.
- Scan UI now binds to real scanner progress, including current area, percentage, found count, and measured size while scanning.
- Downloads, logs, and temporary files use conservative smart rules to reduce noisy candidates from recent small downloads and likely active files.
- Permissions UI checks live Full Disk Access status by probing protected metadata/readability and can refresh the result.
- Finder Automation now shows the live Apple Events consent state, requests access only from an explicit button, and uses the permission to reveal selected items while preserving the NSWorkspace fallback.
- English and Russian app localizations are included; macOS selects the language from system preferences.
- The standard About panel is replaced by a centered singleton CleanMac window with live version/build metadata, local-first safety details, project links, and immediate RU/EN plus light/dark updates.
- The selected language override applies through the app's localizer, and the selected appearance applies to both the main window and menu bar popover.
- The menu bar popover shows current disk usage, scan-in-progress state, last scan source/time, and last scan result summary with larger readable typography and rounded compact panels.
- Settings can enable read-only auto scan while the app is running; it supports daily, hourly, and every-two-hours frequencies, uses the currently selected scan areas, and updates menu bar status.
- Scheduled auto scan can show localized macOS completion notifications when the notification toggle is enabled and system permission allows it; Settings includes a test notification button to diagnose macOS permission/delivery state. Manual scans remain silent.
- Public GitHub Release `v0.2.1` is the latest release and includes the verified arm64 ad-hoc zip and sha256 assets.
- Release packaging creates a clean unsigned/ad-hoc local zip plus sha256, strips Finder/resource-fork metadata before archiving, strictly verifies a fresh ZIP extraction, and can optionally sign with Developer ID, enable hardened runtime, submit to Apple notary service, staple, and re-zip when credentials are configured.

## Unfinished Or Risky Parts

- This Mac has `0 valid identities found`, so actual Developer ID signing/notarization cannot be performed locally yet; macOS Gatekeeper rejects the current ad-hoc zip as expected.
- Permissions are live for Full Disk Access status, but the app still relies on System Settings for granting access.
- The scanner is intentionally conservative and capped; deeper stale-file heuristics and persistent cleanup previews are future work.
- Cleanup is intentionally Trash-based; permanent deletion is still out of scope.
- Scheduled auto scan currently runs only while the CleanMac app process is running; launch-at-login or a privileged background agent is still future work.
- Notification delivery depends on the macOS notification permission for CleanMac; if permission is denied, scheduled scans still complete silently.
- Root-owned or otherwise protected third-party apps may fail to move without administrator privileges; CleanMac reports the failure and does not escalate privileges or remove leftovers.
- Whole-disk analysis intentionally attempts every path beneath `/`, including system and mounted-volume paths. macOS-protected locations remain unreadable without the required system access, while APFS firmlinks/mounted representations can make the measured total differ from Finder; the UI reports these limitations and never treats the result as junk. The analysis UI uses a custom Reduce Motion-aware progress indicator and an interactive radial map whose hovered sector enlarges and reports its exact size in GB.
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
2. Add launch-at-login support so scheduled scans can happen after reboot/login without manually opening CleanMac.
3. Add deeper developer storage previews.
4. Decide whether application removals should have a separate, equally constrained history model.
