# Contract

## Task

- ID: TASK-054
- Title: Safe stale Codex runtime review and native Applications icon
- Mode: continue

## Planner Notes

- Why this task now: Disk Analysis correctly measured several gigabytes under `~/.cache`, but the standard cleanup scan did not include stale Codex runtime installer folders, and the Applications sidebar row needed an immediately recognizable icon.
- Expected value: users can review and reclaim stale Codex installer runtimes without risking the active runtime, while Applications uses the real system App Store artwork at Retina quality.
- Main risk: a broad `~/.cache` rule could remove active Codex components, and an unavailable SF Symbol can render as a blank or misleading sidebar icon.
- Safety choice: allow only old direct children named `codex-runtime-install-[A-Za-z0-9]+`, protect `codex-primary-runtime`, revalidate immediately before Trash, keep results review-only and unselected, and load the installed App Store icon through `NSWorkspace` with a system-symbol fallback.

## Builder Scope

- Allowed files:
  - cleanup models, path policy, scanner, planner, and focused core tests;
  - scan-area preferences, Results warnings and confirmations, sidebar icon rendering;
  - English/Russian localization and Loop documentation.
- Allowed commands:
  - source and history inspection;
  - read-only measurement of `~/.cache/codex-runtimes`;
  - Debug and Release builds;
  - full SwiftPM tests;
  - localization lint and key parity checks;
  - app launch and visual verification;
  - release packaging, checksum, signature, and DMG checks;
  - git diff checks and approved GitHub publication.
- Out of scope:
  - moving or deleting any real runtime during verification;
  - scanning arbitrary contents of `~/.cache`;
  - deleting `codex-primary-runtime`, recent installers, symlinks, nested paths, or malformed names;
  - Developer ID signing or notarization without credentials.
- Dependencies allowed: none
- Destructive actions allowed: replacing generated ignored `dist/` artifacts only

## Evaluator Checklist

- Done criteria:
  - only exact direct `codex-runtime-install-[A-Za-z0-9]+` directories older than seven days are reported;
  - `codex-primary-runtime`, recent installers, nested paths, malformed names, and symlinks are excluded;
  - planner repeats name, root, type, symlink, and age checks immediately before execution;
  - stale runtime results use review risk, start unselected, remain locked by Safe Mode, and require a dedicated confirmation before moving to Trash;
  - runtime package contents are measured accurately within the dedicated 100,000-descendant safety cap;
  - existing saved scan selections receive the new area through a one-time schema migration without overriding an explicitly empty selection;
  - the Applications sidebar row uses the installed system App Store Retina icon, with a visible fallback when App Store is unavailable;
  - English and Russian localizations remain in parity.
- Required verification:
  - `swift test --package-path CleanMacCore`;
  - localization plist lint and RU/EN key parity;
  - read-only scanner probe against the current user's Codex runtime cache;
  - `./script/build_and_run.sh --verify`;
  - live selected and unselected Applications sidebar review;
  - `./script/package_release.sh`;
  - `zsh -lc 'cd dist && shasum -a 256 -c *.sha256'`;
  - `git diff --check`.
- Manual checks:
  - never accept cleanup, application-removal, RAM, DNS, or Shredder confirmation during verification;
  - dismiss any macOS privacy prompt without changing consent unless the user explicitly requests it.

## Result

- Status: complete
- Verification result: passed. All 50 SwiftPM tests passed; localization plist lint and RU/EN key parity passed; Debug build and launch verification passed; the real read-only probe found two exact stale installer runtimes totaling 1,772,158,976 bytes while excluding `codex-primary-runtime`; the actual system App Store icon rendered in selected and unselected sidebar states; release packaging produced and verified the app, DMG, ZIP, and checksums; `git diff --check` passed.
- Notes: no runtime or user file was moved or deleted. The Applications review triggered a macOS privacy prompt, which was closed without choosing Allow or Deny. The known CoreSimulator version warning remains unrelated and non-blocking.
