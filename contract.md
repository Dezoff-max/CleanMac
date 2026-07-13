# Contract

## Task

- ID: TASK-056
- Title: Real Smart Shredder destruction animation
- Mode: continue

## Planner Notes

- Why this task now: Smart Shredder performed the irreversible operation correctly but showed no trustworthy visual relationship between the selected file, overwrite progress, final unlink, and outcome.
- Expected value: the user sees a real Quick Look preview enter the mechanism, split into strips, fall into the bin, and reach success only when the secure core has actually removed the file.
- Main risk: a decorative timer could reach 100% or show success before the descriptor-based operation finishes, masking an I/O or unlink failure.
- Safety choice: emit progress from the real overwrite loop, reserve completion for the post-unlink event, keep failed files queued, generate the preview before mutation, support Reduce Motion, and exercise destructive UI verification only on disposable files created under `/private/tmp`.

## Builder Scope

- Allowed files:
  - `CleanMacCore/Sources/CleanMacCore/SecureFileShredder.swift`;
  - `CleanMacCore/Tests/CleanMacCoreTests/SecureFileShredderTests.swift`;
  - `CleanMac/Views/ShredderView.swift`;
  - `CleanMac/Views/ShredderAnimationView.swift`;
  - `CleanMac/en.lproj/Localizable.strings`;
  - `CleanMac/ru.lproj/Localizable.strings`;
  - Loop documentation.
- Allowed commands:
  - focused and full SwiftPM tests;
  - localization lint and key-parity checks;
  - Debug and Release builds, app launch, and live visual verification;
  - release packaging, checksums, and git checks;
  - approved commit and GitHub PR update.
- Out of scope:
  - adding drag and drop or sound effects;
  - adding extra overwrite passes or claiming guaranteed SSD/APFS physical erasure;
  - changing the existing review and typed-confirmation safety boundary;
  - cleanup, application removal, RAM, or DNS execution.
- Dependencies allowed: none
- Destructive actions allowed: secure removal only of disposable SwiftPM fixtures and agent-created `/private/tmp/CleanMac-Shredder-*-Test.png` copies; replacing generated ignored `dist/` artifacts

## Evaluator Checklist

- Done criteria:
  - the animation uses a real Quick Look thumbnail with an `NSWorkspace` fallback;
  - the preview feeds into the mechanism and becomes 20 independently animated strips;
  - overwrite progress comes from actual completed bytes, not a standalone timer;
  - finalizing remains below 100%, and green success appears only after `unlink` completes;
  - a failure never emits `complete`, remains visibly failed, and leaves the file queued;
  - the focused operation view fits the standard window with the stage and progress footer visible;
  - Reduce Motion removes large fall/rotation motion while preserving readable state changes;
  - RU and EN contain the same localized animation states.
- Required verification:
  - `swift test --package-path CleanMacCore --filter SecureFileShredderTests`;
  - `swift test --package-path CleanMacCore`;
  - localization plist lint and RU/EN key parity;
  - `./script/build_and_run.sh --verify`;
  - live focused animation screenshots against disposable files;
  - `./script/package_release.sh`;
  - `zsh -lc 'cd dist && shasum -a 256 -c *.sha256'`;
  - `git diff --check`.
- Manual checks:
  - never select or remove a real user file;
  - confirm the disposable file exists before the run and is absent only after the green success phase;
  - do not accept cleanup, application-removal, RAM, or DNS actions during visual verification.

## Result

- Status: complete
- Verification result: passed. Five focused Shredder tests and all 51 core tests pass; Debug and Release builds succeed; RU/EN parity is 657 keys; live disposable-file runs showed feed, strip fall, real 98% finalizing, and post-unlink 100% success with the entire scene visible; DMG/ZIP packaging and checksums pass.
- Notes: destructive verification touched only temporary copies created for this task. No real user file, cleanup target, installed app, RAM state, DNS cache, permission, or system setting was changed. The known CoreSimulator version warning remains unrelated and non-blocking.
