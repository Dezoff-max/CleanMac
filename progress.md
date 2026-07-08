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
