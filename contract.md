# Contract

## Task

- ID: TASK-053
- Title: Modern scan progress and drag-to-Applications DMG
- Mode: continue

## Planner Notes

- Why this task now: performance work replaced the custom scan motion with system spinners, and local release packaging did not provide the standard macOS drag-install image.
- Expected value: every real scan surface uses one coherent modern indicator, while `dist/` contains both `CleanMac.app` and an easy-to-install `CleanMac.dmg`.
- Main risk: restoring frame-driven animation could reintroduce the previous high-CPU layout loop; DMG staging inside the Desktop-backed repository can also inherit File Provider metadata and invalidate the app signature.
- Safety choice: use isolated state-driven layer animations with Reduce Motion support and no `TimelineView`; build the DMG from a sanitized `/private/tmp` staging copy and verify a fresh mounted image.

## Builder Scope

- Allowed files:
  - scan progress views and their call sites;
  - `script/package_release.sh`;
  - CI and Release workflows;
  - release documentation and Loop documentation.
- Allowed commands:
  - source and history inspection;
  - Debug and Release builds;
  - full SwiftPM tests;
  - localization lint and key parity checks;
  - app launch verification;
  - DMG creation, read-only mount, signature and checksum checks;
  - git diff checks and approved GitHub publication.
- Out of scope:
  - starting destructive cleanup, application removal, Shredder, RAM purge, or DNS flush;
  - Developer ID signing or notarization without credentials;
  - changing scanner rules, results, or deletion behavior;
  - changing repository visibility without confirmation.
- Dependencies allowed: none
- Destructive actions allowed: replacing generated ignored `dist/` artifacts only

## Evaluator Checklist

- Done criteria:
  - standard cleanup scan, Disk Analysis, Duplicate Finder, and Applications scanning use the shared modern indicator;
  - the old gray system spinner is absent from those scan surfaces;
  - motion stops or becomes static when Reduce Motion is enabled;
  - scan progress does not use `TimelineView` or invalidate the whole page on a display-frame schedule;
  - `dist/CleanMac.dmg` sits beside `dist/CleanMac.app`;
  - the mounted DMG contains `CleanMac.app` and an `Applications -> /Applications` shortcut;
  - the app inside the mounted DMG passes strict signature verification;
  - DMG and ZIP checksums validate;
  - GitHub CI and tag Release workflows include the DMG artifact.
- Required verification:
  - `bash -n script/package_release.sh`;
  - `swift test --package-path CleanMacCore`;
  - localization plist lint and RU/EN key parity;
  - `./script/build_and_run.sh --verify`;
  - `./script/package_release.sh`;
  - `zsh -lc 'cd dist && shasum -a 256 -c *.sha256'`;
  - read-only DMG mount, shortcut inspection, and strict `codesign` verification;
  - `git diff --check`.
- Manual checks:
  - review at least one active scan surface without accepting cleanup or removal actions;
  - do not execute RAM/DNS maintenance during verification.

## Result

- Status: complete
- Verification result: passed. The Debug and Release app builds succeeded; all 48 SwiftPM tests passed; localization lint and RU/EN parity passed; launch verification passed; packaging produced and verified the app, DMG, ZIP, and both checksums; live standard scan and Disk Analysis showed the modern indicator; the read-only analysis was cancelled; source checks found no scan-progress `TimelineView`; `git diff --check` passed.
- Notes: the brief CPU sample had one scan-worker spike, then settled near 11% while analysis remained active, rather than sustaining the old 111–124% layout baseline. No cleanup, application removal, Shredder action, RAM purge, or DNS flush ran.
