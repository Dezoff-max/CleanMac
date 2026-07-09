# Contract

## Task

- ID: TASK-025
- Title: Settings notification test button
- Mode: continue

## Planner Notes

- Why this task now: the user suspects the 16:00 auto scan ran but no notification appeared.
- Expected value: the user can test macOS notification permission and delivery directly from Settings.
- Main risk: the test must not trigger scanning or cleanup and must report denied permission clearly.
- UX constraint: keep Settings compact and make the test status readable in Russian.

## Builder Scope

- Allowed files:
  - `CleanMac/Support/CleanMacNotificationService.swift`
  - `CleanMac/Views/SettingsView.swift`
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
  - visual screenshot commands if useful
- Out of scope:
  - automatic cleanup or deletion;
  - changing scheduled scan timing;
  - release packaging changes;
  - main window redesign.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Settings exposes a localized test notification button near the auto-scan notification toggle.
  - Pressing the button requests system notification permission when needed.
  - A successful test posts a localized macOS notification.
  - Denied or disabled notification states show a clear inline status.
  - Test notification does not start a scan and does not change cleanup behavior.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - Settings view shows the test notification control without clipping.
- Evidence to collect:
  - Build/test command exit status.
  - Visual screenshot path if captured.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- the test button triggers scanning or cleanup;
- notification permission handling blocks the main thread;
- the fix requires background agents or packaging changes.

## Result

- Status: complete
- Verification result: Passed. Localization lint, diff check, Debug Xcode build, `./script/build_and_run.sh --verify`, SwiftPM tests, and visual screenshot `/tmp/cleanmac-settings-test-notification.png` all pass.
- Notes: The Settings test button requests notification permission when needed and reports disabled, denied, failed, or sent status inline. Scan, cleanup, and schedule timing behavior were not changed.
