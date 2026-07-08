# Contract

## Task

- ID: TASK-002/TASK-003/TASK-006
- Title: Read-only scanner, results UI, localization, and window focus polish
- Mode: continue

## Planner Notes

- Why this task now: the user selected scanner, UI polish, smarter Open behavior, and system-language Russian support as the next step.
- Expected value: make CleanMac perform real read-only inspection, show useful results, feel more complete, and work naturally in Russian or English.
- Main risk: accidentally introducing deletion behavior or over-scanning too much of the file system.

## Builder Scope

- Allowed files:
  - `CleanMac/**`
  - `CleanMacCore/Sources/CleanMacCore/CleanMacCore.swift`
  - `CleanMacCore/Sources/CleanMacCore/**`
  - `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`
  - `CleanMac.xcodeproj/project.pbxproj`
  - `AGENTS.md`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `loop.md`
  - `verification.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `./script/package_release.sh`
  - read-only inspection commands
- Out of scope:
  - real file deletion;
  - changing deployment target;
  - adding third-party dependencies;
  - notarization, signing, or release tagging.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - CleanMacCore exposes a read-only scanner for selected cleanup categories.
  - Scanner returns typed items with category, path, size, and risk metadata.
  - Scanner tests prove files are detected and not deleted.
  - UI runs the scanner instead of fake preview results.
  - Dashboard/Scan/Results UI is more informative and keeps cleanup disabled until confirmation logic exists.
  - Menu Open focuses an existing main window before creating a new one.
  - English and Russian localizations exist and app resources include both languages.
  - No real cleanup or deletion code is introduced.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `./script/package_release.sh`
- Manual checks:
  - Review the scanner and UI for non-destructive behavior.
  - Confirm localization resources are copied into the app bundle.
  - Confirm the menu Open action does not create duplicate windows while one exists.
- Evidence to collect:
  - Build/run command exit status.
  - Core test exit status.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- verification fails twice for the same reason;
- work requires out-of-scope files;
- the done criteria cannot be proven;
- the task grows into real scanner or cleanup engine work;
- user-facing behavior diverges from this contract.

## Result

- Status: complete
- Verification result: passed
- Notes: Added the read-only scanner, bound UI results to scanner output, added English/Russian localization resources, and verified that menu Open keeps a single main window. Cleanup/delete actions remain intentionally disabled.
