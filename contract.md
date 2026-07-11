# Contract

## Task

- ID: TASK-033
- Title: Custom About window and v0.2.1 release
- Mode: continue

## Planner Notes

- Why this task now: the user asked to replace the sparse system About panel with a polished window consistent with their other macOS apps, before publishing the pending v0.2.1 release.
- Expected value: About CleanMac clearly presents the product, exact installed version/build, local-first safety model, author, license, and project links.
- Main risk: creating duplicate windows, hardcoding a stale version, or using macOS APIs newer than the current macOS 14 deployment target.
- UX constraint: preserve the current RU/EN language and light/dark appearance selections; keep the window compact, fixed-size, and independently closable.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Views/AboutView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - `CleanMac.xcodeproj/project.pbxproj`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `verification.md`
- Allowed commands:
  - localization/plist lint
  - `swift test --package-path CleanMacCore`
  - `./script/build_and_run.sh --verify`
  - `./script/package_release.sh`
  - non-destructive UI inspection and screenshots
  - focused Git/GitHub release commands after verification
- Out of scope:
  - cleanup behavior, scanner rules, application removal, permissions, signing identity setup, or notarization;
  - adding dependencies or changing the macOS deployment target;
  - presenting an ad-hoc package as Apple-notarized.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - The app menu replaces the system About action with a localized `About CleanMac` action.
  - A singleton About scene opens centered and does not create duplicate windows.
  - The window presents the CleanMac icon, name, localized tagline, exact bundle version/build, developer, local-first mode, MIT license, and working GitHub/Release/License links.
  - The selected RU/EN language and light/dark appearance apply to the About window.
  - The window has a deliberate fixed content size and normal close behavior.
  - Version 0.2.1 build 3 is packaged and published with an honest unsigned/ad-hoc distribution note.
- Required verification:
  - localization lint
  - `swift test --package-path CleanMacCore`
  - `./script/build_and_run.sh --verify`
  - `./script/package_release.sh`
  - `git diff --check`
- Manual checks:
  - Open About from the application menu and confirm its visual hierarchy in Russian.
  - Switch to English and dark appearance and confirm the About content updates.
  - Invoke About more than once and confirm only one About window exists.
  - Inspect the packaged app Info.plist for version 0.2.1 build 3 and verify the ZIP checksum.

## Restart Signals

Restart or shrink the task if:
- the SwiftUI `Window` scene does not behave as a singleton on macOS 14;
- replacing `.appInfo` removes required application-menu behavior;
- visual verification reveals clipping or a fixed-size window that does not fit localized content.

## Result

- Status: in progress
- Verification result: pending
- Notes: the current branch already contains the intended v0.2.1 build-number bump; no release has been published yet.
