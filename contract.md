# Contract

## Task

- ID: TASK-027
- Title: Sidebar click and keyboard focus polish
- Mode: continue

## Planner Notes

- Why this task now: the user selected adding click animation and keyboard focus styling after the sidebar hover polish.
- Expected value: the sidebar feels responsive for mouse users and remains clear for keyboard navigation.
- Main risk: focus styling can compete with the selected accent state or click animation can feel jumpy.
- UX constraint: keep motion subtle, preserve readability, and respect Reduce Motion.

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
  - Sidebar rows show a subtle press/click animation.
  - Keyboard-focused sidebar rows show a visible focus outline or glow.
  - Selected section remains clear and does not lose focus readability.
  - Russian labels still fit at the current sidebar width.
  - Reduce Motion avoids animated movement and press scaling.
  - Navigation selection behavior is unchanged.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - Sidebar renders without clipping, click feedback is visible, and keyboard focus styling is visible.
- Evidence to collect:
  - Build/test command exit status.
  - Visual screenshot path if captured.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- the custom row breaks sidebar selection;
- press/focus states cause layout jumps;
- the fix requires unrelated navigation or window restructuring.

## Result

- Status: complete
- Verification result: Passed. Debug Xcode build, `./script/build_and_run.sh --verify`, SwiftPM tests, `git diff --check`, visual screenshot `/tmp/cleanmac-sidebar-keyboard-focus.png`, and local release packaging all pass.
- Notes: Sidebar rows now have subtle click press feedback and visible keyboard focus styling. Reduce Motion disables press scaling and movement. Scan, cleanup, scheduling, notification, language, and theme behavior were not changed.
