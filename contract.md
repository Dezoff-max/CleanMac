# Contract

## Task

- ID: TASK-014
- Title: Modern scan activity animation
- Mode: continue

## Planner Notes

- Why this task now: the user asked for a modern scanning animation.
- Expected value: make active scans feel responsive and polished without changing cleanup behavior.
- Main risk: adding animation that is too flashy, inaccessible, or invisible because scans finish quickly.
- UX constraint: keep it native macOS, respect Reduce Motion, and keep operational status copy visible.

## Builder Scope

- Allowed files:
  - `CleanMac/**`
  - `CleanMacCore/Sources/CleanMacCore/CleanMacCore.swift`
  - `CleanMacCore/Sources/CleanMacCore/**`
  - `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`
  - `CleanMac.xcodeproj/project.pbxproj`
  - `.github/workflows/**`
  - `script/**`
  - `docs/**`
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
  - `codesign`, `spctl`, and read-only signing inspection commands
  - read-only inspection commands
- Out of scope:
  - permanent deletion with `removeItem` for user cleanup;
  - actual notarization submission without Apple Developer credentials;
  - changing deployment target;
  - adding third-party dependencies;
  - uploading a new public release without explicit tag/version selection.
  - background cleanup scheduling;
  - persistent cleanup history across app restarts.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Scan screen shows a modern animated scan activity surface while `isScanning` is true.
  - The animation includes motion and status phases, but still works as a static status surface when Reduce Motion is enabled.
  - Fast scans keep the scan state visible long enough for the animation to be perceivable.
  - English and Russian strings are complete.
  - No cleanup/scanner safety behavior changes.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
- Manual checks:
  - Visually confirm the Scan screen shows the animated module during scanning and remains readable in the default window size.
- Evidence to collect:
  - Build/run command exit status.
  - Core test exit status.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- verification fails twice for the same reason;
- work requires out-of-scope files;
- the done criteria cannot be proven;
- cleanup/scanning behavior changes unexpectedly;
- user-facing behavior diverges from this contract.

## Result

- Status: complete
- Verification result: Passed. `swift test --package-path CleanMacCore`, `plutil -lint`, `git diff --check`, `xcodebuild`, and `./script/build_and_run.sh --verify` pass. Visual screenshot `/tmp/cleanmac-task14-scanning.png` confirms the animated scan activity surface appears during scanning in the default window.
- Notes: TASK-014 is implemented. Scanner and cleanup safety behavior were not changed; only the active scan UI state and minimum visible scan animation duration were updated.
