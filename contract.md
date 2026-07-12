# Contract

## Task

- ID: TASK-041
- Title: CleanMac v0.3.0 release
- Mode: continue

## Planner Notes

- Why this task now: the feature branch has a green CI run and contains several user-visible additions since v0.2.1.
- Expected value: a reproducible v0.3.0 package and GitHub release that match the current app and make the new functionality available together.
- Main risk: publishing an artifact from an unmerged or differently versioned commit, attaching stale ZIP files, or implying Apple notarization when only ad-hoc signing is available.
- Release assumption: the new feature set warrants minor version 0.3.0 with build number 4; GitHub release copy remains English.

## Builder Scope

- Allowed files:
  - `CleanMac.xcodeproj/project.pbxproj`
  - generated `dist/CleanMac.app`, ZIP, and SHA-256 assets;
  - GitHub PR/release metadata;
  - Loop documentation files
- Allowed commands:
  - read-only source, Git, bundle, signing, and release inspection;
  - `swift test --package-path CleanMacCore`;
  - Debug `xcodebuild`;
  - `./script/build_and_run.sh --verify`;
  - `./script/package_release.sh`;
  - PR update/merge and GitHub Release publishing explicitly approved by the user;
  - `git diff --check`.
- Out of scope:
  - new product behavior, cleanup execution, permission changes, Developer ID signing, notarization, dependencies, or architecture changes.
- Dependencies allowed: no external dependencies; system CryptoKit only
- Destructive actions allowed: replace generated ignored `dist/` artifacts only; no user-data cleanup

## Evaluator Checklist

- Done criteria:
  - Debug and Release bundles both report version 0.3.0 and build 4.
  - The feature PR is green and merged into `main` before tagging.
  - The final arm64 ZIP is built from the tagged main commit, passes strict signature verification after fresh extraction, and has a matching SHA-256 file.
  - GitHub Release v0.3.0 is public, latest, not prerelease, uses English notes, and contains exactly the verified ZIP and SHA-256 assets.
  - The distribution note clearly says the build is ad-hoc signed and not Apple-notarized.
- Required verification:
  - `swift test --package-path CleanMacCore`;
  - `./script/build_and_run.sh --verify`;
  - `./script/package_release.sh`;
  - extracted bundle version/build/architecture/signature inspection;
  - local and downloaded SHA-256 verification;
  - GitHub CI and release metadata inspection;
  - `git diff --check`.
- Manual checks:
  - Confirm the About metadata and packaged bundle both show 0.3.0 (4).
  - Confirm Gatekeeper limitations are documented without recommending security bypasses.

## Result

- Status: complete
- Verification result: 40 SwiftPM tests, local Debug build/launch, green PR CI, main merge, Release packaging, strict fresh-extraction signature verification, 0.3.0 (4) metadata, arm64 architecture, portable SHA-256 verification, and downloaded GitHub asset verification all passed.
- Notes: public latest release `v0.3.0` targets merge commit `515f591`, contains the verified ZIP and portable checksum, and is transparently labeled ad-hoc signed and not notarized because no Developer ID identity is installed.
