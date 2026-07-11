# Contract

## Task

- ID: TASK-031
- Title: Safe application uninstaller
- Mode: continue

## Planner Notes

- Why this task now: the user explicitly requested application removal after the cleanup audit and confirmed the destructive scope.
- Expected value: CleanMac can find third-party apps and move a deliberately selected app plus exact bundle-ID leftovers to Trash after review.
- Main risk: deleting shared or personal application data, system apps, symlinks, or leftovers after the application move itself failed.
- UX constraint: application removal is a separate review flow with mandatory confirmation; the general cleanup confirmation setting cannot bypass it.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/**`
  - `CleanMacCore/Tests/CleanMacCoreTests/**`
  - `CleanMac/Models/CleanMacModels.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `CleanMac/Views/ApplicationsView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `verification.md`
- Allowed commands:
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `swift test --package-path CleanMacCore`
  - `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
  - non-destructive UI inspection and screenshots
- Out of scope:
  - `/System/Applications`, Apple bundle identifiers, CleanMac itself, nested apps, and symbolic links;
  - `Application Support`, `Containers`, `Group Containers`, documents, projects, or shared data;
  - permanent deletion, Empty Trash, privilege escalation, helper tools, or forced process termination;
  - removing a real installed app during automated or manual verification;
  - broad cleanup, Settings, Permissions, packaging, or release changes.
- Dependencies allowed: no
- Destructive actions allowed: yes, only after explicit in-app confirmation and only by moving a user-selected validated target to Trash.

## Evaluator Checklist

- Done criteria:
  - A separate Applications section scans direct `.app` children of `/Applications` and `~/Applications` without modifying them.
  - Apple apps, CleanMac itself, nested bundles, and symbolic links are excluded.
  - Only exact existing bundle-ID leftovers are offered: user Caches, Preferences plist, Saved Application State, and Logs.
  - The user selects one app and individually reviews leftovers before removal.
  - Removal always requires a dedicated confirmation and moves the app to Trash before attempting selected leftovers.
  - If the app move fails, no leftover is touched.
  - Every path is revalidated immediately before execution.
  - Success and failure states are visible and the list refreshes after a successful app move.
- Required verification:
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `swift test --package-path CleanMacCore`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- Manual checks:
  - Open Applications and inspect the read-only list without confirming removal.
  - Confirm Apple apps and CleanMac do not appear.
  - Confirm the standard window shows the list/detail/confirmation copy in Russian without clipping.
- Evidence to collect:
  - Build/test command exit status.
  - Unit tests using temporary fake `.app` fixtures and an injected Trash handler.
  - UI screenshot path if captured.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- macOS requires a privileged helper to move an app;
- exact leftovers cannot be derived from the selected bundle identifier;
- validation would require accessing or deleting a real installed application;
- the UI requires a new global state manager.

## Result

- Status: complete
- Verification result: passed. All 15 `CleanMacCore` tests, localization lint, `git diff --check`, Debug build, and `./script/build_and_run.sh --verify` pass. The live Russian Applications screen and mandatory confirmation were inspected without performing removal.
- Notes: screenshot saved at `/tmp/cleanmac-task31-applications.jpg`. Automated removal tests use only temporary fake `.app` fixtures and injected Trash handlers. No installed application or real leftover was moved.
