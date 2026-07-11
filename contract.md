# Contract

## Task

- ID: TASK-032
- Title: Multi-select application removal
- Mode: continue

## Planner Notes

- Why this task now: the user explicitly requested checkbox selection for removing several applications from the Applications screen.
- Expected value: the user can build one reviewed removal set instead of confirming every app separately.
- Main risk: mixing detail selection with removal selection, losing per-app leftover choices, or touching leftovers after an individual app move fails.
- UX constraint: use native macOS checkbox controls; keep the last interacted app visible in the detail panel; preserve mandatory confirmation and Trash-only removal.

## Builder Scope

- Allowed files:
  - `CleanMac/Views/ApplicationsView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `verification.md`
- Allowed commands:
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `swift test --package-path CleanMacCore`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
  - non-destructive UI inspection and screenshots
- Out of scope:
  - permanent deletion, Empty Trash, privilege escalation, or forced process termination;
  - changing the application scanner or path allowlists;
  - selecting leftovers automatically;
  - removing a real installed application during verification;
  - unrelated cleanup, permissions, packaging, or release changes.
- Dependencies allowed: no
- Destructive actions allowed: yes, only after the existing dedicated in-app confirmation and only for explicitly checked applications.

## Evaluator Checklist

- Done criteria:
  - Every application row has a native checkbox with a visible checked state.
  - Multiple applications can remain checked while one app is shown in the detail panel.
  - Exact leftover choices are stored separately for each checked application.
  - The summary and destructive button show the selected application count and total reviewed size.
  - Confirmation lists the number of apps, selected leftovers, and total size.
  - Each app is independently replanned and moved before its leftovers; one app failure cannot touch that app's leftovers or block safe reporting for the remaining checked apps.
  - Successfully moved apps leave the list; failed apps remain selected for review.
  - Refresh preserves only selections that still exist.
- Required verification:
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `swift test --package-path CleanMacCore`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- Manual checks:
  - Check at least two applications and confirm both checkboxes remain selected.
  - Switch details and verify per-app leftover choices do not leak to another app.
  - Open the batch confirmation and cancel it without removing anything.
- Evidence to collect:
  - Build/test command exit status.
  - Accessibility state showing multiple checked rows and batch confirmation.
  - UI screenshot path if captured.

## Restart Signals

Restart or shrink the task if:
- SwiftUI checkbox composition breaks row accessibility or detail selection;
- batch execution would require weakening the existing single-app planner/executor checks;
- UI verification would require accepting a removal confirmation.

## Result

- Status: complete
- Verification result: passed. All 15 core tests, localization lint, `git diff --check`, Debug build, and `./script/build_and_run.sh --verify` pass. Live accessibility review showed two independently checked apps, isolated per-app leftover state, and the correct batch confirmation.
- Notes: screenshot saved at `/tmp/cleanmac-task32-multiselect.jpg`. The batch confirmation was cancelled; no installed application or real leftover was moved.
