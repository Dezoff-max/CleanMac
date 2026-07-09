# Contract

## Task

- ID: TASK-013
- Title: Cleaner-style review UX and Trash restore guidance
- Mode: continue

## Planner Notes

- Why this task now: the user selected the option to make the cleanup UI feel more like a complete cleaner with categories, risks, details, and restore support.
- Expected value: make scan results easier to review before cleanup and make post-cleanup recovery from Trash visible and safer.
- Main risk: turning a UI polish request into unsafe cleanup behavior. Keep cleanup Trash-only, require existing allowlist planning, and only restore recorded moved items when the destination is safe.
- UX constraint: avoid decorative marketing surfaces; this is an operational review workspace.

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
  - Results show category groups with counts, sizes, selected totals, and risk mix.
  - Results let the user inspect a selected item with path, category, size, modified time, risk, and cleanup behavior.
  - Cleanup history lists moved-to-Trash items from the current session.
  - A safe restore action can restore a recorded trashed item when the Trash path exists and the original destination is not occupied.
  - Restore failures are reported without deleting or overwriting anything.
  - Existing cleanup still uses allowlisted planning and Trash movement only.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
- Manual checks:
  - Visually confirm Results shows category review, detail panel, and cleanup history without cramped or clipped content.
  - Confirm restore controls are disabled or informative when no cleanup history exists.
- Evidence to collect:
  - Build/run command exit status.
  - Core test exit status.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- verification fails twice for the same reason;
- work requires out-of-scope files;
- the done criteria cannot be proven;
- cleanup cannot remain Trash-only, restore-only, and allowlisted;
- user-facing behavior diverges from this contract.

## Result

- Status: complete
- Verification result: Passed. `swift test --package-path CleanMacCore` now runs 9 tests including restore/no-overwrite coverage; `plutil -lint` passes for English/Russian strings; `git diff --check` passes; `./script/build_and_run.sh --verify` builds and launches the app. Visual screenshot confirmed Results shows compact category groups, item list, and detail panel in the standard window.
- Notes: TASK-013 is implemented. Cleanup remains Trash-only; restore is current-session only and refuses to overwrite existing original paths.
