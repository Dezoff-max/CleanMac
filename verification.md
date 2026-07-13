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
| Low disk space warning | Core threshold/cooldown fixtures plus a read-only main-window route check | Disk capacity policy, status monitor, notification delivery, menu warning, or requested-section routing changes | Exactly 10% stays normal; below 10% warns; successful notifications are limited to once per 24 hours; the menu action selects Disk Analysis without starting a scan | Run `LowDiskSpaceWarningPolicyTests`; on a normal disk confirm the warning stays hidden; exercise the requested-section route without changing notification permission or faking user disk capacity |
| Settings and launch at login | Inspect `SMAppService.mainApp.status`, launch once normally and once with `open -g`, then restore through app activation and menu-bar Open | Settings navigation, permissions placement, Login Item, or app launch lifecycle changes | Permissions exists only inside Settings; system status is localized; background launch has zero main windows; activation/menu-bar Open reveals the existing window | Do not toggle Login Item during automated verification; use the current read-only status and inspect registration/error paths in code |
| First-launch onboarding | Reset only `CleanMac.onboardingCompleted`, review four pages, finish, and relaunch | Onboarding content, persistence, language, appearance, permission guidance, or launch routing changes | First launch shows Welcome in system appearance; Back/Next/Skip work; settings open only explicitly; completion switches to Dashboard; relaunch skips onboarding | Inspect the accessibility tree and screenshots, then verify the single defaults key; leave it absent for the user's next launch |
| About window | Open the app menu item, switch RU/EN and light/dark, then inspect the Window menu | About scene, metadata, localization, theme, or links change | One fixed-size About window shows the active language/theme, accurate bundle version/build, and GitHub/Releases/License links | Inspect the accessibility tree and capture a screenshot without activating external links |
| Core package | `swift test --package-path CleanMacCore` | Core model, scanner, or package changes | All tests pass | Run `cd CleanMacCore && swift test` |
| Developer cleanup | Exact-root temporary fixtures plus read-only Scan review | Developer package, IDE, AI-tool, Xcode, Simulator, or Archive categories change | Only listed cache/temp roots produce results; settings/extensions/projects/sessions/history/memory stay excluded; recent Simulator data is skipped; Archives remain review-only and non-default | Run focused `testDeveloper*`, `testScannerFindsDeveloper*`, and `testXcodeDeveloperStorage*` tests; inspect Scan without starting cleanup |
| Stale Codex installer runtimes | Exact temporary fixtures plus a real read-only `~/.cache/codex-runtimes` probe | Codex runtime cleanup category, path policy, result confirmation, or selected-area migration changes | Only direct exact `codex-runtime-install-[A-Za-z0-9]+` directories older than seven days appear; `codex-primary-runtime`, recent, nested, malformed, and symlink paths stay excluded; results are review-only and unselected; planner revalidation accepts only unchanged eligible directories | Run focused stale-runtime scanner/planner tests, confirm the real probe size without executing cleanup, and inspect Results with Safe Mode enabled |
| Persistent cleanup history | Temporary JSON/history fixtures, multi-window snapshots, and injected restore move handlers | History storage, migration, or restore validation changes | Round-trip/status/cap/merge tests pass; corrupt, oversized, outside-Trash, symlink, and outside-allowlist records never reach the move handler; default restore walks path components without following symlinks and performs descriptor-relative exclusive rename | Run focused `testCleanupHistory*`, `testPersistedCleanupHistory*`, and `testSecureRestoreMove*` SwiftPM tests; inspect Results without triggering cleanup |
| Application removal | Temporary fake `.app` fixtures with injected Trash/permanent handlers plus read-only UI review | Application scanner, removal policy, multi-selection, removal mode, or Applications UI changes | Trash mode remains default; permanent mode bypasses Trash only after explicit selection; app target is removed first; failed app removal leaves leftovers untouched; outside/forged paths are rejected; multiple checkboxes and per-app leftovers stay isolated; no real app is removed | Run the focused `testApplication*` SwiftPM tests and inspect the batch/permanent confirmation without accepting it |
| System maintenance | Command existence checks plus read-only UI/build review | RAM purge, DNS cache flush, System section navigation, administrator authorization, command status UI, or memory result metrics change | Buttons are explicit-only; commands use fixed absolute scripts through the macOS administrator prompt; memory shows live and before/after read-only VM stats; UI has running/success/partial/failure/unavailable states; app builds and launches without executing the maintenance actions | Confirm `/usr/sbin/purge`, `/usr/bin/dscacheutil`, `/usr/bin/killall`, and `/usr/bin/osascript` exist; inspect the memory gauge without clicking RAM/DNS buttons unless the user explicitly asks to run them |
| Disk analysis | Temporary folder fixtures plus a read-only live source scan | Disk analyzer, map, large-file review, folder source, progress UI, hover behavior, or Finder/Open actions | Tree totals and large-file thresholds are correct; symlink traversal is skipped; cancellation works; root branches stay visible after the deep-node cap; no initial file selection or cleanup path exists; whole-disk mode starts at `/` with no path exclusions; the shared modern scan indicator remains responsive and Reduce Motion-aware without frame-driven page invalidation; a hovered sector enlarges with a localized GB tooltip | Run `DiskAnalyzerTests`, inspect Home/Downloads first, then use a cancellable `/` scan and confirm protected paths appear as issues rather than privilege escalation |
| Scan thermal load | Repeated `ps` samples plus an 8-second `sample` capture during the same Home Disk Analysis source | Progress visuals, progress stream buffering, or long scan task priority changes | CleanMac stays materially below the 111–124% CPU baseline; the main thread does not continuously relayout; modern progress motion is isolated to small layers; the worker reports utility QoS; progress and Cancel remain functional | Confirm no `TimelineView` remains in scan progress views, then compare stack samples and stop the read-only analysis |
| Duplicate finder | Temporary exact-content, hard-link, changed-file, outside-root, and large-file fixtures plus a read-only live UI review | Duplicate pipeline, grouping, selection, slow mode, or Trash planning/execution changes | Only size and partial-hash survivors receive a full SHA-256; hashing concurrency stays bounded; hard links do not inflate savings; one original is unselectable; copies start unselected; standard mode reports files over 500 MiB and slow mode includes them; only unchanged validated copies reach the injected Trash handler | Run `DuplicateFinderTests`; inspect the Russian duplicate screen without scanning or moving real user files; never accept a cleanup confirmation during automated review |
| Smart Shredder | Disposable regular-file fixtures plus EN/RU, light/dark, and Reduce Motion UI review | Shredder validation, overwrite/unlink execution, real progress, destruction animation, confirmation gating, navigation, limitations copy, or neo-glow styling changes | Only unchanged single-link regular files pass review; unsafe or replaced files fail closed; both acknowledgement and exact phrase are required; actual completed bytes drive progress; Quick Look preview feeds into 20 strips; finalizing stays below 100%; failed removal never emits complete or leaves the queue; green success appears only after unlink; the focused scene fits the standard window; the UI never promises guaranteed SSD/APFS physical erasure | Run `SecureFileShredderTests` and the full core suite; exercise the final action only against a disposable file created under `/private/tmp`, confirm it exists before the run and is absent after success, and never select a real user file |
| Release package | `./script/package_release.sh` | Packaging, release, or CI artifact changes | `dist/CleanMac.app`, `dist/CleanMac.dmg`, fallback ZIP, and both `.sha256` files are created; a read-only mounted DMG contains the app plus `Applications -> /Applications`; mounted app signature and checksums pass | Inspect `build/XcodeData/Build/Products/Release`, then mount the DMG under `/private/tmp` and validate its contents |
| Privacy usage and entitlements | Extract `dist/*.zip` to a temporary directory; inspect its `Info.plist` and run `codesign -d --entitlements :-` on the extracted app | Permission, hardened runtime, or Apple Events changes | Usage description is present, required entitlement values are `true`, and strict signature verification passes | Inspect `dist/CleanMac.app` immediately after clearing FinderInfo added by File Provider |
| CI | GitHub Actions run | After pushed app/build changes | Test, Debug build, and release artifact jobs are green | Inspect failing job logs and reproduce locally |
