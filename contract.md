# Contract

## Task

- ID: TASK-007
- Title: Dashboard scan area discoverability and initial fit
- Mode: continue

## Planner Notes

- Why this task now: the Dashboard says four areas are selected, but it does not show which areas or where to change them; after the added list, the default/restored window height can cut off the Safety block.
- Expected value: make the scan selection understandable and make the first visible Dashboard feel complete rather than clipped.
- Main risk: adding clutter or changing scanner behavior when this should be a small UI discoverability fix.

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
  - scanner logic changes;
  - changing deployment target;
  - adding third-party dependencies;
  - notarization, signing, or release tagging.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Dashboard shows the selected scan area names and path hints.
  - Dashboard has a direct action to open the Scan screen for changing areas.
  - The app opens/restores the main window at a height that shows Dashboard blocks without cutting off the Safety panel on this Mac.
  - New visible copy is localized in English and Russian.
  - Scanner behavior and cleanup safety remain unchanged.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
- Manual checks:
  - Visually confirm selected areas and the Safety panel are visible on Dashboard.
  - Confirm the Choose Areas action opens the Scan screen.
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
- Notes: Dashboard now lists selected scan areas, includes a Choose Areas action that opens the Scan section, and expands restored short windows to show all Dashboard blocks. Scanner and cleanup behavior were not changed.
