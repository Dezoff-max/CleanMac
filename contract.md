# Contract

## Task

- ID: TASK-021
- Title: Scheduled scan status menu
- Mode: continue

## Planner Notes

- Why this task now: the user asked for automatic scanning at a selected time and current information in the menu bar.
- Expected value: CleanMac can keep lightweight scan status fresh while the app lives in the menu bar after the main window is closed.
- Main risk: background work must stay read-only and must not race a manual scan.
- UX constraint: scheduled scanning is configured in Settings and uses the currently selected scan areas.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Support/CleanMacAutoScanScheduler.swift`
  - `CleanMac/Support/CleanMacPreferences.swift`
  - `CleanMac/Support/CleanMacFormatters.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `CleanMac/Views/SettingsView.swift`
  - `CleanMac/Views/StatusMenuView.swift`
  - `CleanMac/*/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - read-only inspection commands
  - defaults-based smoke test with restoration to default app state
  - visual screenshot commands
- Out of scope:
  - automatic cleanup or deletion;
  - LaunchAgent/background daemon scheduling when the app is not running;
  - signing/notarization/release changes;
  - third-party dependencies.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Settings exposes an auto-scan toggle and time picker.
  - Auto scan uses the currently selected scan areas and is read-only.
  - Auto scan does not overlap manual scans.
  - Menu bar popover shows disk usage, scan-in-progress state, last scan summary/source/time, and next auto scan time when enabled.
  - Manual scans persist the last scan summary for menu bar display.
  - Empty selected areas remain empty and do not silently revert to defaults for scheduling.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - defaults-based scheduled scan smoke test records `lastScanSource=scheduled` and clears `scanInProgress`.
  - Visual screenshot confirms menu bar disk details are readable and not truncated.
- Evidence to collect:
  - Build/test command exit status.
  - Smoke test output.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- scheduling requires privileged background agents;
- any path attempts cleanup without confirmation;
- the menu bar layout clips disk/scan status text;
- scheduled and manual scans can run at the same time.

## Result

- Status: complete
- Verification result: Passed. SwiftPM tests, Xcode Debug build, localization lint, diff check, `./script/build_and_run.sh --verify`, defaults-based scheduled scan smoke test, and visual screenshot `/tmp/cleanmac-status-menu.png` all pass.
- Notes: Auto scan runs only while CleanMac is running and performs read-only scanning of selected areas. It does not clean, move, or delete files.
