# Contract

## Task

- ID: TASK-022
- Title: Auto scan frequency options
- Mode: continue

## Planner Notes

- Why this task now: the user asked to add scan timing choices for every hour or every two hours.
- Expected value: the schedule control is more useful than a single daily time and can keep menu bar scan status fresher.
- Main risk: interval scans must run once per interval slot, not every timer tick.
- UX constraint: preserve the existing daily time behavior and add frequency choices without crowding Settings.

## Builder Scope

- Allowed files:
  - `CleanMac/Support/CleanMacAutoScanScheduler.swift`
  - `CleanMac/Support/CleanMacPreferences.swift`
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
  - defaults-based smoke test with restoration to a non-surprising local state
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
  - Settings shows frequency choices: daily, every hour, every two hours.
  - Existing daily behavior remains the default and uses the selected time.
  - Hourly and two-hour modes use the selected time as the start anchor.
  - Scheduler records a run key per interval slot so it does not repeat every minute.
  - Menu bar next-run calculation follows the selected frequency.
  - English and Russian strings cover the new controls.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - defaults-based smoke test records scheduled scans for `hourly` and `everyTwoHours`.
  - Visual screenshot confirms the Settings frequency control is readable in Russian.
- Evidence to collect:
  - Build/test command exit status.
  - Smoke test output.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- interval logic starts scans every timer tick;
- settings controls clip at the standard window size;
- scheduled scans overlap manual scans;
- the update requires background agents or destructive cleanup behavior.

## Result

- Status: complete
- Verification result: Passed. SwiftPM tests, Xcode Debug build, localization lint, diff check, `./script/build_and_run.sh --verify`, hourly/every-two-hours defaults smoke test, and visual screenshot `/tmp/cleanmac-autoscan-frequency-settings-2.png` all pass.
- Notes: Interval auto scan is still read-only and runs only while CleanMac is running.
