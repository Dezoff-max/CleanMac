# Contract

## Task

- ID: TASK-038
- Title: Settings permissions and launch at login
- Mode: continue

## Planner Notes

- Why this task now: Permissions is a separate sidebar destination even though it is configuration, and scheduled scans stop when CleanMac is not running.
- Expected value: one coherent Settings page controls access and lets the user keep CleanMac available after login without opening the main window.
- Main risk: Login Item registration is system-controlled and can be denied or require approval; the UI must show the real `SMAppService.mainApp.status` rather than a stale preference.
- UX constraint: keep the existing adaptive CleanMac settings style, preserve explicit-only permission prompts, and do not enable Login Item during verification.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Models/CleanMacModels.swift`
  - `CleanMac/Support/LaunchAtLoginManager.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `CleanMac/Views/PermissionsView.swift`
  - `CleanMac/Views/SettingsView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - Loop documentation files
- Allowed commands:
  - localization plist lint and RU/EN key parity
  - `swift test --package-path CleanMacCore`
  - Debug `xcodebuild`
  - `./script/build_and_run.sh --verify`
  - read-only `SMAppService.mainApp.status` inspection
  - live Settings and foreground/background launch review
- Out of scope:
  - enabling or disabling the user's Login Item during verification;
  - a separate helper app, LaunchAgent, privileged service, or new dependency;
  - changing scan schedules, cleanup behavior, notification permission, signing, or release version.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - The separate Permissions sidebar item is removed and its complete live content appears inside Settings.
  - Results permission guidance routes to Settings.
  - Settings provides a localized “Launch CleanMac at login” toggle backed by `SMAppService.mainApp.register()` and `unregister()`.
  - The UI shows enabled, disabled, approval-required, and unavailable macOS states and exposes Login Items System Settings when action is required.
  - Registration failures show a clear localized message plus the system error detail.
  - Login Item operations run off the main actor and the control shows progress.
  - A normal user launch still presents the main window; a background/login-style launch does not force activation or open the main window.
  - Menu-bar Open still focuses or creates the main window.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - localization lint and RU/EN key parity
  - Debug `xcodebuild`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- Manual checks:
  - Open Settings in Russian and confirm launch status plus all permission rows fit and refresh.
  - Do not toggle Login Item; inspect the current system status read-only.
  - Compare normal `open` with background `open -g`, then use the menu-bar action to restore the window.

## Result

- Status: complete
- Verification result: passed — 28 core tests, localization/key parity, Debug build, signed launch verification, live Settings review, and foreground/background lifecycle checks.
- Notes: Login Item remained unchanged during verification. The current Debug copy reports `.notFound` because it runs from `Documents`; the localized UI explains installing CleanMac in Applications. Background launch produced zero main windows, while activation and menu-bar Open restored the existing window.
