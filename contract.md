# Contract

## Task

- ID: TASK-047
- Title: CleanMac v0.4.0 release
- Mode: continue

## Planner Notes

- Why this task now: the user explicitly requested that the release be updated after the thermal optimization and Smart Shredder feature were pushed.
- Expected value: publish the verified feature set as the next minor release with reproducible archive and checksum assets.
- Main risk: tagging an unverified commit or presenting an ad-hoc build as notarized.
- Release choice: bump `0.3.0 (4)` to `0.4.0 (5)` because the release adds a user-facing feature; keep the existing ad-hoc/unsigned distribution wording unless signing secrets produce a genuinely signed/notarized artifact in CI.

## Builder Scope

- Allowed files:
  - `CleanMac.xcodeproj/project.pbxproj`;
  - `README.md` and `docs/screenshots/`;
  - release and Loop documentation files.
- Allowed commands:
  - source/version inspection;
  - full SwiftPM tests;
  - Debug build/launch verification;
  - local Release packaging and fresh-extraction validation;
  - non-destructive app navigation and screenshot capture without accepting cleanup or shredder actions;
  - git branch/commit/push and GitHub PR merge;
  - create and push tag `v0.4.0`;
  - inspect/edit the corresponding GitHub Release and verify its downloaded assets.
- Out of scope:
  - new feature code, changing deployment targets/dependencies, inventing signing credentials, disabling security, deleting user files, or claiming notarization without evidence.
- Dependencies allowed: none
- Destructive actions allowed: generated build/dist artifacts only

## Evaluator Checklist

- Done criteria:
  - bundle reports version `0.4.0` and build `5`;
  - all core tests and Debug launch verification pass on the release commit;
  - local Release ZIP extracts with a valid strict ad-hoc signature and matching SHA-256;
  - release version commit is merged into `main` before tagging;
  - tag `v0.4.0` points to that verified `main` commit;
  - GitHub Release is published with ZIP and `.sha256` assets and accurate notes/limitations;
  - downloaded assets pass checksum and fresh-extraction signature/version inspection.
- Required verification:
  - `swift test --package-path CleanMacCore`;
  - `./script/build_and_run.sh --verify`;
  - `./script/package_release.sh`;
  - bundle version, architecture, signature, and checksum inspection;
  - GitHub CI/Release workflow and clean asset download verification;
  - `git diff --check`.
- Manual checks:
  - Keep release publication separate from commit/push and tag creation.
  - Do not claim Developer ID signing or notarization unless the published asset proves it.

## Result

- Status: in progress
- Verification result: pending.
- Notes: PR #14 is merged and green; release versioning/package publication remains.
