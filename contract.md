# Contract

## Task

- ID: TASK-026
- Title: Animated sidebar hover rows
- Mode: continue

## Planner Notes

- Why this task now: the user asked for a modern hover animation on the left sidebar menu sections.
- Expected value: the sidebar feels more responsive and polished without changing navigation behavior.
- Main risk: custom sidebar rows can fight native macOS sidebar density or clip Russian labels.
- UX constraint: keep the effect subtle, fast, and respectful of Reduce Motion.

## Builder Scope

- Allowed files:
  - `CleanMac/Views/SidebarView.swift`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `git diff --check`
  - visual screenshot commands if useful
- Out of scope:
  - automatic cleanup or deletion;
  - scanner or cleanup behavior;
  - settings, scheduling, or notification behavior;
  - release packaging changes;
  - main window redesign.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Sidebar rows show a visible but subtle hover response.
  - Selected section remains clear and uses the existing accent style.
  - Russian labels fit at the current sidebar width.
  - Reduce Motion avoids animated movement.
  - Navigation selection behavior is unchanged.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - Sidebar renders without clipping and hover feedback is visible.
- Evidence to collect:
  - Build/test command exit status.
  - Visual screenshot path if captured.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- the custom row breaks sidebar selection;
- hover states cause layout jumps;
- the fix requires unrelated navigation or window restructuring.

## Result

- Status: complete
- Verification result: Passed. Debug Xcode build, `./script/build_and_run.sh --verify`, SwiftPM tests, `git diff --check`, visual screenshot `/tmp/cleanmac-sidebar-hover.png`, and local release packaging all pass.
- Notes: Sidebar rows now use subtle hover background, icon emphasis, and motion while preserving selected state. Reduce Motion disables the movement. Scan, cleanup, scheduling, notification, language, and theme behavior were not changed.
