# Contract

## Task

- ID: TASK-023
- Title: Auto scan completion notifications and local release package
- Mode: continue

## Planner Notes

- Why this task now: the user selected notifications after auto scan and a fresh local dist/release zip.
- Expected value: scheduled scans become visible without opening the app, and the user gets a current distributable artifact.
- Main risk: notifications must stay opt-in at the macOS permission layer and must not change cleanup safety.
- UX constraint: keep the Settings panel compact and keep notifications tied to scheduled scan completion only.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Support/CleanMacAutoScanScheduler.swift`
  - `CleanMac/Support/CleanMacNotificationService.swift`
  - `CleanMac/Support/CleanMacPreferences.swift`
  - `CleanMac/Views/SettingsView.swift`
  - `CleanMac/*/Localizable.strings`
  - `script/package_release.sh`
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
  - `./script/package_release.sh`
  - `shasum -a 256 -c dist/*.sha256`
  - non-destructive defaults-based smoke tests
  - read-only artifact inspection commands
- Out of scope:
  - automatic cleanup or deletion;
  - LaunchAgent/background daemon scheduling when the app is not running;
  - notarization or Developer ID signing setup;
  - publishing a new GitHub Release tag unless explicitly requested.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Auto scan completion can deliver a localized macOS notification summary.
  - Settings exposes a notification toggle for scheduled scans.
  - Notifications are requested through the system permission API and silently skip if denied.
  - Manual scans do not trigger the scheduled-scan notification.
  - Release packaging creates a fresh `dist/CleanMac-<commit>-unsigned.zip` and `.sha256`.
  - Packaged app validates with code signing checks available in `script/package_release.sh`.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
  - `./script/package_release.sh`
  - checksum validation for the produced zip
- Manual checks:
  - defaults-based scheduled scan smoke test completes without cleanup and leaves notification preference enabled.
  - Artifact list in `dist/` shows the fresh zip and checksum.
- Evidence to collect:
  - Build/test command exit status.
  - Smoke test output.
  - `dist/` artifact names and checksum validation.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- notification authorization blocks scanning;
- scheduled scans start cleanup or destructive behavior;
- packaging fails after a clean Release build;
- signing/notarization requires credentials unavailable on this Mac.

## Result

- Status: complete
- Verification result: Passed. SwiftPM tests, Debug Xcode build, localization lint, diff check, `./script/build_and_run.sh --verify`, defaults-based scheduled scan smoke test, visual Settings screenshot `/tmp/cleanmac-autoscan-notifications-settings-2.png`, `./script/package_release.sh`, checksum validation, and strict code-sign validation after zip extraction all pass.
- Notes: Scheduled scan notifications are localized and permission-aware; manual scans do not notify. The local unsigned/ad-hoc package is written as `dist/CleanMac-<commit>-unsigned.zip`.
