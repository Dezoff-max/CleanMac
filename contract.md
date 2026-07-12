# Contract

## Task

- ID: TASK-044
- Title: Low disk space warning
- Mode: continue

## Planner Notes

- Why this task now: the menu-bar dashboard already samples free disk capacity and can surface an actionable warning before storage is exhausted.
- Expected value: a clear under-10% warning, an immediate path to Disk Analysis, and a restrained local notification.
- Main risk: repeated one-second samples can spam notifications, and requesting notification permission automatically would be intrusive.
- Safety choice: keep the menu warning live, notify at most once per 24 hours only when macOS permission is already granted, and never start scanning automatically.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/LowDiskSpaceWarningPolicy.swift`;
  - `CleanMacCore/Tests/CleanMacCoreTests/LowDiskSpaceWarningPolicyTests.swift`;
  - `CleanMac/Support/StatusSystemMetrics.swift`;
  - `CleanMac/Support/CleanMacLowDiskSpaceMonitor.swift`;
  - `CleanMac/Support/CleanMacNotificationService.swift`;
  - `CleanMac/Support/CleanMacPreferences.swift`;
  - `CleanMac/Support/MainWindowController.swift`;
  - `CleanMac/Views/StatusMenuView.swift`;
  - `CleanMac/Views/MainWindowView.swift`;
  - `CleanMac/CleanMacApp.swift`;
  - RU/EN localization;
  - Loop documentation files.
- Allowed commands:
  - source inspection and Debug build/launch;
  - focused policy fixtures and full core tests;
  - read-only menu navigation review without sending a real notification;
  - `swift test --package-path CleanMacCore`;
  - standard Git/PR/CI checks and merge after green status.
- Out of scope:
  - automatic scanning/cleanup, notification permission prompts, Settings redesign, release/version/package changes, dependencies, or architecture changes.
- Dependencies allowed: none
- Destructive actions allowed: none

## Evaluator Checklist

- Done criteria:
  - Low space means valid total capacity with free fraction strictly below 10%.
  - Notification eligibility is limited to once per 24 hours and persisted only after successful delivery.
  - The monitor checks at launch and every 30 minutes without requesting permission.
  - The menu warning recommends scanning and provides a direct Disk Analysis button.
  - Navigation reveals the existing main window or opens one, then selects Disk Analysis without starting analysis.
- Required verification:
  - focused threshold/boundary/cooldown tests;
  - Debug build and signed launch verification;
  - live menu-to-Disk-Analysis navigation without triggering a scan or notification;
  - `swift test --package-path CleanMacCore`;
  - `git diff --check`;
  - green GitHub PR checks.
- Manual checks:
  - Confirm normal disk space keeps the warning hidden.
  - Do not change notification permission, start scanning, or move any user file during verification.

## Result

- Status: in progress
- Verification result: pending implementation and focused policy/UI checks.
- Notes: the warning uses the same available-capacity value shown in the menu-bar disk card; APFS purgeable-space behavior remains represented by macOS capacity APIs.
