# Contract

## Task

- ID: TASK-058
- Title: Repair startup freeze; CleanMac v0.5.1
- Mode: hotfix

## Authorization and scope

Continue the requested GitHub release update and Applications installation by repairing the startup freeze discovered in published 0.5.0.

- Keep macOS 14+, native SwiftUI and CleanMacCore; no new dependencies.
- Make scan-selection migration idempotent, including schema 1 with an absent selection. Preserve explicit empty selections, saved choices and newer schemas; do not reset user preferences.
- Add a regression harness against the real preference implementation.
- Move disk-capacity queries off the UI thread, coalesce concurrent requests, cache samples and use inert initial view snapshots.
- Resolve each representable's native window once instead of repeating callbacks during body updates.
- Preserve cleanup, confirmation, permissions and signing policies.
- Verify responsive Debug and installed Release UI with existing preferences. Process existence alone is insufficient.
- Publish verified 0.5.1 (7) DMG/ZIP and SHA-256 assets after checks pass, then download, verify and install the published payload in Applications.
- Do not delete user files, execute cleanup/uninstall/Shredder, purge memory, flush DNS, reset preferences or change macOS security settings during verification.

## Verification

- `./script/test_preferences.sh` after Debug build; Release: `./script/test_preferences.sh build/XcodeData/Build/Products/Release`.
- Full `swift test --package-path CleanMacCore`.
- `./script/build_and_run.sh --verify` plus responsive-window, navigation/menu, close/reopen and CPU/memory checks after startup.
- `./script/package_release.sh`; fresh ZIP extraction and DMG mount with strict signature, version/build, architecture and checksum validation.
- Installed Release UI check with existing preferences; record executable path and process sample.
- `git diff --check`; green GitHub checks; tag matches verified code; downloaded published assets verified before final installation.

## Result

- Status: complete. PR #18 merged after CI; v0.5.1 is public/latest, and the verified GitHub ZIP payload is installed and responsive.
- Version target: 0.5.1 (7).
- Debug: responsive after 45 seconds, about 0.1% CPU and 128 MiB RSS.
- Preferences: all six regression cases pass; the original 0.5.0 implementation fails the absent-selection reproducer.
- Core: 62 tests pass. Local Release packaging verifies strict ZIP and mounted-DMG signatures.
- Installed local Release: verified ZIP installed in `/Applications/CleanMac.app`; navigation, disk refresh, System, return to Overview and close/recreation remain responsive. Sample: 83.6 MB physical footprint, 143.1 MB peak; main thread mostly waiting, with no repeated disk/dashboard busy loop.
- Correction to TASK-057: 0.5.0 assets and executable path were verified, but process-level launch checks missed a UI hang. Its previous stable-launch claim is superseded by TASK-058.
