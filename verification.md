# Verification

## Package Manager

- Detected package manager: SwiftPM for `CleanMacCore`; Xcode project for the macOS app.
- Detection source: `CleanMacCore/Package.swift`, `CleanMac.xcodeproj`, `script/*.sh`.

## Commands

- Install: none required.
- Run/dev: `./script/build_and_run.sh`
- Verify launch: `./script/build_and_run.sh --verify`
- Build: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
- Test: `swift test --package-path CleanMacCore`
- Package: `./script/package_release.sh`
- Lint/typecheck: no dedicated lint command found.

## Manual Checklist

- `contract.md` defines done criteria and allowed files before implementation.
- Relevant files were inspected before editing.
- The smallest useful change was made.
- Existing user work was preserved.
- No secrets were copied or logged.
- No destructive cleanup behavior was introduced unless explicitly requested.
- Documentation was updated when behavior changed.
- `progress.md` was updated after verification.
- `trace.md` was updated when verification failed or the loop restarted.

## Success Criteria

- The selected task's definition of done is met.
- The selected task's contract is satisfied.
- The relevant verification command or manual check passes.
- Any known failures are documented clearly.

## If Checks Fail

1. Read the error output.
2. Fix only failures caused by the current task.
3. Re-run the relevant check.
4. If the failure is unrelated or out of scope, document it in `progress.md` and do not mark the task complete.

## Verification Matrix

| Area | Command or check | When to run | Success signal | Fallback |
| --- | --- | --- | --- | --- |
| macOS app launch | `./script/build_and_run.sh --verify` | UI, app lifecycle, assets, or project changes | Build succeeds and `pgrep -x CleanMac` finds the app | Run the xcodebuild command from this file and inspect launch logs |
| Menu bar dashboard | Open the status item in both CleanMac appearance modes and observe at least two refreshes | Menu-bar layout, metrics, localization, appearance, or actions change | Light selection renders a light popover, dark selection renders a dark popover, live metric values remain valid, and Open focuses the main window | Inspect the accessibility tree and capture light/dark screenshots; do not trigger scan, cleanup, or removal actions |
| Settings and launch at login | Inspect `SMAppService.mainApp.status`, launch once normally and once with `open -g`, then restore through app activation and menu-bar Open | Settings navigation, permissions placement, Login Item, or app launch lifecycle changes | Permissions exists only inside Settings; system status is localized; background launch has zero main windows; activation/menu-bar Open reveals the existing window | Do not toggle Login Item during automated verification; use the current read-only status and inspect registration/error paths in code |
| First-launch onboarding | Reset only `CleanMac.onboardingCompleted`, review four pages, finish, and relaunch | Onboarding content, persistence, language, appearance, permission guidance, or launch routing changes | First launch shows Welcome in system appearance; Back/Next/Skip work; settings open only explicitly; completion switches to Dashboard; relaunch skips onboarding | Inspect the accessibility tree and screenshots, then verify the single defaults key; leave it absent for the user's next launch |
| About window | Open the app menu item, switch RU/EN and light/dark, then inspect the Window menu | About scene, metadata, localization, theme, or links change | One fixed-size About window shows the active language/theme, accurate bundle version/build, and GitHub/Releases/License links | Inspect the accessibility tree and capture a screenshot without activating external links |
| Core package | `swift test --package-path CleanMacCore` | Core model, scanner, or package changes | All tests pass | Run `cd CleanMacCore && swift test` |
| Persistent cleanup history | Temporary JSON/history fixtures, multi-window snapshots, and injected restore move handlers | History storage, migration, or restore validation changes | Round-trip/status/cap/merge tests pass; corrupt, oversized, outside-Trash, symlink, and outside-allowlist records never reach the move handler; default restore walks path components without following symlinks and performs descriptor-relative exclusive rename | Run focused `testCleanupHistory*`, `testPersistedCleanupHistory*`, and `testSecureRestoreMove*` SwiftPM tests; inspect Results without triggering cleanup |
| Application removal | Temporary fake `.app` fixtures with an injected Trash handler plus read-only UI review | Application scanner, removal policy, multi-selection, or Applications UI changes | App target is moved first; failed app move leaves leftovers untouched; outside/forged paths are rejected; multiple checkboxes and per-app leftovers stay isolated; no real app is removed | Run the focused `testApplication*` SwiftPM tests and inspect the batch confirmation without accepting it |
| Disk analysis | Temporary folder fixtures plus a read-only live source scan | Disk analyzer, map, large-file review, folder source, progress UI, hover behavior, or Finder/Open actions | Tree totals and large-file thresholds are correct; symlink traversal is skipped; cancellation works; root branches stay visible after the deep-node cap; no initial file selection or cleanup path exists; whole-disk mode starts at `/` with no path exclusions; scan progress uses the custom animation and a hovered sector enlarges with a localized GB tooltip | Run `DiskAnalyzerTests`, inspect Home/Downloads first, then use a cancellable `/` scan and confirm protected paths appear as issues rather than privilege escalation |
| Release package | `./script/package_release.sh` | Packaging, release, or CI artifact changes | `dist/*.zip` and `.sha256` are created and checksum passes | Inspect `build/XcodeData/Build/Products/Release` |
| Privacy usage and entitlements | Extract `dist/*.zip` to a temporary directory; inspect its `Info.plist` and run `codesign -d --entitlements :-` on the extracted app | Permission, hardened runtime, or Apple Events changes | Usage description is present, required entitlement values are `true`, and strict signature verification passes | Inspect `dist/CleanMac.app` immediately after clearing FinderInfo added by File Provider |
| CI | GitHub Actions run | After pushed app/build changes | Test, Debug build, and release artifact jobs are green | Inspect failing job logs and reproduce locally |
