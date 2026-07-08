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

- [ ] ID: TASK-004
  Title: Safe cleanup planning
  Goal: Prepare cleanup operations with confirmation and rollback-friendly boundaries.
  What to do: Add cleanup plan generation, confirmation UI, and safeguards for system/user-critical paths.
  Files: `CleanMac/**`, `CleanMacCore/**`
  Definition of done: Cleanup actions require explicit confirmation and only target approved scan results.
  Verification: `swift test --package-path CleanMacCore`; manual app review
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
  Definition of done: Pushing a version tag creates a GitHub Release with zip and sha256 assets.
  Verification: workflow dry review, optional test tag after approval
  Priority: medium
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
