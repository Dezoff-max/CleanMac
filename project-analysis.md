# Project Analysis

## Purpose

CleanMac is a macOS menu bar and windowed system cleanup utility. The project was intentionally reset from the original upstream code so cleanup behavior can be built safely.

## Current Structure

- `CleanMac/`: macOS SwiftUI application and asset catalog.
- `CleanMacCore/`: SwiftPM library for reusable cleanup/scanning logic.
- `script/build_and_run.sh`: local Debug build and launch entrypoint.
- `script/package_release.sh`: local Release `.app`, drag-to-Applications `.dmg`, fallback `.zip`, and `.sha256` packaging.
- `.github/workflows/ci.yml`: GitHub CI for core tests, Debug app build, and unsigned Release artifact.
- `.github/workflows/release.yml`: idempotent tag-driven GitHub Release workflow for unsigned/ad-hoc zip and sha256 assets, with optional Developer ID signing/notarization when private secrets are configured; it creates a missing release or replaces matching assets on an existing release without overwriting its notes.
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
- Main Dashboard/Scan/Results/Applications/Settings window builds and launches; live permission controls are consolidated inside Settings instead of occupying a separate sidebar destination.
- Main content pages use the supplied light technology background while preserving the native macOS sidebar.
- Sidebar navigation uses subtle modern hover, click, and keyboard focus feedback while preserving the selected accent row. Applications uses the installed system App Store Retina icon through `NSWorkspace`, with a visible system-symbol fallback. The footer has persistent RU/EN language and light/dark appearance controls; language still defaults from system preferences when no override exists.
- Menu bar Open focuses the existing main window before creating a new one.
- `CleanMacCore` has a read-only scanner for user caches, logs, temporary files, Trash, Downloads review, Xcode Derived Data, browser caches, Node/npm/Yarn/pnpm caches, SwiftPM cache, and downloaded installers.
- Advanced developer cleanup uses exact allowlists for Homebrew, pip, Cargo registry cache/source, Gradle, Cursor/VS Code caches, Codex/Claude cache/temp folders, Xcode DeviceSupport, Previews, old user Simulator data, and individual Xcode Archives. IDE settings/extensions and AI projects/sessions/history/memory are excluded; Simulator and Archives require review, and Archives are never selected by default.
- Stale Codex installer runtimes have a separate review-only rule for exact direct `~/.cache/codex-runtimes/codex-runtime-install-[A-Za-z0-9]+` directories older than seven days. The active `codex-primary-runtime`, recent or malformed installers, nested paths, and symlinks are excluded; Results starts them unselected, Safe Mode locks them, and the planner repeats every boundary check before an explicitly confirmed move to Trash.
- Disk Analysis is a separate read-only workspace with whole-disk (`/` with no path exclusions), Home, Downloads, and custom-folder sources. One cancellable scan powers a bounded multi-ring folder map plus a non-selected large-file list with 50 MB, 100 MB, 500 MB, and 1 GB filters, size/date/type sorting, and Finder/Open actions. Its data never enters cleanup reports, junk totals, history, or scheduled scans.
- Long read-only analysis no longer drives the entire SwiftUI layout at 30 FPS. Disk Analysis and normal scan progress use event-driven/system progress visuals, pending progress streams keep only the newest event, and Disk Analysis/Duplicate Finder workers run at utility priority. A repeated Home analysis benchmark dropped from 111–124% CPU to a 28.6% startup sample followed by 1.5% and idle-level samples while the scan remained active.
- Duplicate Finder is a separate Home, Downloads, or custom-folder workspace. It narrows candidates by logical size and a first-block SHA-256 before streaming the full SHA-256 only for survivors, excludes hard links, limits hashing concurrency, protects one deterministic original in every group, starts with no selected copies, and moves only explicitly confirmed unchanged copies to Trash. Standard mode reports matching-size files over 500 MiB without hiding them; an optional slow mode hashes them.
- Smart Shredder is a separate neo-glow sidebar workspace for explicitly selected ordinary files. It rejects directories, symlinks, hard links, package contents, protected system roots, and files changed after review; requires an acknowledgement plus an exact typed phrase; then overwrites the pinned file descriptor with random data, syncs, truncates, revalidates device/inode identity, and unlinks directly without Trash, cleanup history, restore, scheduling, or cancellation after execution begins. Its UI states that SSD/APFS physical recovery cannot be guaranteed and recommends FileVault for future protection.
- Disk Analysis and Duplicate Finder intercept their Custom Folder segment before changing source state, present the native folder panel on the next main-actor turn, preserve the previous source on cancel, and activate the custom source only after a real folder selection.
- Results UI is backed by real scanner output, safe results are selected by default, and cleanup requires explicit confirmation.
- Safe Mode now keeps review-risk results visible but unselectable, clears stale review selections when enabled, and rechecks risk immediately before cleanup execution.
- Results now explain why each item was suggested, using structured reasons produced by the scanner rules.
- Results now lists unavailable scan areas with localized names and exact paths, distinguishes missing optional folders from read failures, and links permission-related failures to the in-app Permissions screen.
- Cleanup planning validates paths against category roots and moves accepted items to Trash instead of permanently deleting them.
- Applications has a separate uninstaller for direct third-party `.app` bundles in `/Applications` and `~/Applications`; native checkboxes support multi-selection, exact bundle-ID leftover choices remain isolated per app, one batch confirmation shows the reviewed count and size, and every app still removes first so its failed removal cannot touch leftovers. Trash mode remains the default. Permanent mode is an explicit segmented choice that auto-includes every shown exact bundle-ID leftover and deletes directly without Trash or CleanMac restore history.
- Results UI now has compact category groups, risk-aware item review, a selected-item detail panel, and locally persisted Trash history with restore actions.
- Cleanup history uses a versioned atomic JSON store with private permissions, unique operation IDs, a 100-record cap, fail-closed decoding, multi-window read-merge-write updates, and visible persistence errors. Persisted restores revalidate a direct child of the current user's Trash and a canonical destination inside the saved category allowlist, then open every directory component without following symlinks and use descriptor-relative exclusive rename.
- Restore logic refuses to overwrite existing original paths and reports missing Trash/original locations without deleting anything.
- Scan UI has all/safe/review filters plus safe/review/clear selection presets.
- Scan UI shows a modern animated activity surface during active scans, with Reduce Motion support and selected-area chips.
- Standard cleanup, Disk Analysis, Duplicate Finder, and Applications scanning share a modern orbit-style indicator. Its rotation, pulse, shimmer, and signal motion are isolated state-driven animations instead of a display-frame `TimelineView`, preserving the thermal optimization while avoiding the gray system spinner.
- Scan UI now binds to real scanner progress, including current area, percentage, found count, and measured size while scanning.
- Downloads, logs, and temporary files use conservative smart rules to reduce noisy candidates from recent small downloads and likely active files.
- Settings includes the complete live Permissions UI, checks Full Disk Access by probing protected metadata/readability, and can refresh or open the relevant system panes.
- Finder Automation now shows the live Apple Events consent state, requests access only from an explicit button, and uses the permission to reveal selected items while preserving the NSWorkspace fallback.
- English and Russian app localizations are included; macOS selects the language from system preferences.
- The standard About panel is replaced by a centered singleton CleanMac window with live version/build metadata, local-first safety details, project links, and immediate RU/EN plus light/dark updates.
- The selected language override applies through the app's localizer, and the selected appearance applies to both the main window and menu bar popover.
- The menu bar popover is a compact live dashboard with CPU, memory, disk, battery, network, uptime, scan state, and last-scan summary. Its 2x2 gauge layout uses system materials and follows the light/dark appearance selected in CleanMac rather than a fixed reference color scheme.
- System has a separate manual workspace for two non-file-deleting maintenance actions: freeing inactive memory through `/usr/sbin/purge` and flushing DNS cache through `/usr/bin/dscacheutil -flushcache` plus `/usr/bin/killall -HUP mDNSResponder`. Commands use exact fixed scripts, no user-provided shell interpolation, no scheduling, and visible success/partial/failure states. Because modern macOS rejects these operations from a normal user process, the actions use the macOS administrator authorization prompt only after the user clicks a button. The memory action also shows the same read-only VM usage gauge as the menu bar and records before/after snapshots so users can see whether usage visibly dropped, stayed roughly the same, or rose again.
- When free disk capacity falls strictly below 10%, the menu bar shows an adaptive warning with the remaining space, recommends a scan, and opens Disk Analysis directly without starting it. A background check runs at launch and every 30 minutes; when macOS notifications are already allowed, it can send at most one warning per 24 hours.
- Settings can enable read-only auto scan while the app is running; it supports daily, hourly, and every-two-hours frequencies, uses the currently selected scan areas, and updates menu bar status.
- Settings can register the main app through `SMAppService.mainApp` to launch at login, displays the authoritative macOS enabled/disabled/approval/unavailable status, reports registration failures, and links to Login Items when user action is required. Login-style background launch keeps the main window hidden until the user activates CleanMac or chooses Open from the menu bar.
- Scheduled auto scan can show localized macOS completion notifications when the notification toggle is enabled and system permission allows it; Settings includes a test notification button to diagnose macOS permission/delivery state. Manual scans remain silent.
- Public GitHub Release `v0.4.0` is the latest release and includes the verified arm64 ad-hoc ZIP and SHA-256 assets. It ships the low-disk warning, custom-folder picker fix, scan thermal optimization, Smart Shredder, and refreshed public screenshots.
- Release packaging creates a clean unsigned/ad-hoc app, a compressed DMG with `CleanMac.app` and an `Applications` shortcut, a fallback ZIP, and portable SHA-256 files. It stages the DMG outside the Desktop-backed File Provider path, strictly verifies a fresh mounted image and ZIP extraction, and can optionally sign with Developer ID, enable hardened runtime, submit to Apple notary service, staple, and recreate both archives when credentials are configured.

## Unfinished Or Risky Parts

- This Mac has `0 valid identities found`, so actual Developer ID signing/notarization cannot be performed locally yet; macOS Gatekeeper rejects the current ad-hoc zip as expected.
- Permissions are live for Full Disk Access status, but the app still relies on System Settings for granting access.
- The scanner is intentionally conservative and capped; deeper stale-file heuristics and persistent cleanup previews are future work.
- Standard cleanup and duplicate removal remain intentionally Trash-based. Application removal now has an explicit permanent mode for reviewed `.app` bundles and exact bundle-ID leftovers; it bypasses Trash and CleanMac restore history, so the UI keeps it separate from the default Trash mode. Smart Shredder remains the only best-effort overwrite workflow.
- Smart Shredder cannot guarantee physical-media erasure on SSD/APFS because copy-on-write, snapshots/clones, asynchronous TRIM, and flash wear leveling may retain older blocks outside the selected file's current mapping.
- Duplicate scanning intentionally skips hidden files and package contents, stops at a documented file-count safety limit, and can take substantial time in the explicit large-file mode. Its results remain isolated from junk totals, normal cleanup history, and scheduled scans.
- Scheduled auto scan still runs inside the CleanMac process rather than a privileged agent, but the optional Login Item can now start that process automatically after macOS login.
- System maintenance commands depend on macOS administrator authorization. If the user cancels the system prompt or macOS rejects the operation, CleanMac reports the failure and does not retry in the background.
- Notification delivery depends on the macOS notification permission for CleanMac; if permission is denied, scheduled scans still complete silently and the low-space warning remains available inside the menu-bar popover.
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
2. Decide whether to add read-only system-managed Simulator runtime guidance through Xcode tooling rather than moving `/Library` bundles directly.
3. Decide whether application removals should have a separate, equally constrained history model.
