# Contract

## Task

- ID: TASK-037
- Title: Live system dashboard menu bar
- Mode: continue

## Planner Notes

- Why this task now: the existing menu popover only shows disk and last scan, while the supplied reference presents a compact live system dashboard.
- Expected value: CPU, memory, disk, battery, network, uptime, and CleanMac scan state are visible without opening the main window.
- Main risk: frequent sampling must stay lightweight, local, and stop when the popover closes.
- UX constraint: follow the supplied two-column card layout while using the light or dark CleanMac appearance selected by the user, preserving CleanMac branding, RU/EN text, and short menu actions.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Support/StatusSystemMetrics.swift`
  - `CleanMac/Views/StatusMenuView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `verification.md`
- Allowed commands:
  - localization plist lint and RU/EN key-parity checks
  - `swift test --package-path CleanMacCore`
  - Debug `xcodebuild`
  - `./script/build_and_run.sh --verify`
  - live menu-bar visual and accessibility inspection
- Out of scope:
  - background monitoring while the popover is closed;
  - external telemetry, analytics, persistence, notifications, or cleanup behavior changes;
  - replacing or deleting user app copies, release version changes, or new dependencies.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - The popover matches the reference structure with a header, 2x2 metric grid, network/uptime strip, system/scan card, and two bottom actions.
  - The popover follows the selected CleanMac light/dark appearance and uses adaptive system materials instead of a fixed reference color scheme.
  - CPU and memory are read from macOS host statistics; disk uses the active home volume; battery is shown when available and degrades gracefully on desktops.
  - Network receive/send rates and system uptime update locally while the popover is open.
  - Existing last-scan and scan-in-progress data remains visible in compact form.
  - The sampling task starts on presentation, refreshes about once per second, and is cancelled automatically when the view disappears.
  - Open focuses the existing main window and Quit terminates CleanMac as before.
  - RU/EN labels fit the fixed popover width and accessibility exposes metric names and values.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - localization lint and RU/EN key parity
  - Debug `xcodebuild`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- Manual checks:
  - Open the menu popover in Russian and confirm all cards fit without clipping.
  - Observe at least two refreshes and confirm live values change or remain valid.
  - Confirm the main window opens through the bottom action; do not trigger scans or cleanup.

## Result

- Status: complete
- Verification result: passed — 28 core tests, localization/key parity, Debug build, launch verification, diff check, and live Russian light/dark menu review.
- Notes: SwiftUI `MenuBarExtra` did not honor `preferredColorScheme`; injecting the selected scheme into the popover environment fixed the live mismatch. The local non-blocking CoreSimulator warning remains unchanged.
