# Contract

## Task

- ID: TASK-024
- Title: Modern status menu popover polish
- Mode: continue

## Planner Notes

- Why this task now: the user asked for larger text and a more minimal, modern menu bar popover.
- Expected value: disk and scan status are easier to read at menu-bar size and the popover looks less like stacked gray blocks.
- Main risk: larger typography can clip Russian labels in the narrow popover.
- UX constraint: keep the popover compact and action-oriented instead of turning it into a full app page.

## Builder Scope

- Allowed files:
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
  - visual screenshot commands
- Out of scope:
  - automatic cleanup or deletion;
  - scheduled scan behavior;
  - release packaging changes;
  - main window redesign.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Status popover uses larger readable typography for key disk and scan metrics.
  - The header does not duplicate the same status text.
  - Main action labels fit without truncation in Russian.
  - Disk and last-scan blocks use rounded modern panels instead of flat gray rectangles.
  - Existing disk/last-scan data behavior is unchanged.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - Screenshot of the open menu bar popover confirms readable, unclipped Russian UI.
- Evidence to collect:
  - Build/test command exit status.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- button text clips again;
- status panels overflow the menu bar popover;
- visual polish requires unrelated scanner or scheduling changes.

## Result

- Status: complete
- Verification result: Passed. SwiftPM tests, Debug Xcode build, localization lint, diff check, `./script/build_and_run.sh --verify`, and visual screenshot `/tmp/cleanmac-status-menu-polished.png` all pass.
- Notes: This is UI-only. Scan, scheduling, cleanup, and packaging behavior were not changed.
