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

## Handoff

- Current state: TASK-002/TASK-003/TASK-006 complete. CleanMac now has a read-only scanner, real results UI, RU/EN localization, and menu Open window reuse.
- Next recommended task: TASK-004 safe cleanup planning with explicit confirmation and strict deletion boundaries.
- Known blockers: local Xcode reports a CoreSimulator warning, but macOS app builds are not blocked.
- Commands that passed: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `./script/package_release.sh`.
- Commands that failed: none for required verification. One deep recursive System Events tree dump was stopped because SwiftUI traversal was too slow; narrower UI checks passed.
- Current bottleneck: cleanup safety design
