# Contract

## Task

- ID: TASK-057
- Title: Dashboard, motion and workflow polish; CleanMac v0.5.0
- Mode: continue

## Authorization and scope

The user explicitly requested analysis and improvements to the app and animations,
publication of an updated GitHub release, useful ideas from the supplied PureMac
screenshot, and installation into Applications. Build on the existing PR #17 so
previously implemented features are preserved and reviewed before release.

- Keep macOS 14+, native SwiftUI and CleanMacCore; no new dependencies.
- Add a live, accurately labelled storage overview and quick tool navigation.
- Improve adaptive layout, hover/press feedback and Reduce Motion behavior.
- Prevent scan/cleanup/restore overlap and unwanted completion navigation.
- Keep existing scan, confirmation, Trash and isolated permanent-action policies.
- Update localizations, version/build, release notes and verification documentation.
- Build/test/package, commit/push/merge verified work, create v0.5.0, publish DMG/ZIP
  with checksums, verify downloaded assets, then install and open /Applications/CleanMac.app.
- Do not run cleanup, uninstall, shredder, memory purge or DNS flush against real
  user data/system state during review. Destructive tests may use disposable fixtures.
- Do not change repository visibility, dependencies, deployment targets or security settings.
- Do not invent signing credentials or describe an ad-hoc build as notarized.

## Verification

- Full `swift test --package-path CleanMacCore`.
- `./script/build_and_run.sh --verify` and non-destructive UI review.
- RU/EN plist lint/key parity and `git diff --check`.
- `./script/package_release.sh`; ZIP/DMG checksum, strict signature, bundle version
  and architecture checks against fresh extraction/mount.
- Green GitHub checks; release tag matches verified merged code.
- Download published assets and validate checksums/version/signature.
- Install the verified bundle into Applications and verify the running executable path.

## Result

- Status: complete. CI, downloaded release assets and Applications installation verified.
- Version target: 0.5.0 (6).

- Published release: https://github.com/Dezoff-max/CleanMac/releases/tag/v0.5.0
- Release commit: `40e5ffe5044641fff0cb69f7fac1bc257ea60698`.
