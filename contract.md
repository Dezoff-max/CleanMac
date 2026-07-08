# Contract

## Task

- ID: TASK-001
- Title: Main window UI and launch lifecycle
- Mode: setup

## Planner Notes

- Why this task now: the app currently launches only as a minimal shell and the user wants a full windowed interface that still remains in the menu bar.
- Expected value: make the app feel like a real CleanMac application while preserving the menu bar workflow.
- Main risk: accidentally mixing UI scaffolding with real destructive cleanup behavior.

## Builder Scope

- Allowed files:
  - `CleanMac/**`
  - `CleanMacCore/Sources/CleanMacCore/CleanMacCore.swift`
  - `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`
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
  - CleanMac uses a primary launch window scene instead of only an on-demand window.
  - App activates as a normal macOS app on launch.
  - Closing the main window does not terminate the process.
  - Menu bar extra remains available with Open and Quit actions.
  - Main window contains Dashboard, Scan, Results, Permissions, and Settings sections.
  - No cleanup or deletion code is introduced.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
- Manual checks:
  - Review the UI code for non-destructive actions only.
  - Confirm the menu Open action still targets the main window.
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
- Verification result: `./script/build_and_run.sh --verify` passed; `swift test --package-path CleanMacCore` passed; System Events saw a `Dashboard` window after launch; closing that window left the `CleanMac` process alive.
- Notes: UI-only shell implemented. Real scanning and cleanup remain out of scope for this task.
