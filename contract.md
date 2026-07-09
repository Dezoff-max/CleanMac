# Contract

## Task

- ID: TASK-018
- Title: Main content technology background
- Mode: continue

## Planner Notes

- Why this task now: the user asked to make the main window background match the supplied light technology example.
- Expected value: make the main app pages feel less plain while keeping controls readable.
- Main risk: custom backgrounds can interfere with `NavigationSplitView` sidebar behavior or reduce contrast.
- UX constraint: keep the native macOS sidebar; apply the image only behind main page content.

## Builder Scope

- Allowed files:
  - `CleanMac/Assets.xcassets/**`
  - `CleanMac/Views/CleanMacComponents.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - image dimension/JSON validation commands
  - read-only inspection commands
- Out of scope:
  - changing cleanup behavior;
  - changing bundle identifier/signing/release workflows;
  - adding third-party dependencies.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - `MainWindowBackground` asset exists and is valid.
  - Dashboard and Settings pages show the supplied background in the main content area.
  - Sidebar remains native and does not show detail content underneath.
  - Controls, cards, and text remain readable.
  - App builds and launches with the new asset catalog.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - PNG dimension check for the background asset
  - JSON validation for the background asset catalog
- Manual checks:
  - Visual screenshots confirm the Dashboard and Settings page background and sidebar behavior.
- Evidence to collect:
  - Build/run command exit status.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- asset catalog compilation fails;
- the background causes sidebar/detail overlap;
- cards or text become hard to read;
- the update requires new dependencies.

## Result

- Status: complete
- Verification result: Passed. The background asset JSON and dimensions are valid, `./script/build_and_run.sh --verify` passes, `swift test --package-path CleanMacCore` passes, and screenshots `/tmp/cleanmac-background-check-3.png` plus `/tmp/cleanmac-background-settings.png` confirm the background on Dashboard and Settings without sidebar bleed.
- Notes: The first ZStack approach was rejected during visual QA because it let detail content show under the sidebar; the final approach applies the background inside `PageContainer`.
