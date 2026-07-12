# Contract

## Task

- ID: TASK-039
- Title: Advanced developer cleanup
- Mode: continue

## Planner Notes

- Why this task now: CleanMac already scans Node/npm, SwiftPM, and Xcode DerivedData, but does not expose the other reproducible developer caches requested by the user.
- Expected value: developers can review package-manager, IDE, AI-tool, and Xcode storage through explicit allowlisted categories instead of broad home-directory scans.
- Main risk: IDE and AI tools keep settings, extensions, projects, history, sessions, and memory beside caches; Xcode Archives and Simulator data can be valuable and must never be treated as ordinary auto-selected junk.
- Assumption: “old” Simulator data means a direct Simulator device or user-installed runtime whose modification date is at least 180 days old. System-managed runtimes under `/Library` remain out of scope because the current Trash-based executor cannot safely uninstall them.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupPathPolicy.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupPlanner.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupScanner.swift`
  - `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`
  - `CleanMac/Models/CleanMacModels.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - Loop documentation files
- Allowed commands:
  - read-only source and local path-name inspection;
  - localization plist lint and RU/EN key parity;
  - `swift test --package-path CleanMacCore`;
  - Debug `xcodebuild`;
  - `./script/build_and_run.sh --verify`;
  - `git diff --check`.
- Out of scope:
  - scanning an entire `.codex`, `.claude`, Cursor, or VS Code data root;
  - settings, extensions, projects, sessions, history, memories, backups, or workspace storage;
  - deleting or moving real developer data during verification;
  - system-managed Simulator runtime removal from `/Library`;
  - new dependencies, privileged helpers, signing, packaging, or release changes.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Package-manager caches include exact Homebrew, pip, Cargo registry cache/source, and Gradle cache roots.
  - Cursor and VS Code include only exact Electron/cache roots and never `User`, extensions, workspace storage, or backups.
  - Codex and Claude include only exact cache/temp roots and never projects, sessions, history, shell snapshots, or memories.
  - Xcode DeviceSupport and Previews appear as separate categories.
  - Simulator review includes only direct user Device/runtime entries at least 180 days old; recent entries are excluded.
  - Xcode Archives lists `.xcarchive` bundles as review items, is not selected by default, and never becomes a safe result.
  - All accepted cleanup paths still pass the category allowlist and root items remain rejected.
- Required verification:
  - focused exact-root, forbidden-path, risk, age, and planner tests;
  - `swift test --package-path CleanMacCore`;
  - localization lint and RU/EN key parity;
  - Debug `xcodebuild`;
  - `./script/build_and_run.sh --verify`;
  - `git diff --check`.
- Manual checks:
  - Review Scan in Russian and confirm all new categories fit and explain their scope.
  - Confirm Xcode Archives is unchecked in a fresh default selection and shows the review badge.
  - Do not start cleanup or change user files.

## Result

- Status: complete
- Verification result: passed — 32 core tests, localization lint/key parity, Debug build, signed launch verification, live Russian Scan review, and clean diff checks.
- Notes: implementation intentionally uses narrower roots than MacSai where a neighboring directory may contain user state. The live window confirmed Archives and Simulator are review-only and disabled; existing saved selections were preserved. No scan or cleanup was started.
