# Contract

## Task

- ID: TASK-043
- Title: Fix custom-folder source selection
- Mode: continue

## Planner Notes

- Why this task now: the user reported that the Custom Folder source looked inactive in both read-only analysis workspaces.
- Expected value: reliable native folder selection without forcing a scan or losing the current built-in source on cancel.
- Main risk: opening a synchronous AppKit modal during a SwiftUI Picker state transaction can drop or visually revert the selection.
- Safety choice: intercept the custom value, defer the panel one main-actor turn, and change source state only after selection.

## Builder Scope

- Allowed files:
  - `CleanMac/Views/DiskAnalysisView.swift`;
  - `CleanMac/Views/DuplicateFinderView.swift`;
  - Loop documentation files.
- Allowed commands:
  - source inspection and Debug build/launch;
  - live native panel open/cancel/select checks without starting a scan;
  - `swift test --package-path CleanMacCore`;
  - standard Git/PR/CI checks and merge after green status.
- Out of scope:
  - scanning user folders, cleanup, release/version/package changes, localization, dependencies, or architecture changes.
- Dependencies allowed: none
- Destructive actions allowed: none

## Evaluator Checklist

- Done criteria:
  - Both Custom Folder segments open their localized native folder panel.
  - Cancel keeps the previous built-in source and leaves controls active.
  - Selecting a folder activates Custom Folder, shows the exact path, and exposes the change-folder button.
  - No scan starts from source selection alone.
- Required verification:
  - Debug build and signed launch verification;
  - live cancel/select interactions in both sections;
  - `swift test --package-path CleanMacCore`;
  - `git diff --check`;
  - green GitHub PR checks.
- Manual checks:
  - Confirm the selected path is visible and no progress indicator appears.
  - Do not start scanning or move any user file during verification.

## Result

- Status: complete
- Verification result: Debug build and signed launch passed; both native panels opened; cancel preserved Downloads in Duplicate Finder; selecting `/Users/admin/Documents` activated Custom Folder and displayed the path in both sections; no scan started; core tests, diff checks, and PR CI passed.
- Notes: the fix changes only source-selection timing and does not expand folder access or scanner scope.
