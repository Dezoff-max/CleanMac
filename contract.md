# Contract

## Task

- ID: TASK-040
- Title: Safe duplicate finder
- Mode: continue

## Planner Notes

- Why this task now: Disk Analysis explains space usage, while duplicate detection can identify exact redundant personal files without mixing them into junk totals.
- Expected value: a separate review workspace finds byte-identical files efficiently and always preserves one protected original.
- Main risk: hashing large folders is expensive, files can change between scan and cleanup, hard links are not real duplicate storage, and broad deletion must never follow from an automatic selection.
- UX constraint: Home, Downloads, or one explicit custom folder; no whole-disk default; no automatic selection; one visibly protected original per group; confirmation before Trash.
- Performance assumption: standard mode defers size-matched files over 500 MiB and lists them in the report; slow mode hashes them with at most two concurrent hashing operations.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/DuplicateFinder.swift`
  - `CleanMacCore/Sources/CleanMacCore/DuplicateCleanup.swift`
  - `CleanMacCore/Tests/CleanMacCoreTests/DuplicateFinderTests.swift`
  - `CleanMac/Models/CleanMacModels.swift`
  - `CleanMac/Support/DuplicateWorkspaceService.swift`
  - `CleanMac/Views/DuplicateFinderView.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - Loop documentation files
- Allowed commands:
  - read-only source and reference inspection;
  - localization plist lint and RU/EN key parity;
  - `swift test --package-path CleanMacCore`;
  - Debug `xcodebuild`;
  - `./script/build_and_run.sh --verify`;
  - temporary-fixture duplicate scans and injected Trash tests;
  - live UI review without accepting cleanup;
  - `git diff --check`.
- Out of scope:
  - automatic selection or deletion;
  - permanent deletion, secure erase, hard-link replacement, or cloud deduplication;
  - whole-disk scanning, Photos-library interpretation, package contents, or hidden-file scanning;
  - persistent duplicate history, privileged access, new dependencies, release/package changes.
- Dependencies allowed: no external dependencies; system CryptoKit only
- Destructive actions allowed: no real user files; injected temporary-fixture Trash handler only

## Evaluator Checklist

- Done criteria:
  - Files are reduced by exact logical size before any hashing.
  - Size candidates receive a first-block SHA-256; only matching partial buckets receive a full streaming SHA-256.
  - Full hashes run through a bounded scheduler with no more than two concurrent operations by default.
  - Files sharing device and inode are represented once and never create false duplicate savings.
  - Every final group exposes one deterministic protected original and one or more selectable copies.
  - Selected copy IDs are empty after scanning; the original has no selectable control.
  - Standard mode reports matching-size files over 500 MiB as deferred instead of hiding them; slow mode includes them.
  - Cleanup planning accepts only unchanged scanned copies beneath the selected root, rejects originals/unknown/outside/symlink/changed paths, and requires the original to still exist.
  - Execution uses macOS Trash only and requires an explicit UI confirmation.
  - Duplicate results never enter junk totals, normal Results, cleanup history, or scheduled scans.
- Required verification:
  - focused pipeline, partial/full separation, hard-link, slow-mode, cancellation, keeper, planner, and injected-Trash tests;
  - `swift test --package-path CleanMacCore`;
  - localization lint and RU/EN key parity;
  - Debug `xcodebuild`;
  - `./script/build_and_run.sh --verify`;
  - live Russian duplicate-screen review with no scan of real user data and no cleanup confirmation acceptance;
  - `git diff --check`.
- Manual checks:
  - Confirm the new sidebar destination, adaptive layout, source controls, slow-mode explanation, empty initial selection, Original/Copy labels, and disabled cleanup action.
  - Use only temporary fixtures for result/confirmation inspection.

## Result

- Status: complete
- Verification result: 40 SwiftPM tests passed; localization lint and RU/EN key parity passed; Debug build and signed launch verification passed; the live Russian initial screen was reviewed without scanning or moving user files; final diff checks passed.
- Notes: the implementation follows MacSai's staged matching idea but deliberately removes its 500 MiB drop and preselection behavior.
