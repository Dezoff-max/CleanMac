# Contract

## Task

- ID: TASK-046
- Title: Smart irreversible file shredder
- Mode: continue

## Planner Notes

- Why this task now: the user explicitly requested a separate hacker-style tool for deleting selected files without the Trash or CleanMac restore path.
- Expected value: a deliberately isolated destructive workflow with review, clear limitations, strong confirmation, and fail-closed path validation.
- Main risk: per-file overwrite cannot guarantee physical media erasure on SSD/APFS because copy-on-write, clones, snapshots, asynchronous TRIM, and flash wear leveling may preserve older blocks.
- Safety choice: describe the operation as best-effort irreversible direct deletion; accept only explicitly selected regular files; reject directories, symlinks, hard links, packages, protected system roots, and files changed after review; use descriptor-based overwrite plus identity revalidation and direct unlink.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/SecureFileShredder.swift`;
  - focused `CleanMacCore` tests;
  - `CleanMac/Models/CleanMacModels.swift`;
  - `CleanMac/Support/ShredderWorkspaceService.swift`;
  - `CleanMac/Views/ShredderView.swift`;
  - `CleanMac/Views/MainWindowView.swift`;
  - RU/EN localization;
  - `README.md`;
  - Loop documentation files.
- Allowed commands:
  - source inspection;
  - direct deletion only inside disposable test fixture directories;
  - `swift test --package-path CleanMacCore`;
  - Debug build and `./script/build_and_run.sh --verify`;
  - localization and Git diff checks;
  - non-destructive UI review up to, but not accepting, the final destructive confirmation.
- Out of scope:
  - deleting any real user file during verification, directories, application bundles, privileged/system files, background shredding, scheduled shredding, dependencies, release/version/package changes, signing, or publication.
- Dependencies allowed: none
- Destructive actions allowed: disposable test fixtures only

## Evaluator Checklist

- Done criteria:
  - Shredder is a separate sidebar destination and does not reuse normal cleanup, Trash, restore, or scheduled scan flows.
  - Review accepts only explicitly selected regular files and records device/inode/size/mtime identity.
  - Execution opens without following symlinks, verifies the same single-link regular file, overwrites through the file descriptor, syncs, truncates, revalidates identity, and unlinks directly.
  - Protected roots, directories, symlinks, hard links, packages, and changed/replaced files fail closed.
  - Final action requires both an acknowledgement and an exact typed phrase; no cancellation is offered after execution starts.
  - UI clearly states that SSD/APFS physical recovery cannot be guaranteed and recommends FileVault for future protection.
  - Neo-glow styling is concentrated on armed/danger states and supports both app appearances.
- Required verification:
  - focused shredder tests and full `swift test --package-path CleanMacCore`;
  - localization lint/key parity;
  - Debug build and signed launch verification;
  - live RU/EN layout and confirmation review without accepting deletion;
  - `git diff --check`.
- Manual checks:
  - Never select or delete a real user file during automated verification.
  - Confirm normal cleanup and restore behavior remain unchanged.

## Result

- Status: complete
- Verification result: focused shredder tests 4/4; full `CleanMacCore` suite 47/47; EN/RU localization lint and 583-key parity; Debug build, ad-hoc signature, and launch verification; live EN/light and RU/dark UI review; exact-phrase gating review; `git diff --check`.
- Notes: The production path was not exercised against a real user file. Only disposable SwiftPM fixtures were shredded; the UI fixture was preserved. Apple documents that secure erase options are unavailable for SSDs, so the UI explicitly describes this as best-effort direct deletion rather than guaranteed physical-media erasure.
