# Progress

Append-only history. Do not erase previous entries.

## 2026-07-08 - TASK-001 - Main window UI and launch lifecycle

- What changed: Added Loop project docs, replaced the placeholder window with a multi-section SwiftUI shell, made the main window launch automatically, and kept the app alive in the menu bar after closing the window.
- Files touched: `AGENTS.md`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `loop.md`, `verification.md`, `CleanMac/CleanMacApp.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/*`, `CleanMacCore/Sources/CleanMacCore/CleanMacCore.swift`.
- Checks run: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `pgrep -x CleanMac`; `osascript` window check before and after closing `Dashboard`.
- Result: Passed. The app launched with a `Dashboard` window, and the process stayed alive after the window was closed.
- Next step: TASK-002 read-only cleanup scanner.
- Bottleneck: implementation
- Handoff: The UI is intentionally non-destructive. The disabled cleanup action should remain disabled until real scan results and confirmation logic exist.

## 2026-07-08 - TASK-002/TASK-003/TASK-006 - Read-only scanner, results UI, localization, and window focus polish

- What changed: Added typed read-only cleanup scanner models/services, connected Scan/Results/Dashboard UI to real scanner output, added English and Russian localizations, added a narrow main-window focus bridge for menu Open, and kept cleanup disabled until confirmation logic exists.
- Files touched: `CleanMac.xcodeproj/project.pbxproj`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/*`, `CleanMac/Views/*`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupScanner.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `find build/XcodeData/Build/Products/Debug/CleanMac.app/Contents/Resources -maxdepth 2 -type f`; `osascript` UI checks for Russian window, scan navigation, close-to-menu lifecycle, and Open window reuse; `./script/package_release.sh`.
- Result: Passed. The app launches in Russian on this system, scan navigates to Results, localization resources are bundled, read-only scanner tests pass, and menu Open keeps one `CleanMacMainWindow`.
- Next step: TASK-004 safe cleanup planning with explicit confirmation and strict deletion boundaries.
- Bottleneck: cleanup safety design
- Handoff: The current app can inspect and estimate cleanup candidates only. Do not enable deletion until TASK-004 defines allowlists, confirmation UI, and tests.

## 2026-07-08 - TASK-007 - Dashboard scan area discoverability and initial fit

- What changed: The Dashboard now shows the selected scan area names and path hints, includes a `Choose Areas` / `Выбрать области` button that opens the Scan screen, uses tighter vertical spacing, and expands restored short windows to show all Dashboard blocks.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/MainWindowController.swift`, `CleanMac/Views/CleanMacComponents.swift`, `CleanMac/Views/DashboardView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `osascript` window size check; visual screenshot check.
- Result: Passed. The Dashboard shows `Выбранные области` with the four default areas and paths, plus a direct action to change them; the reopened window measured `980x720` and the Safety panel was fully visible.
- Next step: TASK-004 safe cleanup planning with explicit confirmation and strict deletion boundaries.
- Bottleneck: cleanup safety design
- Handoff: This was a UI discoverability and window fit fix only. Scanner behavior and deletion safety were unchanged.

## Handoff

- Current state: TASK-004, TASK-005, and TASK-008 complete. Private GitHub Release `v0.1.0` exists with unsigned zip and sha256 assets.
- Next recommended task: Add Developer ID signing/notarization or expand scanner heuristics with stronger permissions handling.
- Known blockers: local Xcode reports a CoreSimulator warning, but macOS app builds are not blocked.
- Commands that passed: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `./script/package_release.sh`; `shasum -a 256 -c dist/CleanMac-bd20fa1-unsigned.zip.sha256`; GitHub CI run `28939363191`; GitHub Release run `28939469061`; `gh release view v0.1.0 --repo Dezoff-max/CleanMac`.
- Commands that failed: none.
- Current bottleneck: signing/notarization

## 2026-07-08 - TASK-004/TASK-008 - Safe cleanup and scan selection controls

- What changed: Added allowlisted cleanup planning, Trash-based execution, result selection with explicit confirmation, safe-only default result selection, scan filters, and quick selection presets.
- Files touched: `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/Views/ScanView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMacCore/Sources/CleanMacCore/CleanupExecutor.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPathPolicy.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPlanModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPlanner.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupScanner.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `.github/workflows/release.yml`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `rg -n "removeItem|trashItem|rm -rf|unlink\\(|rmdir\\(" CleanMac CleanMacCore script .github`; UI smoke test for Scan filters, Results selection, and cleanup confirmation alert.
- Result: Passed for TASK-004 and TASK-008. Cleanup is confirmation-gated and uses `FileManager.trashItem`; no production permanent deletion path was added.
- Next step: Finish TASK-005 by pushing `main`, creating tag `v0.1.0`, watching the Release workflow, and verifying the uploaded zip and sha256 assets.
- Bottleneck: release
- Handoff: The UI confirmation was opened and cancelled during testing, so no scanned user files were moved.

## 2026-07-08 - TASK-005 - Release tagging

- What changed: Pushed implementation commit `bd20fa1`, verified GitHub CI, created and pushed tag `v0.1.0`, and verified the GitHub Release assets in the private `Dezoff-max/CleanMac` repository.
- Files touched: `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `./script/package_release.sh`; `shasum -a 256 -c dist/CleanMac-bd20fa1-unsigned.zip.sha256`; `git push origin main`; GitHub CI run `28939363191`; `git push origin v0.1.0`; GitHub Release run `28939469061`; `gh release view v0.1.0 --repo Dezoff-max/CleanMac --json tagName,name,url,isDraft,isPrerelease,assets,targetCommitish,createdAt,publishedAt`; `gh repo view Dezoff-max/CleanMac --json nameWithOwner,isPrivate,url,visibility`.
- Result: Passed. Release `https://github.com/Dezoff-max/CleanMac/releases/tag/v0.1.0` is published with `CleanMac-bd20fa1-unsigned.zip` and `CleanMac-bd20fa1-unsigned.zip.sha256`; repository visibility is private.
- Next step: Add Developer ID signing/notarization or expand scanner heuristics.
- Bottleneck: signing/notarization
- Handoff: The release zip is unsigned; macOS Gatekeeper may warn until a Developer ID signing/notarization workflow is added.

## 2026-07-08 - TASK-009/TASK-010/TASK-011/TASK-012 - Signing readiness, expanded scanner, live access, and icon refresh

- What changed: Replaced the icon everywhere with the supplied broom/code artwork, expanded the scanner with browser cache, Node package cache, SwiftPM cache, and downloaded installer categories, added live Full Disk Access status with refresh, and upgraded release packaging/GitHub Releases for optional Developer ID signing and notarization.
- Files touched: `.github/workflows/release.yml`, `CleanMac/Assets.xcassets/**`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/FullDiskAccessChecker.swift`, `CleanMac/Views/*`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMacCore/Sources/CleanMacCore/**`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `docs/signing-notarization.md`, `script/package_release.sh`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `bash -n script/package_release.sh`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshots for Dashboard, Scan, Permissions, and menu bar; `./script/package_release.sh`; `shasum -a 256 -c dist/CleanMac-5f4ae88-unsigned.zip.sha256`; zip extraction followed by `codesign --verify --deep --strict --verbose=2`; `spctl -a -vv`; `security find-identity -p codesigning -v`.
- Result: Passed for implementation and unsigned/ad-hoc package validation. The zip artifact extracts to a valid ad-hoc signed app; `spctl` rejects it as expected without Developer ID signing.
- Next step: Configure Apple Developer certificate/notary secrets and create a signed/notarized release tag.
- Bottleneck: Apple Developer credentials
- Handoff: `security find-identity -p codesigning -v` reports `0 valid identities found`, so actual Developer ID signing/notarization was not possible on this Mac. The workflow and docs are ready for credentials.

## 2026-07-09 - TASK-013 - Cleaner-style review UX and Trash restore guidance

- What changed: Reworked Results into a cleaner-style review workspace with top summary metrics, compact category groups, visible item list, selected-item detail panel, risk explanations, and current-session Trash history. Added `CleanupRestorer` to restore recorded moved items from Trash without overwriting existing original paths.
- Files touched: `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMacCore/Sources/CleanMacCore/CleanupPlanModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupRestorer.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; `rg -n "removeItem|trashItem|moveItem|unlink\\(|rmdir\\(" CleanMac CleanMacCore script .github`; `git diff --check`; visual screenshots `/tmp/cleanmac-task13-results.png` and `/tmp/cleanmac-task13-results-v2.png`.
- Result: Passed. Results now shows category groups, list, and detail panel in the standard window; restore behavior is covered by tests and refuses overwrites.
- Next step: Add persistent cleanup history or deeper stale-file heuristics.
- Bottleneck: product decision
- Handoff: Current-session restore is implemented. No real user cleanup was triggered during manual UI checks.

## 2026-07-09 - TASK-014 - Modern scan activity animation

- What changed: Added a modern animated scan activity surface with orbital radar motion, pulsing rings, signal bars, localized scan phases, selected-area chips, Reduce Motion support, and a short minimum visible scan duration so fast scans do not skip the animation.
- Files touched: `CleanMac/Views/ScanActivityView.swift`, `CleanMac/Views/ScanView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; visual screenshot `/tmp/cleanmac-task14-scanning.png`; `swift test --package-path CleanMacCore`; `git diff --check`.
- Result: Passed. The scan screen displays the animated module during scanning and remains readable in the standard window.
- Next step: Add deeper scanner heuristics or persistent cleanup history.
- Bottleneck: product decision
- Handoff: This is UI-only. Scanner and cleanup safety behavior were not changed.

## 2026-07-09 - TASK-015 - Real scan progress and smart cleanup rules

- What changed: Added `CleanupScanProgress` events to the core scanner, connected Scan UI to real percentage/current area/found count/size, polished the scan animation with a progress track and area states, and added conservative smart rules for Downloads, logs, and temporary files.
- Files touched: `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ScanActivityView.swift`, `CleanMac/Views/ScanView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupScanner.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshots `/tmp/cleanmac-task15-scanning.png`, `/tmp/cleanmac-task15-scanning-v2.png`, and `/tmp/cleanmac-task15-scanning-final.png`.
- Result: Passed. Scan shows live progress data during scanning in the default window, and tests cover scanner progress plus smart Downloads filtering.
- Next step: Add richer result explanations for why each item was suggested, or add persistent cleanup history.
- Bottleneck: product decision
- Handoff: Cleanup remains confirmation-gated and Trash-based. No permanent deletion path or destructive background action was added.

## 2026-07-09 - TASK-016 - Unified minimal broom icon

- What changed: Regenerated AppIcon, BrandIcon, MenuBarIcon, design, and docs icon assets from one minimal broom shape. MenuBarIcon now uses template rendering so macOS tints the Retina menu bar silhouette correctly.
- Files touched: `CleanMac/Assets.xcassets/AppIcon.appiconset/*`, `CleanMac/Assets.xcassets/BrandIcon.imageset/*`, `CleanMac/Assets.xcassets/MenuBarIcon.imageset/*`, `Design/app-icon.png`, `Design/toolbar-icon.png`, `docs/assets/icon-256.png`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: PNG dimension checks with `sips`; asset JSON validation with `python3 -m json.tool`; `./script/build_and_run.sh --verify`; visual screenshot `/tmp/cleanmac-menubar-icon-check.png`.
- Result: Passed. The app builds with the updated asset catalog, the in-app brand icon uses the same minimal broom, and the menu bar icon is visible as a system-tinted silhouette.
- Next step: Decide whether to publish a new release for the icon refresh.
- Bottleneck: release decision
- Handoff: Pillow was not needed; icons were generated with system AppKit/CoreGraphics.

## 2026-07-09 - TASK-017 - Supplied broom icon restore

- What changed: Replaced the rejected thin minimal icon with the user's supplied detailed broom artwork everywhere: AppIcon, BrandIcon, MenuBarIcon, design assets, and docs asset. Removed menu bar template rendering so the color icon is preserved, added `Design/source-icon.png` as the canonical source, rebuilt the app, and refreshed LaunchServices/Dock registration.
- Files touched: `CleanMac/Assets.xcassets/AppIcon.appiconset/*`, `CleanMac/Assets.xcassets/BrandIcon.imageset/*`, `CleanMac/Assets.xcassets/MenuBarIcon.imageset/*`, `Design/app-icon.png`, `Design/toolbar-icon.png`, `Design/source-icon.png`, `docs/assets/icon-256.png`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`.
- Checks run: PNG dimension checks with `sips`; asset JSON validation with `python3 -m json.tool`; visual preview `/tmp/cleanmac-supplied-icon-preview.png`; `./script/build_and_run.sh --verify`; LaunchServices registration refresh; `killall Dock`; visual screenshot `/tmp/cleanmac-icon-runtime-after-refresh.png`.
- Result: Passed. The window brand icon, real menu bar icon, and Dock icon all show the supplied broom artwork after rebuild and cache refresh.
- Next step: Decide whether to publish a new GitHub Release with the restored icon.
- Bottleneck: none
- Handoff: The previous thin icon failure is documented in `trace.md`. Pillow was not needed.

## 2026-07-09 - TASK-018 - Main content technology background

- What changed: Added the user's supplied light technology image as `MainWindowBackground`, rendered it behind every shared page container, and kept the native macOS sidebar separate from the custom background.
- Files touched: `CleanMac/Assets.xcassets/MainWindowBackground.imageset/*`, `CleanMac/Views/CleanMacComponents.swift`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`.
- Checks run: background PNG dimension check with `sips`; asset JSON validation with `python3 -m json.tool`; `./script/build_and_run.sh --verify`; screenshots `/tmp/cleanmac-background-check-3.png` and `/tmp/cleanmac-background-settings.png`; `swift test --package-path CleanMacCore`; `git diff --check`.
- Result: Passed. Dashboard and Settings show the supplied background in the main content area, controls remain readable, and the sidebar no longer shows detail content underneath.
- Next step: Decide whether to package or release the visual refresh.
- Bottleneck: none
- Handoff: The first root `ZStack` approach caused sidebar bleed and was replaced with the safer `PageContainer` background approach.

## 2026-07-09 - TASK-019 - Sidebar language and appearance controls

- What changed: Added compact sidebar footer controls for RU/EN language and light/dark appearance, stored preferences with `@AppStorage`, routed localized strings through the selected language bundle, and applied the selected color scheme to the main window and menu bar popover.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/Localizer.swift`, `CleanMac/Views/SidebarView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; screenshots `/tmp/cleanmac-sidebar-controls-en-dark.png` and `/tmp/cleanmac-sidebar-controls-final.png`; `swift test --package-path CleanMacCore`.
- Result: Passed. EN/dark and RU/light states both render correctly, and the controls stay visible at the bottom of the sidebar.
- Next step: Decide whether to package/release the sidebar preference controls or continue with cleanup functionality.
- Bottleneck: none
- Handoff: The local app preference state was returned to RU/light after verification.

## 2026-07-09 - TASK-020 - Result cleanup explanations

- What changed: Added structured scanner reasons to `CleanupScanItem`, assigned reasons from the same rules that include each cleanup candidate, localized reason titles/details, and displayed compact reasons in Results rows with fuller "Почему предложено" explanations in the detail panel.
- Files touched: `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupScanner.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot `/tmp/cleanmac-task20-results-4.png`.
- Result: Passed. Results now shows why each item was suggested without changing cleanup execution, confirmation, or Trash behavior.
- Next step: Add persistent cleanup history or deeper preview metadata for large downloads.
- Bottleneck: product decision
- Handoff: The UI smoke used a read-only scan only; no cleanup action was triggered.

## 2026-07-09 - TASK-021 - Scheduled scan status menu

- What changed: Added persisted scan preferences, a read-only auto-scan scheduler, Settings controls for enable/time, menu bar disk usage, last scan source/time/result summary, and guards so manual and scheduled scans do not overlap.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/CleanMacAutoScanScheduler.swift`, `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Support/CleanMacFormatters.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/Views/StatusMenuView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; defaults-based scheduled scan smoke test (`source=scheduled`, `scanInProgress=0`); visual screenshot `/tmp/cleanmac-status-menu.png`.
- Result: Passed. The menu bar shows readable disk and scan status, and the scheduler updates last scan data from a safe read-only scan.
- Next step: Add launch-at-login support or notifications after scheduled scans.
- Bottleneck: product decision
- Handoff: Auto scan runs only while CleanMac is running; it never performs cleanup or deletion.

## 2026-07-09 - TASK-022 - Auto scan frequency options

- What changed: Added a persisted auto-scan frequency preference, Settings segmented choices for daily/hourly/every-two-hours, interval slot run keys, and next-run calculation for menu bar status.
- Files touched: `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Support/CleanMacAutoScanScheduler.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; defaults-based interval smoke test (`hourly` and `everyTwoHours`); visual screenshot `/tmp/cleanmac-autoscan-frequency-settings-2.png`.
- Result: Passed. Settings now shows the frequency control in Russian, and both interval modes trigger a single read-only scheduled scan for the due slot.
- Next step: Add launch-at-login support so auto scan can work after reboot/login without opening CleanMac manually.
- Bottleneck: product decision
- Handoff: Local test state was returned to daily 10:00 after visual QA so every-two-hours scanning is not accidentally left enabled.

## 2026-07-09 - TASK-023 - Auto scan completion notifications and local release package

- What changed: Added a localized `CleanMacNotificationService`, wired scheduled scan completion notifications through `CleanMacAutoScanScheduler`, added a Settings toggle for auto-scan notifications, requested system notification permission when useful, and hardened local packaging against Finder/resource-fork metadata before zip creation.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/CleanMacAutoScanScheduler.swift`, `CleanMac/Support/CleanMacNotificationService.swift`, `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `script/package_release.sh`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; defaults-based scheduled scan smoke test (`source=scheduled`, `runKey=2026-07-09-15-13`, `scanInProgress=0`); visual screenshot `/tmp/cleanmac-autoscan-notifications-settings-2.png`; `./script/package_release.sh`; `shasum -a 256 -c dist/CleanMac-<commit>-unsigned.zip.sha256`; zip extraction followed by `codesign --verify --deep --strict --verbose=2`; local `dist/CleanMac.app` strict code-sign validation after clearing FinderInfo added by Finder.
- Result: Passed. Scheduled scans can notify with item count and size when the toggle and macOS permission allow it; manual scans remain silent; the fresh local unsigned/ad-hoc package is written as `dist/CleanMac-<commit>-unsigned.zip`.
- Next step: Add launch-at-login support or create a new GitHub Release tag for this package.
- Bottleneck: Apple Developer signing identity for trusted distribution.
- Handoff: Notification permission was not forced during smoke testing; the app requests it only when auto scan and notification settings are enabled. Xcode still emits the known CoreSimulator warning, but macOS builds complete.

## 2026-07-09 - TASK-024 - Modern status menu popover polish

- What changed: Reworked the menu bar popover visual hierarchy with larger disk percentage typography, rounded lightweight status panels, a cleaner header without duplicate status chip, a custom progress bar, and a shorter localized primary action label that fits the two-button footer.
- Files touched: `CleanMac/Views/StatusMenuView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`; visual screenshot `/tmp/cleanmac-status-menu-polished.png`.
- Result: Passed. The open popover is readable in Russian, the primary action no longer truncates, and the disk/last-scan sections render as rounded modern panels.
- Next step: Add click-through behavior from notifications to Results or launch-at-login support.
- Bottleneck: product decision.
- Handoff: This was UI-only; scan, scheduling, cleanup, and packaging behavior were not changed.

## 2026-07-09 - TASK-025 - Settings notification test button

- What changed: Added `CleanMacNotificationService.sendTestNotification`, a Settings "Test Notification" button under the auto-scan notification toggle, localized test notification copy, and inline delivery statuses for sent, disabled, denied, and failed states.
- Files touched: `CleanMac/Support/CleanMacNotificationService.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`; visual screenshot `/tmp/cleanmac-settings-test-notification.png`.
- Result: Passed. Settings shows the test button in Russian without clipping, and notification delivery now reports whether macOS blocked the banner.
- Next step: Add notification click-through behavior or launch-at-login support.
- Bottleneck: product decision.
- Handoff: The test button may trigger the macOS notification permission prompt on first use. No scan, cleanup, or scheduling behavior changed.

## 2026-07-09 - TASK-026 - Animated sidebar hover rows

- What changed: Replaced the static sidebar list rows with custom SwiftUI sidebar buttons that add a subtle hover background, icon emphasis, shadow, and small movement while preserving the selected accent row and Reduce Motion behavior.
- Files touched: `CleanMac/Views/SidebarView.swift`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`; `git diff --check`; visual screenshot `/tmp/cleanmac-sidebar-hover.png`; `./script/package_release.sh`.
- Result: Passed. Sidebar hover is visible on the Scan row, Russian labels fit at the current sidebar width, and navigation selection remains unchanged.
- Next step: Decide whether to add keyboard focus styling or click sound/haptic-style microfeedback.
- Bottleneck: product decision.
- Handoff: This is UI-only. Scan, cleanup, scheduling, notification, and language/theme behavior were not changed.

## 2026-07-09 - TASK-027 - Sidebar click and keyboard focus polish

- What changed: Added a reusable sidebar press `ButtonStyle` for subtle click feedback, made sidebar rows keyboard-focusable, and added a visible focus outline/glow that works alongside the selected accent state.
- Files touched: `CleanMac/Views/SidebarView.swift`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`; `git diff --check`; visual screenshot `/tmp/cleanmac-sidebar-keyboard-focus.png`; `./script/package_release.sh`.
- Result: Passed. Keyboard focus is visible on the Scan row, click feedback compiles into the sidebar button style, labels remain unclipped, and selection behavior is unchanged.
- Next step: Decide whether to add a broader glass sidebar style or leave the sidebar interaction polish restrained.
- Bottleneck: product decision.
- Handoff: This is UI-only. Scan, cleanup, scheduling, notification, language, and theme behavior were not changed.

## 2026-07-11 - TASK-028 - Enforce Safe Mode during cleanup review

- What changed: Connected the existing Safe Mode preference to Results selection and cleanup execution. Review-risk items remain visible but show a disabled checkbox and lock indicator while Safe Mode is enabled; bulk selection and totals only include allowed items; enabling Safe Mode removes stale review selections; cleanup filters risk again before planning or execution.
- Files touched: `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore` (11/11); Debug `xcodebuild`; `./script/build_and_run.sh --verify`; manual Safe Mode ON/OFF scan-results review; screenshot `/tmp/cleanmac-safe-mode-review.png`; independent diff review.
- Result: Passed. A review-risk Derived Data result is locked and unselected with Safe Mode on, becomes selectable when Safe Mode is off, and is removed from selection immediately when Safe Mode is re-enabled. No cleanup action was triggered.
- Next step: TASK-029 - show specific unavailable scan areas and permission guidance instead of only an issue count.
- Bottleneck: none.
- Handoff: Safe Mode is left enabled after verification. The known stale CoreSimulator warning remains non-blocking for macOS builds.

## 2026-07-11 - TASK-030 - Real Finder Automation permission

- What changed: Replaced the static Automation placeholder with a live Finder Apple Events permission state and explicit request/settings actions. Added off-main-thread preflight/request handling, Finder reveal through Apple Events only when granted, the existing NSWorkspace fallback, localized privacy text, the Automation entitlement, hardened Debug/Release signing, and strict verification of the archived release app.
- Files touched: `CleanMac/Support/CleanMacAutomationService.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/PermissionsView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/CleanMac.entitlements`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMac/en.lproj/InfoPlist.strings`, `CleanMac/ru.lproj/InfoPlist.strings`, `CleanMac.xcodeproj/project.pbxproj`, `script/build_and_run.sh`, `script/package_release.sh`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: plist/localization lint; shell syntax checks; `git diff --check`; `swift test --package-path CleanMacCore` (11/11); `./script/build_and_run.sh --verify`; Debug runtime/entitlement/Info.plist inspection; live Permissions UI review through accessibility; `./script/package_release.sh`; SHA-256 verification; fresh ZIP extraction followed by strict codesign, hardened-runtime, entitlement, localized InfoPlist, and usage-description inspection; independent final diff review.
- Result: Passed. Permissions opens without prompting, reports Finder Automation as `Не запрошен`, and exposes the active `Запросить доступ` button. No native consent button was pressed and no macOS privacy setting was changed during verification.
- Next step: The user can press `Запросить доступ` and approve CleanMac in the native macOS dialog, then continue with TASK-029.
- Bottleneck: none in code; the final consent decision belongs to the user.
- Handoff: The release ZIP is ad-hoc signed for local validation because no Developer ID identity is configured. The known stale CoreSimulator warning remains non-blocking for macOS builds.

## 2026-07-11 - TASK-029 - Explain unavailable scan areas

- What changed: Replaced the generic Results issue banner with an actionable availability panel. It groups duplicate failures by cleanup category, shows localized area names and exact paths, distinguishes missing optional folders from read failures, confirms that other areas were scanned, and offers an in-app Permissions action only when reading actually failed.
- Files touched: `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`.
- Checks run: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore` (11/11); `git diff --check`; live read-only scan and accessibility review; screenshot `/tmp/cleanmac-task29-unavailable.png`; in-app Permissions navigation check.
- Result: Passed. A real Safari cache read failure rendered as `Кэши браузеров — Не удалось прочитать` with `/Users/admin/Library/Caches/com.apple.Safari`; `Проверить доступы` opened the CleanMac Permissions page without opening System Settings or triggering another permission request.
- Next step: choose between Developer ID signing, persistent cleanup history, or launch-at-login support.
- Bottleneck: Developer ID distribution still requires Apple credentials; the other product tasks have no current blocker.
- Handoff: No cleanup action was triggered and no files were moved. The existing selected scan areas and Safe Mode behavior were preserved. The known stale CoreSimulator warning remains non-blocking for macOS builds.

## 2026-07-11 - TASK-031 - Safe application uninstaller

- What changed: Added a separate Applications section that scans direct third-party `.app` bundles in `/Applications` and `~/Applications`, excludes Apple apps, CleanMac, symlinks, and nested bundles, and shows only exact bundle-ID Caches, Preferences, Saved Application State, and Logs leftovers. Leftovers are optional and unchecked by default. Removal has a dedicated confirmation, revalidates paths, moves the app first, stops before leftovers if that move fails, and uses Trash rather than permanent deletion.
- Files touched: `CleanMacCore/Sources/CleanMacCore/ApplicationUninstaller.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ApplicationsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (15/15); `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; live read-only Russian UI review; mandatory confirmation review followed by Cancel; screenshot `/tmp/cleanmac-task31-applications.jpg`.
- Result: Passed. The live screen listed 39 third-party applications, showed exact optional leftovers unselected, fit the standard window, and displayed the mandatory app/leftover/size confirmation. Unit tests prove Apple/self/symlink exclusions, app-first Trash order, no leftover attempt after app-move failure, and rejection of outside/forged paths.
- Next step: Add a read-only large-files review or deeper developer-storage cleanup preview.
- Bottleneck: Root-owned third-party apps can require administrator privileges; this version fails safely and does not install a privileged helper.
- Handoff: No installed application or real leftover was moved during verification. The confirmation dialog was cancelled. The known stale CoreSimulator warning remains non-blocking for macOS builds.

## 2026-07-11 - TASK-032 - Multi-select application removal

- What changed: Added native checkbox controls beside every application, separated checkbox selection from detail-row navigation, stored exact leftover choices per application, added a selected app/size summary, and changed the destructive action and confirmation to cover the whole reviewed set. Batch execution sequentially reuses the existing single-app planner and executor, so each app is revalidated and moved before its own leftovers; successful apps leave the list while failures remain selected for review.
- Files touched: `CleanMac/Views/ApplicationsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (15/15); `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; live accessibility and visual review; screenshot `/tmp/cleanmac-task32-multiselect.jpg`.
- Result: Passed. AdGuard Mini and Antigravity stayed checked simultaneously, switching details did not change either checkbox, Antigravity's selected Preferences leftover remained isolated when AdGuard details were open, and the confirmation reported 2 apps, 1 leftover, and 816.2 MB.
- Next step: Add a compact Select visible/Clear selection action if bulk selection becomes frequent, or continue with large-file review.
- Bottleneck: none.
- Handoff: The confirmation was cancelled and no real app or leftover was moved. The known stale CoreSimulator warning remains non-blocking; a transient FinderInfo attribute on the built `.app` was cleared before the successful verification rerun.

## 2026-07-11 - TASK-033 - Custom About window and v0.2.1 release

- What changed: Replaced the sparse system About panel with a centered singleton SwiftUI window modeled on the user's SubPulse and LanScope patterns. It shows the transparent CleanMac artwork, live bundle version/build, localized tagline, developer and MIT license metadata, GitHub/Releases/License links, and a close action. RU/EN and light/dark changes update an already-open window. The final user-directed simplification removes the Data and Cleanup rows and reduces the fixed height. The app version is now 0.2.1 build 3.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Views/AboutView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `CleanMac.xcodeproj/project.pbxproj`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: localization plist lint and RU/EN key parity; `git diff --check`; `swift test --package-path CleanMacCore` (15/15); repeated `./script/build_and_run.sh --verify`; live Russian/light and English/dark accessibility plus visual review; repeated About invocation followed by Window-menu singleton inspection; screenshot `/tmp/cleanmac-task33-about-ru-light.jpg`; `./script/package_release.sh`; SHA-256 comparison; fresh-ZIP strict codesign, version/build, entitlement, and arm64 inspection; independent diff review; protected PR #6 CI; tag-driven Release run 29151074758; downloaded GitHub asset verification.
- Result: Passed. PR #6 is merged, `v0.2.1` is the latest GitHub Release, the downloaded `CleanMac-a5c853e-unsigned.zip` hash is `3dcdfdf49bfaca63bdda83a3bad2940896ea1e31e0df7f1d956ebc08a66b0501`, and its extracted app reports version 0.2.1 (3), arm64, with a valid strict ad-hoc signature.
- Next step: Configure Developer ID signing/notarization when Apple credentials become available, or continue with persistent cleanup history.
- Bottleneck: no Developer ID certificate or notarization credentials are configured, so the public archive remains ad-hoc signed and not notarized.
- Handoff: GitHub release notes are in English and explicitly disclose the distribution limitation. CleanMac was left in the user's Russian/light preferences, and no cleanup or application-removal action was triggered during About verification.

## 2026-07-12 - TASK-034 - Persistent cleanup history

- What changed: Added a versioned atomic `Application Support/CleanMac/cleanup-history.json` store with private permissions, UUID operation IDs, a 100-record cap, fail-closed decoding, and read-merge-write updates that preserve newer records across multiple windows. Results now loads history across launches and persists restored/failed statuses; write failures are reported. Persisted restore validates absolute canonical category paths and direct non-symlink Trash children, opens every directory path component without following symlinks, then uses pinned parent descriptors plus exclusive rename to avoid races and overwrites.
- Files touched: `CleanMacCore/Sources/CleanMacCore/CleanupHistoryStore.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPlanModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPathPolicy.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupRestorer.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (23/23); localization plist lint and RU/EN key parity; `git diff --check`; repeated `./script/build_and_run.sh --verify`; live read-only Russian Results accessibility/visual review; screenshot `/tmp/cleanmac-task34-persistent-history.jpg`; independent security and final diff reviews with no remaining P0-P2 findings.
- Result: Passed. Valid persisted fixtures restore to their allowlisted original location; corrupt/oversized JSON, duplicate IDs, stale window snapshots, source paths outside/directly beneath symlinked Trash parents, category mismatches, prefix collisions, and symlinks in final or intermediate destination components fail safely. No real user file was cleaned or restored.
- Next step: Add read-only large-file review or deeper developer-storage previews.
- Bottleneck: none. Developer ID signing/notarization still separately requires Apple credentials.
- Handoff: The app remains on the Russian/light Results screen. The known stale CoreSimulator warning remains non-blocking for macOS builds.

## 2026-07-12 - TASK-035 - Read-only disk analysis

- What changed: Added a separate Disk Analysis sidebar section backed by a cancellable read-only `CleanMacCore` scanner. It offers no-exclusion whole-disk scanning from `/`, Home, Downloads, and a native custom-folder picker; one scan powers a bounded radial multi-ring map with folder drill-down/breadcrumbs and a large-file list with 50/100/500 MB/1 GB filters, size/date/type sorting, nil initial selection, and Finder/Open actions. Analyzer results never enter cleanup reports, junk totals, cleanup selection, history, or scheduled scans.
- Files touched: `CleanMacCore/Sources/CleanMacCore/DiskAnalyzer.swift`, `CleanMacCore/Tests/CleanMacCoreTests/DiskAnalyzerTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/DiskAnalysisWorkspaceService.swift`, `CleanMac/Views/DiskAnalysisView.swift`, `CleanMac/Views/DiskSunburstView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (28/28); localization plist lint and RU/EN key parity; `git diff --check`; repeated Debug `xcodebuild`; repeated `./script/build_and_run.sh --verify`; live Russian/light Home and whole-disk scans; visual radial-map and large-file review; nil initial row selection/action-state check; no-exclusion `/` scan through system/application/user/developer paths.
- Result: Passed. The live whole-disk scan visited 1,316,113 accessible objects, measured 68.73 GB, found 124 files over 50 MB, and showed Applications, System, Users, Library, var, opt, usr, tmp, and bin branches. It reported 457 macOS-protected locations instead of escalating privileges. No file was selected automatically and no cleanup or mutation occurred.
- Next step: Add launch-at-login support or deeper developer-storage previews.
- Bottleneck: a truly complete physical-volume total is limited by macOS access controls and APFS/mounted representations; the analyzer reports what the current process can read and explains why Finder may differ.
- Handoff: Whole-disk mode deliberately has no path exclusion list per user direction. It can be slower and can include mounted paths. The known stale CoreSimulator warning remains non-blocking for macOS builds.

## 2026-07-12 - TASK-035 - Disk analysis interaction polish

- What changed: Replaced the standard scan spinner with a custom gradient ring/pulse indicator and added efficient radial-map hover hit-testing. The hovered sector now grows with a short animation, glow, and localized floating tooltip containing its folder name and binary-gigabyte size; Reduce Motion disables continuous movement.
- Files touched: `CleanMac/Views/DiskAnalysisProgressIndicator.swift`, `CleanMac/Views/DiskAnalysisView.swift`, `CleanMac/Views/DiskSunburstView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (28/28); localization plist lint and RU/EN key parity; `git diff --check`; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; live Russian/light whole-disk progress review; live map hover review showing `.cache` at `1.510 ГБ`; cancellation smoke check.
- Result: Passed. The modern indicator renders during a live `/` scan, the hovered sector enlarges and displays its GB tooltip, and cancellation returns without modifying files.
- Next step: Decide whether to add launch-at-login support or a rectangular treemap alternative.
- Bottleneck: none. macOS access controls still limit unreadable protected paths, and the stale CoreSimulator warning remains non-blocking for macOS builds.
- Handoff: The verification scan was cancelled through the UI after the indicator check. No cleanup, application removal, restore, or file mutation was triggered.

## 2026-07-12 - TASK-036 - First-launch system onboarding

- What changed: Added a four-step first-launch flow inside the primary CleanMac window: Welcome, real product capabilities, optional Full Disk Access guidance with live read-only status, and completion. The screen uses semantic macOS colors/materials and the system appearance rather than the saved in-app theme, supports Back/Next/Skip, Return as the default action, Reduce Motion, RU/EN localization, and persists completion through `CleanMac.onboardingCompleted`.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Views/OnboardingView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (28/28); localization plist lint and RU/EN key parity; `git diff --check`; Debug `xcodebuild`; repeated `./script/build_and_run.sh --verify`; live Russian/light review of all four pages; Back and top-right Skip checks; completion-to-Dashboard check; completed relaunch check.
- Result: Passed. Onboarding is the only primary-window content before completion, all four pages fit the standard window, permission settings are explicit-only, both finishing and skipping store completion, and the next launch opens Dashboard directly.
- Next step: Decide whether Settings should expose a "Show onboarding again" action.
- Bottleneck: none. The known generated-app FinderInfo attribute required the already documented build-product cleanup before the successful verification rerun; the stale CoreSimulator warning remains non-blocking.
- Handoff: The completion flag was deleted after verification so the new onboarding is visible on the user's next launch. No System Settings button, scan, cleanup, app removal, or restore action was triggered.

## 2026-07-12 - TASK-036 - Release artifact refresh

- What changed: Rebuilt `Documents/CleanMac/dist/CleanMac.app` from commit `53e68ff`, created the matching unsigned ZIP and SHA-256 file, and hardened the packaging script by sanitizing File Provider metadata between its nested and outer signing passes.
- Files touched: `script/package_release.sh`, `progress.md`, `trace.md`.
- Checks run: `./script/package_release.sh`; fresh-ZIP strict codesign verification; local app strict codesign verification after removing FinderInfo; `shasum -a 256 -c dist/CleanMac-53e68ff-unsigned.zip.sha256`.
- Result: Passed. The current Release executable was produced on 2026-07-12 12:27:17, the ZIP checksum is `5062e433beb9eca85aa73a85d15fd7b08008e9981ed594da50f6a14d50b71ac3`, and both the local app and fresh ZIP extraction satisfy their designated requirements.
- Next step: Push the feature branch and open the protected-main pull request.
- Bottleneck: no Developer ID identity is installed, so the artifact remains ad-hoc signed and not notarized.
- Handoff: The separate `/Users/admin/Desktop/CleanMac` project copy remains untouched and still contains version 1.0 (1) artifacts.

## 2026-07-12 - TASK-037 - Live system dashboard menu bar

- What changed: Rebuilt the menu-bar popover as a compact 2x2 live dashboard based on the supplied layout. CPU, memory, disk, battery, network rates, and uptime update locally only while the popover is visible; the existing scan state and last-scan summary remain available. The final styling uses adaptive macOS materials, semantic text colors, and the CleanMac accent, and explicitly injects the selected CleanMac light/dark scheme because `MenuBarExtra` ignored `preferredColorScheme` in the live app.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/StatusSystemMetrics.swift`, `CleanMac/Views/StatusMenuView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (28/28); localization plist lint and RU/EN key parity; `git diff --check`; Debug `xcodebuild`; repeated `./script/build_and_run.sh --verify`; live Russian light/dark popover review with screenshots `/tmp/cleanmac-task37-menu-light-final.png` and `/tmp/cleanmac-task37-menu-dark-fixed.png`.
- Result: Passed. The live light setting renders a light system popover, the dark setting renders a dark popover matching the main window, gauges and values update without background persistence, battery degrades safely when unavailable, and no cleanup or scan was triggered.
- Next step: Decide whether to expose a compact menu-bar refresh interval setting; the current one-second visible-only interval is intentionally fixed and lightweight.
- Bottleneck: none. The known stale CoreSimulator warning remains non-blocking, and the generated app FinderInfo attribute required the documented build-product cleanup before the successful launch verification rerun.
- Handoff: The user's original `light` appearance preference was restored after the dark-theme review. CleanMac remains running from the current Debug product.

## 2026-07-12 - TASK-038 - Settings permissions and launch at login

- What changed: Removed Permissions from the sidebar and embedded its complete Full Disk Access, Files/Folders, and Finder Automation status/actions in Settings. Added a `LaunchAtLoginManager` backed by `SMAppService.mainApp`, with off-main register/unregister calls, live enabled/not-registered/approval-required/not-found status, progress feedback, localized failure details, and a Login Items System Settings action. Reworked initial window presentation so login/background launch keeps the window hidden without a flash, while app activation, Dock/Finder reopen, and menu-bar Open reveal the same existing window.
- Files touched: `CleanMac/CleanMacApp.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/LaunchAtLoginManager.swift`, `CleanMac/Support/MainWindowController.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/PermissionsView.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `script/package_release.sh`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (28/28); localization plist lint and RU/EN key parity; `git diff --check`; repeated Debug `xcodebuild`; `./script/build_and_run.sh --verify`; live Russian Settings accessibility and screenshot review; read-only `.notFound` Login Item status; normal/background/activation/menu-bar Open lifecycle checks; `bash -n script/package_release.sh`; `./script/package_release.sh`; fresh-ZIP strict codesign verification and SHA-256 check.
- Result: Passed. Sidebar contains five product sections plus Settings and no Permissions row; all permission controls render in Settings. A background `open -g` launch produced zero main windows, activation produced one main window, and menu-bar Open restored the window from the background process. The Login Item itself was not enabled or disabled during verification. `dist/CleanMac.app` and `CleanMac-13fc508-unsigned.zip` now contain this task's build.
- Next step: Install the packaged app in `/Applications` and let the user explicitly enable the toggle to confirm the real `.enabled` or `.requiresApproval` path.
- Bottleneck: the Debug copy under `Documents` correctly reports `.notFound`; macOS Login Item registration should be exercised from an installed app bundle, and public distribution remains ad-hoc signed until Developer ID credentials exist.
- Handoff: No Login Item, privacy permission, scan, cleanup, application removal, or notification setting was changed. CleanMac is running from the current Debug product.

## 2026-07-12 - TASK-039 - Advanced developer cleanup

- What changed: Added precise cleanup categories for Homebrew, pip, Cargo registry cache/source, Gradle, Cursor and VS Code cache folders, Codex and Claude cache/temp folders, Xcode DeviceSupport, Xcode Previews, old user Simulator devices/runtimes, and individual `.xcarchive` bundles. Simulator candidates must be unchanged for 180 days. DeviceSupport, Simulator, and Archives require review; Archives are never selected by default. The planner accepts only individual archives and direct Xcode/Simulator children, while exact forbidden-path tests protect IDE settings/extensions and AI projects/sessions/history/shell snapshots/memory.
- Files touched: `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPathPolicy.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupPlanner.swift`, `CleanMacCore/Sources/CleanMacCore/CleanupScanner.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `verification.md`.
- Checks run: `swift test --package-path CleanMacCore` (32/32); localization plist lint and RU/EN key parity; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; `pgrep -x CleanMac`; live Russian Scan accessibility review; `git diff --check`.
- Result: Passed. All new rows fit the live Scan screen. Existing saved area choices stayed unchanged; every new review category was off, and Xcode Archives visibly states “Требует проверки”. No forbidden user-data path appeared in scanner roots or plans.
- Next step: If system-managed Simulator runtimes must be handled later, add read-only Xcode runtime discovery and an explicit Xcode-supported removal workflow instead of Trash-based `/Library` deletion.
- Bottleneck: modern system-managed Simulator runtimes live outside the user's home and cannot be safely handled by the current unprivileged Trash executor. The known stale CoreSimulator framework warning remains non-blocking for macOS builds.
- Handoff: No real scan, cleanup, archive move, Simulator change, or preference reset occurred. CleanMac remains running from the current Debug product on the Scan screen.

## 2026-07-12 - TASK-040 - Safe duplicate finder

- What changed: Added a separate Duplicate Finder for Home, Downloads, and a user-selected folder. The core pipeline groups by logical size, hashes only the first 128 KiB, streams full SHA-256 only for surviving candidates, removes hard links by device/inode, limits hashes to two concurrent tasks by default, and supports an explicit slow mode for matching-size files over 500 MiB instead of hiding them. Every result group has one locked deterministic original and unselected copies. Cleanup requires a dedicated confirmation, revalidates scanned metadata and root containment, and moves only selected copies to macOS Trash.
- Files touched: `CleanMacCore/Sources/CleanMacCore/DuplicateFinder.swift`, `CleanMacCore/Sources/CleanMacCore/DuplicateCleanup.swift`, `CleanMacCore/Tests/CleanMacCoreTests/DuplicateFinderTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/DuplicateWorkspaceService.swift`, `CleanMac/Views/DuplicateFinderView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `project-analysis.md`, `roadmap.md`, `contract.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: focused duplicate tests and full `swift test --package-path CleanMacCore` (40/40); localization plist lint and RU/EN key parity; `git diff --check`; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; `pgrep -x CleanMac`; live Russian initial-screen accessibility and visual review.
- Result: Passed. No file is automatically selected; originals have no checkbox; large matching-size candidates are shown for opt-in slow hashing; duplicate data stays out of junk totals, normal Results, cleanup history, and scheduled scans. No real folder scan or cleanup was performed during UI verification.
- Next step: Exercise the result and confirmation layout on a user-approved disposable folder, then cut a release only when requested.
- Bottleneck: Full hashing of very large files is intentionally slow and remains an explicit opt-in; hidden files and package contents stay outside this stage.
- Handoff: The current Debug app is running on the Russian Duplicate Finder initial screen. No user file was scanned or moved, and no destructive confirmation was accepted.

## 2026-07-12 - TASK-041 - CleanMac v0.3.0 release

- What changed: Bumped CleanMac to 0.3.0 build 4, updated the feature PR title and English summary, waited for green CI, merged PR #9 into `main`, rebuilt `dist/CleanMac.app` and the arm64 ad-hoc ZIP from merge commit `515f591`, published `v0.3.0` with English notes, and fixed checksum generation so downloaded `.sha256` files contain a portable ZIP basename rather than a developer-machine path.
- Files touched: `CleanMac.xcodeproj/project.pbxproj`, `script/package_release.sh`, generated ignored `dist/CleanMac.app`, `dist/CleanMac-515f591-unsigned.zip`, `dist/CleanMac-515f591-unsigned.zip.sha256`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`, GitHub PR #9, and GitHub Release `v0.3.0`.
- Checks run: `swift test --package-path CleanMacCore` (40/40); `./script/build_and_run.sh --verify`; Debug version/build/arm64/signature inspection; green GitHub PR CI; `./script/package_release.sh`; local and fresh-extraction strict codesign verification; local and clean downloaded SHA-256 verification; downloaded release bundle version/build/architecture inspection; GitHub release metadata inspection.
- Result: Passed. PR #9 is merged. `v0.3.0` is public, latest, non-prerelease, targets `515f591`, and contains `CleanMac-515f591-unsigned.zip` plus its portable checksum. The ZIP SHA-256 is `cd5d94601d3a5e5bb5e8681f71ccf2decb216638ec83159cd6aca3d65c0a0cbf`; the extracted app reports 0.3.0 (4), arm64, and a valid strict ad-hoc signature.
- Next step: Install the packaged app in `/Applications`; Developer ID signing and Apple notarization remain the next distribution upgrade when credentials are available.
- Bottleneck: This Mac has no Developer ID identity, so Gatekeeper can reject the downloaded ad-hoc build even though its integrity and signature are valid.
- Handoff: `dist/` contains the current 0.3.0 app and verified release assets. No security setting, Login Item, privacy permission, cleanup selection, application, or user file was changed.

## 2026-07-12 - TASK-042 - Idempotent GitHub Release publishing

- What changed: Replaced the unconditional `gh release create` step with an idempotent publish step. Missing tag releases keep the existing creation behavior; existing releases preserve their title/notes and replace matching ZIP/checksum assets through `gh release upload --clobber`.
- Files touched: `.github/workflows/release.yml`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`.
- Checks run: GitHub failure-log inspection; Ruby YAML parse; extracted publish-step `bash -n`; stubbed missing-release branch; exact existing-release branch against `v0.3.0`; clean downloaded `shasum -a 256 -c`; release metadata/asset inspection; `git diff --check`; GitHub PR CI.
- Result: Passed. The original red run was a duplicate-publication error after a successful package, not an app build failure. `v0.3.0` remains public/latest with its English notes and exactly the verified ZIP and portable checksum assets.
- Next step: Use the normal tag workflow for the next version; no manual pre-creation is required, but the workflow now safely tolerates it.
- Bottleneck: The historical `v0.3.0` failure cannot be turned green without rewriting the tag because GitHub reruns the workflow definition stored at that tagged commit.
- Handoff: No release tag, note, app binary, security setting, secret, or user file was changed; only same-named verified release assets were refreshed.

## 2026-07-12 - TASK-043 - Fix custom-folder source selection

- What changed: Replaced direct Picker state binding with an intercepting Binding in Disk Analysis and Duplicate Finder. Selecting Custom Folder now schedules the native folder panel after the current SwiftUI update, prevents duplicate panel requests, leaves the previous source selected on cancel, and activates Custom Folder only after a real selection. Source controls remain disabled only while scanning, cleaning, or the panel is open.
- Files touched: `CleanMac/Views/DiskAnalysisView.swift`, `CleanMac/Views/DuplicateFinderView.swift`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`.
- Checks run: Debug `xcodebuild`; `./script/build_and_run.sh --verify`; live Russian accessibility interaction in both sections; Duplicate Finder cancel path; `/Users/admin/Documents` selection in both sections without starting scans; `swift test --package-path CleanMacCore`; `git diff --check`.
- Result: Passed. Both Custom Folder segments open the native panel, the selected path appears with the segment active, and neither analysis nor duplicate scanning starts automatically.
- Next step: Package a 0.3.1 bug-fix release only when explicitly requested.
- Bottleneck: none; the known CoreSimulator warning remains unrelated and non-blocking for macOS builds.
- Handoff: CleanMac is running from the current Debug product on Duplicate Finder with `/Users/admin/Documents` selected. No cleanup, duplicate move, or scan was triggered.

## 2026-07-12 - TASK-044 - Low disk space warning

- What changed: Added a shared low-space policy with a strict under-10% threshold and a 24-hour notification cooldown. CleanMac now checks capacity at launch and every 30 minutes, sends a localized warning only when macOS notifications are already authorized, and records the cooldown only after successful delivery. The menu-bar popover shows an adaptive warning card with remaining space, a scan recommendation, and a direct Disk Analysis action that reveals or opens the main window without starting analysis.
- Files touched: `CleanMacCore/Sources/CleanMacCore/LowDiskSpaceWarningPolicy.swift`, `CleanMacCore/Tests/CleanMacCoreTests/LowDiskSpaceWarningPolicyTests.swift`, `CleanMac/CleanMacApp.swift`, `CleanMac/Support/CleanMacLowDiskSpaceMonitor.swift`, `CleanMac/Support/CleanMacNotificationService.swift`, `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Support/MainWindowController.swift`, `CleanMac/Support/StatusSystemMetrics.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/StatusMenuView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: focused `LowDiskSpaceWarningPolicyTests` (3/3); full `swift test --package-path CleanMacCore` (43/43); localization plist lint and RU/EN key parity; `git diff --check`; `./script/build_and_run.sh --verify`; live one-shot route check to the Russian Disk Analysis screen; normal-capacity hidden-state check; GitHub PR core-test and macOS-build CI.
- Result: Passed. Exactly 10% does not warn, below 10% does; notifications are limited to one successful delivery per 24 hours; the action opens Disk Analysis without selecting files or starting a scan. No notification permission was changed and no real warning was sent during verification.
- Next step: Publish a feature release only when explicitly requested.
- Bottleneck: system notification delivery remains dependent on macOS permission; the known CoreSimulator version warning remains unrelated and non-blocking for macOS builds.
- Handoff: The current Debug app uses the normal live disk capacity, so the warning remains naturally hidden. No scan, cleanup, application removal, release, or user-file mutation occurred.

## 2026-07-12 - TASK-045 - Reduce scan thermal load

- What changed: Replaced the two continuous 30 FPS `TimelineView` progress animations with event-driven progress visuals and system `ProgressView`; bounded cleanup, Disk Analysis, and Duplicate Finder progress streams to the newest pending event; and moved the long read-only Disk Analysis and duplicate workers from user-initiated to utility priority.
- Files touched: `CleanMac/Views/DiskAnalysisProgressIndicator.swift`, `CleanMac/Views/DiskAnalysisView.swift`, `CleanMac/Views/DuplicateFinderView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ScanActivityView.swift`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `verification.md`.
- Checks run: repeated live `ps` CPU sampling; 8-second before/after `/usr/bin/sample` captures during Home Disk Analysis; `swift test --package-path CleanMacCore` (43/43); localization plist lint; Debug `xcodebuild`; `./script/build_and_run.sh --verify`; `git diff --check`; source check confirming no scan-progress `TimelineView` remains.
- Result: Passed. The reproduced baseline stayed at 111–124% CleanMac CPU. The optimized build measured 28.6% on startup, 1.5% on the next sample, and 0% on the following eight samples while the analysis remained active. The baseline sample spent 1,469 samples in repeated window constraint updates; the optimized sample removed that cycle and showed the scan worker on `com.apple.root.utility-qos.cooperative`.
- Next step: Repeat the same benchmark on an uncached whole-disk scan after normal use if a longer thermal comparison is desired; no additional code change is currently required.
- Bottleneck: none. The known stale CoreSimulator warning remains non-blocking for macOS builds.
- Handoff: Only read-only Home Disk Analysis was started and cancelled during verification. No cleanup, duplicate removal, application removal, permission, setting, release, or user file was changed.

## 2026-07-12 - TASK-046 - Smart irreversible file shredder

- What changed: Added a separate Smart Shredder sidebar destination with adaptive neo-glow styling, explicit multi-file selection, file-system/APFS status, fail-closed review, and a two-part irreversible confirmation. The core accepts only unchanged single-link regular files, pins and locks the descriptor without following symlinks, performs one random overwrite pass with sync, truncates and syncs, revalidates device/inode identity, and directly unlinks without Trash, CleanMac history, restore, scheduling, or cancellation after execution begins. Protected system roots and their `/etc`/`/var` aliases, package contents, directories, symlinks, hard links, and changed/replaced files are rejected. The UI explicitly documents the SSD/APFS limitation and recommends FileVault.
- Files touched: `CleanMacCore/Sources/CleanMacCore/SecureFileShredder.swift`, `CleanMacCore/Tests/CleanMacCoreTests/SecureFileShredderTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/ShredderWorkspaceService.swift`, `CleanMac/Views/ShredderView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `README.md`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: focused `SecureFileShredderTests` (4/4); full `swift test --package-path CleanMacCore` (47/47); localization plist lint and EN/RU parity (583 keys); Debug `xcodebuild`; `./script/build_and_run.sh --verify`; live EN/light empty-state and RU/dark queued/armed confirmation review; confirmation button disabled/enabled gating check; `git diff --check`; disposable UI fixture preservation check.
- Result: Passed. Destructive behavior was exercised only against disposable SwiftPM fixtures. The UI confirmation was never accepted, and the selected UI fixture remains preserved outside the repository. Standard cleanup and restore paths remain unchanged.
- Next step: Commit and push the feature only when explicitly requested; package or publish a release separately when approved.
- Bottleneck: physical-media erasure cannot be guaranteed on SSD/APFS; the known stale CoreSimulator warning remains non-blocking for macOS builds.
- Handoff: The current Debug app builds, signs, and launches. CleanMac preferences were restored to English/light after RU/dark review. No real user file, setting, permission, package, release, or remote repository state was changed.

## 2026-07-13 - TASK-047 - CleanMac v0.4.0 release

- What changed: Merged the thermal optimization and Smart Shredder in PR #14, bumped the app from `0.3.0 (4)` to `0.4.0 (5)` in PR #15, refreshed the Dashboard/Scan/Applications screenshots, added a dark Smart Shredder screenshot and README coverage, tagged verified `main` as `v0.4.0`, and published accurate feature, safety, checksum, architecture, signing, and notarization notes.
- Files touched: `CleanMac.xcodeproj/project.pbxproj`, `README.md`, `docs/screenshots/overview.png`, `docs/screenshots/scan-areas.png`, `docs/screenshots/applications-multiselect.png`, `docs/screenshots/shredder.png`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`.
- Checks run: PR #14 core/macOS CI; PR #15 core/macOS CI; `swift test --package-path CleanMacCore` (47/47); `./script/build_and_run.sh --verify`; `./script/package_release.sh`; local and downloaded SHA-256 verification; clean ZIP extraction; `CFBundleShortVersionString`/`CFBundleVersion`; `lipo -archs`; strict `codesign`; Release workflow run `29220077936`; live English/light and English/dark screenshot review without starting a scan or accepting any removal action; `git diff --check`.
- Result: Passed. GitHub Release `v0.4.0` is published as latest with `CleanMac-125e528-unsigned.zip` and its `.sha256`; a clean download reports version `0.4.0`, build `5`, `arm64`, matching checksum, and a valid strict ad-hoc signature.
- Next step: Configure Developer ID and notarization secrets before a future trusted-distribution release.
- Bottleneck: the release remains ad-hoc signed and not notarized because no Developer ID certificate/notary credentials are configured; Gatekeeper may reject it. The known stale CoreSimulator warning remains unrelated and non-blocking for macOS builds.
- Handoff: Tag `v0.4.0` points to `125e528`. Release assets and verification copies are preserved under the task diagnostics folder. No user file was deleted and no destructive Shredder action was accepted.

## 2026-07-13 - TASK-048 - Application removal modes

- What changed: Added a two-mode Applications uninstaller. Trash mode remains the default and moves selected apps plus chosen leftovers to Trash. Permanent mode is an explicit segmented choice that auto-includes every shown exact bundle-ID leftover and directly deletes without Trash or CleanMac restore history. Exact leftover discovery now covers cache, preferences, saved state, logs, Application Support, Containers, Group Containers, HTTPStorages, WebKit, cookies, Application Scripts, and LaunchAgents. The Debug run script now retries signing verification if local Finder/File Provider metadata is reattached.
- Files touched: `CleanMacCore/Sources/CleanMacCore/ApplicationUninstaller.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `CleanMac/Views/ApplicationsView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `script/build_and_run.sh`, `README.md`, `contract.md`, `project-analysis.md`, `roadmap.md`, `trace.md`, `verification.md`, `progress.md`.
- Checks run: `swift test --package-path CleanMacCore` (48/48); `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; RU/EN localization key parity; Debug `xcodebuild`; `./script/build_and_run.sh --verify` after metadata-race hardening; `git diff --check`.
- Result: Passed. Disposable app-removal fixtures prove the default Trash path and the permanent delete path, and prove the app is removed before any leftovers. The live Debug app builds, signs, launches, and is running.
- Next step: Review the Applications screen visually and decide whether permanent mode needs a typed phrase like Smart Shredder before it can execute.
- Bottleneck: direct deletion is intentionally irreversible and unprivileged; root-owned apps may still fail without administrator privileges, and CleanMac does not escalate.
- Handoff: No real installed app or user leftover was removed. Permanent deletion was exercised only inside temporary SwiftPM fixtures.

## 2026-07-13 - TASK-049 - Shredder icon polish

- What changed: Replaced the Shredder section icon from the terminal symbol to the system `scissors` symbol and reused that same section icon in the Shredder header mark so the feature reads as a shredding tool instead of a console.
- Files touched: `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/ShredderView.swift`, `contract.md`, `roadmap.md`, `progress.md`.
- Checks run: `swift test --package-path CleanMacCore` (48/48); `./script/build_and_run.sh --verify`; `git diff --check`.
- Result: Passed. The Debug app builds, signs after the existing metadata retry, and launches.
- Next step: Visually review the Shredder sidebar row in the running app and decide whether a custom sidebar-only asset is needed later.
- Bottleneck: none. The known CoreSimulator warning and FinderInfo retry remain non-blocking for this macOS Debug build.
- Handoff: UI-only change. No scan, cleanup, app removal, Shredder confirmation, package, release, or remote repository state was changed.

## 2026-07-13 - TASK-050 - System maintenance actions

- What changed: Added a new System sidebar workspace with two explicit maintenance actions: Free Memory runs only `/usr/sbin/purge`, and Flush DNS runs `/usr/bin/dscacheutil -flushcache` followed by `/usr/bin/killall -HUP mDNSResponder`. Commands are launched through `Process` with fixed absolute paths, no shell, no sudo, no scheduling, and visible running/success/partial/failure/unavailable states.
- Files touched: `CleanMac/Support/SystemMaintenanceService.swift`, `CleanMac/Views/SystemMaintenanceView.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `README.md`, `contract.md`, `project-analysis.md`, `roadmap.md`, `verification.md`, `progress.md`.
- Checks run: command existence checks for `/usr/sbin/purge`, `/usr/bin/dscacheutil`, and `/usr/bin/killall`; `swift test --package-path CleanMacCore` (48/48); localization plist lint and RU/EN key parity; repeated `./script/build_and_run.sh --verify`; `git diff --check`.
- Result: Passed. The Debug app builds, signs, launches, and includes the new System section.
- Next step: Visually review the System screen and decide whether RAM/DNS actions should also appear in the menu-bar popover.
- Bottleneck: DNS refresh can partially fail if macOS denies signalling `mDNSResponder`; CleanMac reports that state and does not elevate privileges.
- Handoff: The RAM and DNS maintenance buttons were not clicked during verification, so no memory purge or DNS cache flush was executed. No scan, cleanup, app removal, Shredder confirmation, package, release, or remote repository state was changed.

## 2026-07-13 - TASK-051 - Administrator-backed system maintenance

- What changed: Changed System maintenance actions from normal user `Process` execution to fixed macOS administrator-authorized scripts. Free Memory now asks macOS for authorization and runs only `/usr/sbin/purge`; Flush DNS asks macOS for authorization and runs `/usr/bin/dscacheutil -flushcache` plus `/usr/bin/killall -HUP mDNSResponder`. The UI warns about the admin prompt and marks results as authorized by macOS.
- Files touched: `CleanMac/Support/SystemMaintenanceService.swift`, `CleanMac/Views/SystemMaintenanceView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `README.md`, `contract.md`, `project-analysis.md`, `roadmap.md`, `verification.md`, `progress.md`.
- Checks run: command existence checks for `/usr/sbin/purge`, `/usr/bin/dscacheutil`, `/usr/bin/killall`, and `/usr/bin/osascript`; `swift test --package-path CleanMacCore` (48/48); localization plist lint and RU/EN key parity; `./script/build_and_run.sh --verify`; `git diff --check`.
- Result: Passed. The Debug app builds, signs, launches, and the System actions are wired to macOS administrator authorization instead of failing as an unprivileged process.
- Next step: Manually click Free Memory in the app and confirm the macOS password prompt appears, then verify it reports success.
- Bottleneck: Actual RAM/DNS execution was not performed during automated verification to avoid changing system state without an explicit user click. If the user cancels the macOS administrator prompt, CleanMac reports a failure.
- Handoff: No RAM purge or DNS cache flush was executed by Codex. No scan, cleanup, app removal, Shredder confirmation, package, release, or remote repository state was changed.

## 2026-07-13 - TASK-052 - Visible memory cleanup result

- What changed: Added a shared read-only `StatusMemorySnapshot` so the menu bar and System screen use the same VM memory calculation. The Free Memory card now shows a live circular memory gauge before action, records memory before and after `/usr/sbin/purge`, and labels the result as freed, no visible drop, or memory rose again.
- Files touched: `CleanMac/Support/StatusSystemMetrics.swift`, `CleanMac/Support/SystemMaintenanceService.swift`, `CleanMac/Views/SystemMaintenanceView.swift`, `CleanMac/en.lproj/Localizable.strings`, `CleanMac/ru.lproj/Localizable.strings`, `README.md`, `contract.md`, `project-analysis.md`, `roadmap.md`, `verification.md`, `progress.md`.
- Checks run: Debug `xcodebuild`; `swift test --package-path CleanMacCore` (48/48); localization plist lint and RU/EN key parity; `./script/build_and_run.sh --verify`; `pgrep -fl CleanMac`; safe System window list check; `git diff --check`.
- Result: Passed. The Debug app builds, signs, launches, and the System window opens with the new memory result UI compiled in.
- Next step: Click Free Memory manually and confirm the UI shows a before/after percentage plus the freed/no-change/rose-again label after the macOS administrator prompt.
- Bottleneck: Automated verification did not click Free Memory, so it did not produce a real before/after purge result. macOS can refill RAM quickly, so a successful command may still show no visible drop or a small increase.
- Handoff: No RAM purge or DNS cache flush was executed by Codex. No scan, cleanup, app removal, Shredder confirmation, package, release, or remote repository state was changed.

## 2026-07-13 - TASK-053 - Modern scan progress and drag-to-Applications DMG

- What changed: Replaced the gray scan-only system spinners with a shared orbit-style SwiftUI indicator across standard cleanup scanning, Disk Analysis, Duplicate Finder, and Applications scanning. Restored rotating arcs, soft pulse, shimmer, and signal motion through small state-driven animations with Reduce Motion support and no `TimelineView`. Release packaging now creates `dist/CleanMac.dmg` beside `dist/CleanMac.app`; the image contains `CleanMac.app` and an `Applications -> /Applications` shortcut, while CI and tag Release workflows publish the DMG alongside the fallback ZIP and checksums.
- Files touched: `CleanMac/Views/DiskAnalysisProgressIndicator.swift`, `CleanMac/Views/ScanActivityView.swift`, `CleanMac/Views/DiskAnalysisView.swift`, `CleanMac/Views/DuplicateFinderView.swift`, `CleanMac/Views/ApplicationsView.swift`, `script/package_release.sh`, `.github/workflows/ci.yml`, `.github/workflows/release.yml`, `README.md`, `docs/signing-notarization.md`, `contract.md`, `project-analysis.md`, `roadmap.md`, `progress.md`, `trace.md`, `verification.md`.
- Checks run: Debug `xcodebuild`; `bash -n script/package_release.sh`; full `swift test --package-path CleanMacCore` (48/48); localization plist lint and RU/EN key parity; `./script/build_and_run.sh --verify`; two `./script/package_release.sh` passes while hardening DMG staging; `hdiutil verify`; read-only DMG mount with shortcut and strict app signature inspection; `zsh -lc 'cd dist && shasum -a 256 -c *.sha256'`; source check confirming no scan-progress `TimelineView`; live standard scan and cancellable Home Disk Analysis review; six CPU samples; `git diff --check`.
- Result: Passed. The live standard scan showed the modern 70% orbital/progress surface, Disk Analysis showed the compact modern indicator, and the test analysis was cancelled with the app confirming that files were unchanged. The DMG and ZIP checksums pass, and the app inside the mounted DMG satisfies strict ad-hoc signature verification.
- Next step: Push only after resolving the repository visibility choice, then let CI validate the DMG artifact on GitHub.
- Bottleneck: `Dezoff-max/CleanMac` currently reports `PUBLIC`, which conflicts with the earlier private-repository requirement. This Mac still has no Developer ID identity, so the local DMG is ad-hoc signed and not notarized.

## 2026-07-13 - TASK-054 - Safe stale Codex runtime review and native Applications icon

- What changed: Added a narrowly scoped standard-scan category for exact direct `~/.cache/codex-runtimes/codex-runtime-install-[A-Za-z0-9]+` directories older than seven days. The scanner excludes the active `codex-primary-runtime`, recent installers, malformed names, nested paths, and symlinks; measures package contents with a category-specific descendant cap; and marks every result for review. Results start unselected, remain locked by Safe Mode, explain the protected active runtime, require a dedicated final confirmation, and move only planner-revalidated paths to Trash. Existing nonempty scan selections receive the category once through a schema migration. The Applications sidebar row now renders the installed system App Store Retina icon through `NSWorkspace` instead of an unavailable or imitation symbol.
- Files touched: `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`, `CleanupPathPolicy.swift`, `CleanupScanner.swift`, `CleanupPlanner.swift`, `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/Views/SidebarView.swift`, both localization files, and Loop docs.
- Checks: all 50 SwiftPM tests; localization plist lint and RU/EN key parity; real read-only runtime probe; `./script/build_and_run.sh --verify`; selected/unselected live icon review; `./script/package_release.sh`; DMG/ZIP checksum verification; `git diff --check`.
- Result: Passed. The real probe found two old exact installer runtimes totaling 1,772,158,976 bytes and excluded `codex-primary-runtime`; no cleanup ran. The native App Store icon is visible in both sidebar states. Debug and Release packaging passed.
- Next step: Review and merge PR #17, then create a feature release only when requested.
- Bottleneck: public distribution remains ad-hoc signed and not notarized until Developer ID credentials are configured. The known CoreSimulator version warning remains unrelated and non-blocking.
- Handoff: `dist/` contains `CleanMac.app`, `CleanMac.dmg`, `CleanMac.dmg.sha256`, the fallback ZIP, and its checksum. No cleanup, removal, Shredder, RAM purge, DNS flush, permission, or system setting was changed.
