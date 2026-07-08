# Contract

## Task

- ID: TASK-004/TASK-005/TASK-008
- Title: Safe cleanup, scan filters, and v0.1.0 release
- Mode: continue

## Planner Notes

- Why this task now: the user selected real safe cleanup, scan selection improvements, and a GitHub Release.
- Expected value: make CleanMac useful end-to-end while keeping destructive behavior guarded and reversible.
- Main risk: unsafe deletion. The implementation must move files to Trash only after confirmation and allowlist validation.

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
  - permanent deletion with `removeItem` for user cleanup;
  - notarization or Developer ID signing;
  - changing deployment target;
  - adding third-party dependencies;
  - broad scanner heuristics beyond existing categories.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - CleanMacCore can build a cleanup plan from scan items and reject paths outside category roots.
  - Cleanup execution moves allowlisted items to Trash and reports moved/failed/rejected items.
  - Core tests cover allowlist rejection and executor behavior without permanent deletion.
  - Results UI supports selecting scan results and requires explicit confirmation before cleanup.
  - Review-risk items are visibly distinct and not silently selected by default after scanning.
  - Scan screen has all/safe/review filters and quick selection presets.
  - English and Russian strings cover new UI.
  - GitHub tag `v0.1.0` has a Release with unsigned zip and sha256 assets.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/package_release.sh`
  - GitHub Actions release workflow for `v0.1.0`
- Manual checks:
  - Visually confirm filters/presets and confirmation UI.
  - Confirm app release assets are present in GitHub.
- Evidence to collect:
  - Build/run command exit status.
  - Core test exit status.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- verification fails twice for the same reason;
- work requires out-of-scope files;
- the done criteria cannot be proven;
- cleanup cannot be made Trash-only and allowlisted;
- user-facing behavior diverges from this contract.

## Result

- Status: complete
- Verification result: passed.
- Notes: Safe cleanup planning, Trash execution, scan filters, confirmation UI, CI, local zip packaging, and GitHub Release `v0.1.0` are verified. Release assets: `CleanMac-bd20fa1-unsigned.zip` and `CleanMac-bd20fa1-unsigned.zip.sha256`.
