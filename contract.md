# Contract

## Task

- ID: TASK-034
- Title: Persistent cleanup history
- Mode: continue

## Planner Notes

- Why this task now: cleanup history and restore already work, but the history is held only in SwiftUI state and disappears when CleanMac is relaunched.
- Expected value: the user can still see and safely restore a previously trashed cleanup item after restarting the app.
- Main risk: a modified or corrupt history file must never become authority to move an arbitrary file.
- UX constraint: preserve the existing Results history UI and Trash-only cleanup behavior; only its lifetime and safety validation change.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/CleanupModels.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupPlanModels.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupPathPolicy.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupRestorer.swift`
  - `CleanMacCore/Sources/CleanMacCore/CleanupHistoryStore.swift`
  - `CleanMacCore/Tests/CleanMacCoreTests/CleanMacCoreTests.swift`
  - `CleanMac/Models/CleanMacModels.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `CleanMac/Views/ResultsView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `verification.md`
- Allowed commands:
  - localization/plist lint and key-parity checks
  - `swift test --package-path CleanMacCore`
  - `./script/build_and_run.sh --verify`
  - non-destructive UI inspection and screenshots
  - focused Git/GitHub commands after verification
- Out of scope:
  - new cleanup categories, permanent deletion, application-removal history, launch at login, release/version changes, signing, or notarization;
  - adding dependencies or changing the macOS deployment target;
  - triggering cleanup or restore against real user files during verification.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - The history is stored as a versioned JSON file under `Application Support/CleanMac` using atomic replacement.
  - Only successful cleanup moves create records, and each operation gets a unique history ID even when the same original path is reused.
  - The newest 100 unique records are retained.
  - Restored and failed statuses are written back to the store.
  - Updates from multiple app windows use read-merge-write semantics and cannot downgrade a stored restored record.
  - Persistence failures remain visible in the current window and produce a localized warning instead of a false durability claim.
  - Missing or corrupt JSON loads as empty history without a crash or restore attempt.
  - A persisted record can restore only from a direct child of the configured Trash root to a strict descendant of its category allowlist; forged paths and symbolic links are rejected before the move handler runs.
  - The default move opens every parent path component with `openat(..., O_NOFOLLOW)`, pins both directory descriptors, and uses exclusive `renameatx_np`, so a raced destination cannot follow a substituted symlink or overwrite an existing item.
  - The existing history panel explains that records persist across launches.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - localization lint and RU/EN key parity
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- Manual checks:
  - Open Results and confirm the persistent-history wording fits in Russian.
  - Do not trigger real cleanup or restore.

## Restart Signals

Restart or shrink the task if:
- persisted restoration cannot be revalidated without weakening the existing allowlist;
- Swift concurrency makes file persistence block or race with cleanup state;
- a history migration would require trusting an unversioned legacy format.

## Result

- Status: complete
- Verification result: passed. All 23 core tests, localization lint/key parity, `git diff --check`, Debug build/launch, and read-only Russian Results inspection passed.
- Notes: No real cleanup or restore was triggered. The focused forged-destination test initially exposed a symlink-parent gap; canonical-parent rebuilding plus descriptor-relative exclusive rename resolved it. The known stale CoreSimulator warning remains non-blocking for macOS builds.
