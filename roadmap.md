# Roadmap

- [x] ID: TASK-034
  Title: Persistent cleanup history
  Goal: Preserve Trash-based cleanup history across app launches without trusting stored paths blindly.
  What to do: Add a versioned atomic local history store, stable per-operation IDs, a 100-record cap, and restore-time validation for both the original allowlisted location and the current user's Trash.
  Files: `CleanMacCore/Sources/CleanMacCore/CleanupHistoryStore.swift`, cleanup restore models/service, core tests, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, localization, Loop docs
  Definition of done: Successful cleanup records survive relaunch; restored/failed statuses persist; corrupt or forged history cannot crash the app or move files outside the allowed roots; repeated cleanup of one path has unique history IDs.
  Verification: `swift test --package-path CleanMacCore`; localization lint; `./script/build_and_run.sh --verify`; non-destructive UI review
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: high
  Score: high impact / medium risk / medium

- [x] ID: TASK-033
  Title: Custom About window and v0.2.1 release
  Goal: Replace the default About panel with a polished localized CleanMac window, then publish the verified v0.2.1 build.
  What to do: Add a singleton SwiftUI About scene, live bundle version/build data, project links, RU/EN copy, theme support, and complete the protected PR/release flow.
  Files: `CleanMac/CleanMacApp.swift`, `CleanMac/Views/AboutView.swift`, `CleanMac/*/Localizable.strings`, version settings, Loop docs
  Definition of done: One fixed-size About window opens from the app menu, matches the selected language/theme, shows accurate metadata and working links, and v0.2.1 is released with verified assets.
  Verification: localization lint; `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; `./script/package_release.sh`; visual review; GitHub CI
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-032
  Title: Multi-select application removal
  Goal: Let the user check several applications and remove the reviewed set through one mandatory confirmation.
  What to do: Add native row checkboxes, per-app leftover selections, a batch summary, and sequential use of the existing safe planner/executor.
  Files: `CleanMac/Views/ApplicationsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Multiple checked apps remain selected; per-app leftovers stay isolated; batch confirmation shows counts and size; each app still moves before its leftovers; no real app is removed during verification.
  Verification: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; localization lint; non-destructive UI review
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: high
  Score: high impact / medium risk / medium

- [x] ID: TASK-031
  Title: Safe application uninstaller
  Goal: Let the user review and move a third-party app plus exact bundle-ID leftovers to Trash.
  What to do: Add an isolated app scanner/removal policy in `CleanMacCore`, a separate Applications screen, mandatory confirmation, and temporary-fixture tests.
  Files: `CleanMacCore/**`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ApplicationsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Only direct third-party apps in `/Applications` and `~/Applications` are listed; only exact Caches/Preferences/Saved State/Logs leftovers are optional; the app is moved first; failures cannot delete leftovers; no real app is removed during verification.
  Verification: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`; localization lint; read-only visual review
  Priority: high
  Impact: high
  Risk: high
  Effort: medium
  Confidence: high
  Score: high impact / high risk / medium

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

- [x] ID: TASK-005
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

- [x] ID: TASK-009
  Title: Developer ID signing and notarization readiness
  Goal: Make release packaging able to produce signed/notarized builds when Apple credentials are configured.
  What to do: Add optional signing/notarization support to release packaging, document required secrets, and keep unsigned fallback working when no certificate is present.
  Files: `script/**`, `.github/workflows/**`, `docs/**`, Loop docs
  Definition of done: Local packaging still creates unsigned zip without credentials; package script can sign with a Developer ID identity and submit notarization when configured; docs list required private secrets.
  Verification: `./script/package_release.sh`; `codesign`/`spctl` inspection; `git diff --check`
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: medium
  Score: high impact / medium risk / medium

- [x] ID: TASK-010
  Title: Expanded cleanup scanner categories
  Goal: Check more useful cleanup areas while preserving safe allowlisted cleanup boundaries.
  What to do: Add browser cache, Node/npm cache, old downloads/installers, and SwiftPM build cache categories with localized UI.
  Files: `CleanMacCore/**`, `CleanMac/**`
  Definition of done: New categories appear in Scan and Results, have explicit roots, risk labels, and tests for scanner/allowlist behavior.
  Verification: `swift test --package-path CleanMacCore`; `./script/build_and_run.sh --verify`
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: high
  Score: high impact / medium risk / medium

- [x] ID: TASK-011
  Title: Live Full Disk Access state
  Goal: Replace static permissions copy with real status checks where macOS allows it.
  What to do: Add a Full Disk Access checker that probes protected paths by metadata/readability only, show granted/limited/unknown status, and add refresh/open settings actions.
  Files: `CleanMac/**`, Loop docs
  Definition of done: Permissions screen shows live Full Disk Access status and updates on refresh without reading user data contents.
  Verification: `./script/build_and_run.sh --verify`; manual UI check
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: medium
  Score: medium impact / low risk / small

- [x] ID: TASK-012
  Title: Refresh icon everywhere
  Goal: Replace the current broom icon with the supplied broom/code icon in every app surface.
  What to do: Regenerate AppIcon sizes, MenuBarIcon sizes, and use the asset as the in-app brand icon instead of generic SF Symbols.
  Files: `CleanMac/Assets.xcassets/**`, `CleanMac/Views/**`, Loop docs
  Definition of done: App bundle icon, menu bar icon, and Dashboard/StatusMenu brand icon use the supplied image.
  Verification: `./script/build_and_run.sh --verify`; visual screenshot check
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-013
  Title: Cleaner-style review UX and Trash restore guidance
  Goal: Make Results feel like a complete cleanup review workspace with category groups, risk clarity, item details, and recovery from Trash.
  What to do: Add category summaries, selected item details, safer risk copy, current-session cleanup history, and restore action for moved-to-Trash items.
  Files: `CleanMac/**`, `CleanMacCore/**`, Loop docs
  Definition of done: Results shows grouped cleanup categories, a detail panel for selected items, current-session moved-to-Trash history, and a restore flow that never overwrites existing files.
  Verification: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: medium
  Score: high impact / medium risk / medium

- [x] ID: TASK-014
  Title: Modern scan activity animation
  Goal: Make the active scanning state feel modern, responsive, and clearly alive.
  What to do: Add an animated scan activity component with a radar/pulse treatment, live status phases, selected-area chips, and Reduce Motion support; keep fast scans visible long enough to perceive.
  Files: `CleanMac/Views/**`, `CleanMac/*/Localizable.strings`, `CleanMac/Views/MainWindowView.swift`, Loop docs
  Definition of done: Scan screen shows a polished animated activity surface while scanning, localized in English/Russian, without changing scanner or cleanup safety behavior.
  Verification: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-015
  Title: Real scan progress and smart cleanup rules
  Goal: Make scanning show truthful per-area progress and reduce noisy cleanup candidates.
  What to do: Add scan progress events in `CleanMacCore`, bind them to the animated Scan UI, and make Downloads/logs/temporary-file candidates smarter and safer by default.
  Files: `CleanMacCore/**`, `CleanMac/Views/**`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Scan UI shows percentage, current area, found count, size, and selected-area states from real scanner progress; smart rules skip likely active temporary/log files and recent small downloads; cleanup remains confirmation-gated and Trash-based.
  Verification: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: high
  Score: high impact / medium risk / medium

- [x] ID: TASK-016
  Title: Unified minimal broom icon
  Goal: Replace the detailed broom/code artwork with one minimal broom shape everywhere, including a Retina-readable menu bar template icon.
  What to do: Regenerate AppIcon, BrandIcon, MenuBarIcon, design, and docs assets from the same broom shape; mark MenuBarIcon as template-rendered.
  Files: `CleanMac/Assets.xcassets/**`, `Design/**`, `docs/assets/**`, Loop docs
  Definition of done: Menu bar icon is visible as a system-tinted template silhouette, all app/project icon assets use the same broom shape, and the app builds with the updated asset catalog.
  Verification: `./script/build_and_run.sh --verify`; PNG dimension checks; JSON validation; visual screenshot check
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-017
  Title: Supplied broom icon restore
  Goal: Replace the failed thin minimal icon with the user's supplied detailed broom artwork everywhere, including Dock and menu bar.
  What to do: Regenerate AppIcon, BrandIcon, MenuBarIcon, design, and docs assets from the supplied PNG; remove menu bar template rendering so the color icon is not reduced to a thin monochrome stroke; refresh LaunchServices/Dock registration.
  Files: `CleanMac/Assets.xcassets/**`, `Design/**`, `docs/assets/**`, Loop docs
  Definition of done: Window brand, menu bar, Dock app icon, design assets, and docs asset all use the supplied broom icon; Debug app builds and launches; Dock shows the new icon after cache refresh.
  Verification: PNG dimension checks; asset JSON validation; `./script/build_and_run.sh --verify`; visual screenshot check; LaunchServices/Dock refresh.
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-018
  Title: Main content technology background
  Goal: Add the user's supplied light technology background to the main app window without breaking native macOS split-view layout.
  What to do: Add the background image as an asset, render it behind all page content through the shared page container, and keep the sidebar on native macOS material.
  Files: `CleanMac/Assets.xcassets/**`, `CleanMac/Views/CleanMacComponents.swift`, `CleanMac/Views/MainWindowView.swift`, Loop docs
  Definition of done: Dashboard and Settings pages show the supplied background in the main content area, controls remain readable, and the sidebar does not show detail content underneath.
  Verification: Asset JSON/dimension checks; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`; visual screenshot checks.
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-019
  Title: Sidebar language and appearance controls
  Goal: Let the user switch RU/EN and light/dark directly from the bottom of the sidebar.
  What to do: Add persistent sidebar footer controls, route localization through the selected language bundle, and apply the selected color scheme to the main window and menu bar popover.
  Files: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/Localizer.swift`, `CleanMac/Views/SidebarView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: RU/EN and light/dark controls are visible at the bottom of the sidebar; language defaults from the system when unset; selected language/theme apply to the app UI.
  Verification: `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; `swift test --package-path CleanMacCore`; visual screenshot checks.
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-020
  Title: Result cleanup explanations
  Goal: Make scan results more trustworthy by explaining why each item was suggested.
  What to do: Add structured scan reasons in `CleanMacCore`, cover them with tests, localize reason titles/details, and show compact reasons in rows plus fuller explanations in the detail panel.
  Files: `CleanMacCore/**`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Results list shows a concise reason, the detail panel explains "why suggested", scanner tests cover reason assignment, and cleanup behavior remains unchanged.
  Verification: `swift test --package-path CleanMacCore`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check.
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-021
  Title: Scheduled scan status menu
  Goal: Let CleanMac scan selected areas automatically at a chosen time while keeping current disk and scan status visible in the menu bar.
  What to do: Add persistent scan preferences, a read-only scheduler, Settings controls, menu bar disk/last-scan status, and overlap guards for manual scans.
  Files: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/**`, `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/Views/StatusMenuView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Settings configures auto scan time, scheduled scans store last scan status without cleanup, menu bar shows disk usage and current scan info, and manual/scheduled scans do not overlap.
  Verification: `swift test --package-path CleanMacCore`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; defaults-based scheduled scan smoke test; visual screenshot check.
  Priority: high
  Impact: high
  Risk: medium
  Effort: medium
  Confidence: high
  Score: high impact / medium risk / medium

- [x] ID: TASK-022
  Title: Auto scan frequency options
  Goal: Add useful scan frequency choices so the user can schedule daily, hourly, or every-two-hours read-only scans.
  What to do: Add a persisted frequency preference, render it in Settings, compute interval run slots in the scheduler, and keep menu bar next-run status accurate.
  Files: `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Support/CleanMacAutoScanScheduler.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Settings shows daily/hourly/every-2-hours choices, interval modes run once per due slot, daily remains the default, and menu bar next-run calculation follows the selected frequency.
  Verification: `swift test --package-path CleanMacCore`; `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`; `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`; `git diff --check`; `./script/build_and_run.sh --verify`; defaults-based interval smoke test; visual screenshot check.
  Priority: high
  Impact: medium
  Risk: medium
  Effort: small
  Confidence: high
  Score: medium impact / medium risk / small

- [x] ID: TASK-023
  Title: Auto scan completion notifications and local release package
  Goal: Notify the user when a scheduled read-only scan finishes and provide a fresh local release zip.
  What to do: Add a notification service, Settings toggle, permission-aware scheduling hook, localized notification copy, and package a clean unsigned/ad-hoc Release build.
  Files: `CleanMac/CleanMacApp.swift`, `CleanMac/Support/CleanMacAutoScanScheduler.swift`, `CleanMac/Support/CleanMacNotificationService.swift`, `CleanMac/Support/CleanMacPreferences.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/*/Localizable.strings`, `script/package_release.sh`, Loop docs
  Definition of done: Scheduled scans can show localized completion notifications when enabled and permitted, manual scans do not notify, and `dist/` contains a verified zip plus sha256 for the current app commit.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; localization lint; `git diff --check`; `./script/build_and_run.sh --verify`; defaults-based scheduled scan smoke test; Settings screenshot; `./script/package_release.sh`; checksum and strict code-sign validation after zip extraction.
  Priority: high
  Impact: medium
  Risk: medium
  Effort: small
  Confidence: high
  Score: medium impact / medium risk / small

- [x] ID: TASK-024
  Title: Modern status menu popover polish
  Goal: Make the menu bar popover easier to read and visually cleaner.
  What to do: Increase key metric typography, remove duplicated status chrome, use rounded lightweight panels, and shorten the primary action label for the compact two-button layout.
  Files: `CleanMac/Views/StatusMenuView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Disk percentage and scan summary are readable, Russian action labels do not clip, panels are rounded instead of flat gray rectangles, and status data behavior is unchanged.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; localization lint; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check.
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-025
  Title: Settings notification test button
  Goal: Let the user diagnose why scheduled scan notifications may not appear.
  What to do: Add a Settings test button near the auto-scan notification toggle, request macOS notification permission when needed, send a localized test notification, and show inline delivery status.
  Files: `CleanMac/Support/CleanMacNotificationService.swift`, `CleanMac/Views/SettingsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Settings shows a localized test notification button, successful tests post a macOS notification, denied/disabled states show inline status, and no scan or cleanup behavior changes.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; localization lint; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check.
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-026
  Title: Animated sidebar hover rows
  Goal: Make the left sidebar feel more modern and responsive.
  What to do: Replace static sidebar rows with custom SwiftUI rows that animate hover background, icon emphasis, and subtle movement while preserving selection behavior.
  Files: `CleanMac/Views/SidebarView.swift`, Loop docs
  Definition of done: Sidebar rows show a subtle hover response, selected state remains clear, Russian labels fit, Reduce Motion avoids animated movement, and navigation behavior is unchanged.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check; local package rebuild.
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-027
  Title: Sidebar click and keyboard focus polish
  Goal: Finish the sidebar interaction polish with press feedback and keyboard-visible focus.
  What to do: Add a small press animation to sidebar buttons and a clear focus outline/glow for keyboard navigation while preserving selected state and Reduce Motion behavior.
  Files: `CleanMac/Views/SidebarView.swift`, Loop docs
  Definition of done: Clicking a sidebar row has subtle press feedback, keyboard focus is visible, selected state remains readable, Russian labels fit, and navigation behavior is unchanged.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; `git diff --check`; `./script/build_and_run.sh --verify`; visual screenshot check; local package rebuild.
  Priority: medium
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-028
  Title: Enforce Safe Mode during cleanup review
  Goal: Make the enabled-by-default Safe Mode actually prevent review-risk items from being selected or moved to Trash.
  What to do: Pass Safe Mode into Results, lock review-risk selection while it is enabled, clear stale review selections when the preference turns on, and filter selected items again before cleanup execution.
  Files: `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Safe Mode keeps review-risk items visible for inspection but unselectable; selection summaries and bulk selection include only allowed items; switching Safe Mode on removes stale review selections; cleanup execution rejects review-risk items even if stale selection state reaches it; disabling Safe Mode preserves the existing confirmation and Trash-only flow.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; localization lint; `git diff --check`; `./script/build_and_run.sh --verify`; manual safe-mode ON/OFF review.
  Priority: high
  Impact: high
  Risk: low
  Effort: small
  Confidence: high
  Score: high impact / low risk / small

- [x] ID: TASK-029
  Title: Explain unavailable scan areas
  Goal: Replace the generic scan issue count with actionable details about which cleanup areas could not be checked.
  What to do: Present unavailable category names and paths from the existing scan report, then guide the user to Permissions when access is the likely cause without changing scanner or cleanup behavior.
  Files: `CleanMac/Views/MainWindowView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/*/Localizable.strings`, Loop docs
  Definition of done: Results identifies unavailable scan areas and gives a clear next action; successful categories and cleanup safety behavior remain unchanged.
  Verification: `swift test --package-path CleanMacCore`; Debug Xcode build; localization lint; `git diff --check`; `./script/build_and_run.sh --verify`; manual unavailable-area review.
  Priority: high
  Impact: medium
  Risk: low
  Effort: small
  Confidence: high
  Score: medium impact / low risk / small

- [x] ID: TASK-030
  Title: Real Finder Automation permission
  Goal: Replace the static Automation placeholder with a real macOS Apple Events permission for revealing selected items in Finder.
  What to do: Check Finder Automation without prompting, request access only from an explicit button, show granted/not-requested/denied/unavailable states, use Apple Events for Finder reveal with an NSWorkspace fallback, and preserve the entitlement through Debug and Release signing.
  Files: `CleanMac/Support/CleanMacAutomationService.swift`, `CleanMac/Views/PermissionsView.swift`, `CleanMac/Views/ResultsView.swift`, `CleanMac/Models/CleanMacModels.swift`, `CleanMac/*/Localizable.strings`, `CleanMac/*/InfoPlist.strings`, `CleanMac/CleanMac.entitlements`, `CleanMac.xcodeproj/project.pbxproj`, `script/**`, Loop docs
  Definition of done: Opening Permissions never prompts automatically; the Automation row shows the live Finder status; Request Access invokes the native macOS consent flow off the main thread; denied access links to Automation settings; Finder reveal uses Apple Events only when granted and still works through the existing fallback otherwise; built and packaged apps contain the usage description and Automation entitlement.
  Verification: localization and plist lint; `swift test --package-path CleanMacCore`; Debug Xcode build; `./script/build_and_run.sh --verify`; `./script/package_release.sh`; Info.plist and codesign entitlement inspection; manual Permissions UI review without triggering cleanup.
  Priority: high
  Impact: medium
  Risk: medium
  Effort: medium
  Confidence: high
  Score: medium impact / medium risk / medium
