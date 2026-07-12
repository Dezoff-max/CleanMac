# Contract

## Task

- ID: TASK-036
- Title: First-launch system onboarding
- Mode: continue

## Planner Notes

- Why this task now: the app has several safe cleanup and analysis workflows, but a new user is not introduced to them or to Full Disk Access.
- Expected value: the first launch explains the product, its real capabilities, the optional permission step, and the safe starting action.
- Main risk: onboarding must not appear on every launch, must not open privacy settings automatically, and must not show the main UI behind a second window.
- UX constraint: follow the supplied four-screen structure while using semantic macOS colors and the current system appearance instead of a fixed dark palette.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Support/CleanMacPreferences.swift`
  - `CleanMac/Views/OnboardingView.swift`
  - `CleanMac/en.lproj/Localizable.strings`
  - `CleanMac/ru.lproj/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
  - `verification.md`
- Allowed commands:
  - localization plist lint and RU/EN key-parity checks
  - `swift test --package-path CleanMacCore`
  - Debug `xcodebuild`
  - `./script/build_and_run.sh --verify`
  - live first-launch and relaunch UI inspection
  - read/write only the single onboarding completion preference during verification
- Out of scope:
  - requesting Full Disk Access automatically;
  - changing cleanup, scan, removal, restore, scheduling, release, signing, or GitHub behavior;
  - dependencies or a separate persistent welcome window.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - A four-step localized onboarding appears when `CleanMac.onboardingCompleted` is absent or false.
  - The screens cover welcome, only capabilities CleanMac actually has, Full Disk Access guidance, and completion.
  - The UI follows system Light/Dark appearance independently of the saved in-app appearance until onboarding completes.
  - Back, Next, Skip/Close, progress dots, and the default Return action work; Reduce Motion avoids animated movement.
  - Full Disk Access is checked read-only and System Settings opens only from the explicit button.
  - Finishing or skipping persists completion and replaces onboarding with the main UI in the same window.
  - Relaunch after completion opens the main UI directly.
- Required verification:
  - `swift test --package-path CleanMacCore`
  - localization lint and RU/EN key parity
  - Debug `xcodebuild`
  - `./script/build_and_run.sh --verify`
  - `git diff --check`
- Manual checks:
  - Reset only the onboarding preference, launch in Russian, and review all four screens in the standard window.
  - Finish onboarding, relaunch, and confirm the main window opens without onboarding.
  - Restore the unfinished preference state for the user after verification.

## Result

- Status: complete
- Verification result: automated checks, live four-step review, completion, skip, and relaunch checks passed.
- Notes: the onboarding was left unfinished and visible for the user's next launch. Full Disk Access was checked read-only; System Settings was not opened during verification.
