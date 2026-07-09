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
- Checks run: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; defaults-based scheduled scan smoke test (`source=scheduled`, `runKey=2026-07-09-15-13`, `scanInProgress=0`); visual screenshot `/tmp/cleanmac-autoscan-notifications-settings-2.png`; `./script/package_release.sh`; `shasum -a 256 -c dist/CleanMac-2f6c16d-unsigned.zip.sha256`; zip extraction followed by `codesign --verify --deep --strict --verbose=2`; local `dist/CleanMac.app` strict code-sign validation after clearing FinderInfo added by Finder.
- Result: Passed. Scheduled scans can notify with item count and size when the toggle and macOS permission allow it; manual scans remain silent; the fresh local unsigned/ad-hoc package is `dist/CleanMac-2f6c16d-unsigned.zip`.
- Next step: Add launch-at-login support or create a new GitHub Release tag for this package.
- Bottleneck: Apple Developer signing identity for trusted distribution.
- Handoff: Notification permission was not forced during smoke testing; the app requests it only when auto scan and notification settings are enabled. Xcode still emits the known CoreSimulator warning, but macOS builds complete.
