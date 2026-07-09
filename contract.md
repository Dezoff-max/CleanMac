# Contract

## Task

- ID: TASK-015
- Title: Real scan progress and smart cleanup rules
- Mode: continue

## Planner Notes

- Why this task now: the user selected all three follow-up options after TASK-014: real per-area progress, a more premium scan animation, and smarter cleanup rules.
- Expected value: make scanning feel truthful and alive while reducing noisy cleanup candidates from active temporary files and recent small downloads.
- Main risk: progress reporting could make scanner/UI coupling fragile, or smart filters could hide useful candidates unexpectedly.
- UX constraint: keep the scanner read-only, keep cleanup confirmation unchanged, and present progress in Russian/English without adding dependencies.

## Builder Scope

- Allowed files:
  - `CleanMac/**`
  - `CleanMacCore/Sources/CleanMacCore/**`
  - `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `verification.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - read-only inspection commands
- Out of scope:
  - permanent deletion with `removeItem` for user cleanup;
  - changing deployment target;
  - adding third-party dependencies;
  - changing signing/notarization or release flows;
  - background cleanup scheduling;
  - persistent cleanup history across app restarts.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - `CleanMacCore` emits real scan progress events while preserving the existing scan API.
  - Scan UI shows progress percentage, current area, found count, size, and area chips while scanning.
  - Animation remains modern and readable at the default window size.
  - Downloads, logs, and temporary-file scans use more conservative smart candidate rules.
  - English and Russian strings are complete.
  - Cleanup remains Trash-based and confirmation-gated.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
- Manual checks:
  - Visually confirm the Scan screen shows real progress data during scanning and remains readable in the default window size.
- Evidence to collect:
  - Build/run command exit status.
  - Core test exit status.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- verification fails twice for the same reason;
- progress updates require invasive scanner rewrites;
- smart rules require destructive cleanup behavior;
- user-facing behavior diverges from this contract.

## Result

- Status: complete
- Verification result: Passed. `swift test --package-path CleanMacCore`, `plutil -lint`, `git diff --check`, and `./script/build_and_run.sh --verify` pass. Visual screenshot `/tmp/cleanmac-task15-scanning-final.png` confirms live progress, current area, found count, size, and modern scan animation in the default window.
- Notes: TASK-015 keeps scan/cleanup safe by default. Cleanup still requires confirmation and moves accepted items to Trash; no permanent deletion path was added.
