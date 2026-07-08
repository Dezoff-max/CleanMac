# Roadmap

- [x] ID: TASK-001
  Title: Main window UI and launch lifecycle
  Goal: Make CleanMac open as a normal windowed app on launch while staying available from the menu bar after the window closes.
  What to do: Replace the placeholder window with a Dashboard/Scan/Results/Permissions/Settings UI shell, use a primary launch window scene, and keep menu bar access.
  Files: `CleanMac/**`, `CleanMacCore/**`, Loop docs
  Definition of done: App opens a main window on normal launch, menu bar extra remains available, closing the window does not terminate the app, and the UI has the five requested sections.
  Verification: `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`
  Priority: high
  Impact: high
  Risk: low
  Effort: medium
  Confidence: high
  Score: high impact / low risk / medium

- [x] ID: TASK-002
  Title: Read-only cleanup scanner
  Goal: Add safe scanning for common cleanup areas without deleting files.
  What to do: Implement scanner models and services for caches, logs, temporary files, Trash, Downloads review, and Xcode derived data.
  Files: `CleanMacCore/**`, `CleanMac/**`
  Definition of done: Scanner returns typed results with paths, sizes, categories, and risk levels; no deletion occurs.
  Verification: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: medium
  Score: high impact / medium risk / medium

- [x] ID: TASK-003
  Title: Scan results review
  Goal: Let the user review and select scanned items before cleanup.
  What to do: Bind real scan results to the Results UI with grouping, selection, size totals, and risk labels.
  Files: `CleanMac/**`, `CleanMacCore/**`
  Definition of done: Results are visible, selectable, grouped by category, and no cleanup can happen without review.
  Verification: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: medium
  Score: high impact / medium risk / medium

- [x] ID: TASK-004
  Title: Safe cleanup planning
  Goal: Prepare cleanup operations with confirmation and rollback-friendly boundaries.
  What to do: Add cleanup plan generation, confirmation UI, Trash-based execution, and safeguards for system/user-critical paths.
  Files: `CleanMac/**`, `CleanMacCore/**`
  Definition of done: Cleanup actions require explicit confirmation, only target allowlisted scan results, and move accepted items to Trash instead of permanently deleting files.
  Verification: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; manual app review
  Priority: high
  Impact: high
  Risk: high
  Effort: large
  Confidence: medium
  Score: high impact / high risk / large

- [ ] ID: TASK-005
  Title: Release tagging
  Goal: Create GitHub Releases automatically from version tags.
  What to do: Add a release workflow for `v*` tags that uploads the unsigned zip and checksum.
  Files: `.github/workflows/**`, `script/**`, docs
  Definition of done: Pushing `v0.1.0` creates a GitHub Release with zip and sha256 assets.
  Verification: `./script/package_release.sh`; tag workflow success; GitHub Release asset check
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-008
  Title: Scan filters and selection presets
  Goal: Make scan area selection faster and clearer.
  What to do: Add filter controls for all/safe/review areas plus actions to select safe areas, select review-only areas, and clear selection.
  Files: `CleanMac/Views/ScanView.swift`, `CleanMac/*/Localizable.strings`
  Definition of done: Scan screen can filter visible areas and quickly apply safe/review/clear selection presets.
  Verification: `./script/build_and_run.sh --verify`; visual app review
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-006
  Title: Localization and window focus polish
  Goal: Add English/Russian localization and make menu Open focus the existing window before creating a new one.
  What to do: Add localized string resources, route visible UI copy through localization, and add a narrow AppKit window bridge for main-window focus.
  Files: `CleanMac/**`, `CleanMac.xcodeproj/project.pbxproj`, Loop docs
  Definition of done: Russian and English resources exist, UI uses localized strings, system language chooses localization by default, and Open reuses/focuses an existing main window.
  Verification: `./script/build_and_run.sh --verify`; app bundle contains `en.lproj` and `ru.lproj`; manual/System Events window count check
  Priority: high
  Impact: high
  Risk: low
  Effort: medium
  Confidence: high
  Score: high impact / low risk / medium

- [x] ID: TASK-007
  Title: Dashboard scan area discoverability and initial fit
  Goal: Make selected scan areas visible and keep Dashboard blocks visible when the window opens.
  What to do: Show the currently selected scan areas on the Dashboard, add a direct action that opens the Scan section, compact the Dashboard layout, and expand restored windows that are shorter than the intended first-run height.
  Files: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/MainWindowController.swift`, `CleanMac/Views/CleanMacComponents.swift`, `CleanMac/Views/DashboardView.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Dashboard shows selected area names and paths, the user can jump from Dashboard to the Scan screen to change them, and the initial Dashboard shows all main blocks without cutting off the Safety panel.
  Verification: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; visual screenshot check.
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small
