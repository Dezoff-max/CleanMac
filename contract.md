# Contract

## Task

- ID: TASK-009/TASK-010/TASK-011/TASK-012
- Title: Signed distribution readiness, deeper scanner, real permissions, and icon refresh
- Mode: continue

## Planner Notes

- Why this task now: the user selected signing/notarization, deeper scanner heuristics, Full Disk Access status, and replacing the icon everywhere.
- Expected value: make CleanMac more complete as a real cleanup utility and ready for signed distribution once Apple credentials are available.
- Main risk: unsafe cleanup expansion. New categories must stay inside explicit allowlisted roots, default to review when broad, and keep Trash-only cleanup.
- Signing constraint: this Mac currently has no valid Developer ID signing identity, so notarization can only be implemented as a ready-to-run pipeline and verified in unsigned fallback mode.

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
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - The supplied broom/code icon is used for the app icon, menu bar icon, and visible in-app brand icon.
  - Scanner includes additional developer/browser/download cleanup categories with explicit roots and risk labels.
  - Core tests cover at least one newly added category and keep cleanup path allowlisting intact.
  - Permissions UI shows a live Full Disk Access status derived from protected path readability and has a refresh action.
  - Packaging supports optional Developer ID signing, hardened runtime verification, and optional notarization when credentials are configured.
  - CI/release docs explain required private secrets without exposing any secrets.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/package_release.sh`
  - `codesign -dvvv dist/CleanMac.app` and `spctl -a -vv dist/CleanMac.app` inspection, accepting unsigned/ad hoc status when no Developer ID exists
- Manual checks:
  - Visually confirm the refreshed icon appears in the app and menu bar.
  - Confirm signing/notarization is documented as blocked by missing local certificate unless credentials are later provided.
- Evidence to collect:
  - Build/run command exit status.
  - Core test exit status.
  - File list touched.
  - Signing identity check result.

## Restart Signals

Restart or shrink the task if:
- verification fails twice for the same reason;
- work requires out-of-scope files;
- the done criteria cannot be proven;
- cleanup cannot remain Trash-only and allowlisted;
- user-facing behavior diverges from this contract.

## Result

- Status: complete
- Verification result: Passed local implementation checks. `./script/package_release.sh` creates `dist/CleanMac-5f4ae88-unsigned.zip`; the zip checksum verifies and the app extracted from the zip passes `codesign --verify --deep --strict --verbose=2`. `spctl` rejects it as expected because this Mac has no Developer ID identity.
- Notes: TASK-009/TASK-010/TASK-011/TASK-012 are implemented. Actual Developer ID signing/notarization remains blocked until Apple Developer credentials and CI secrets are configured.
