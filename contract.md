# Contract

## Task

- ID: TASK-019
- Title: Sidebar language and appearance controls
- Mode: continue

## Planner Notes

- Why this task now: the user asked to place RU/EN language switching and light/dark theme switching at the bottom of the sidebar.
- Expected value: make language and theme changes quick without opening Settings, while preserving native macOS sidebar behavior.
- Main risk: manual localization overrides can fail to refresh visible strings, and custom sidebar footer controls can crowd the navigation list.
- UX constraint: keep the sidebar native and compact; controls must remain visible at the bottom of the sidebar.

## Builder Scope

- Allowed files:
  - `CleanMac/CleanMacApp.swift`
  - `CleanMac/Support/Localizer.swift`
  - `CleanMac/Views/SidebarView.swift`
  - `CleanMac/Views/MainWindowView.swift`
  - `CleanMac/*/Localizable.strings`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - visual screenshot commands
  - read-only inspection commands
- Out of scope:
  - changing cleanup behavior;
  - changing bundle identifier/signing/release workflows;
  - adding third-party dependencies.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Sidebar footer contains a RU/EN segmented language switcher.
  - Sidebar footer contains a light/dark appearance switcher.
  - App defaults language from the system when no override exists.
  - Selected language applies to visible app strings and formatting.
  - Selected appearance applies to the main window and menu bar popover.
  - Main window still builds, launches, and keeps the controls visible at the bottom of the sidebar.
- Required verification:
  - `plutil -lint CleanMac/en.lproj/Localizable.strings CleanMac/ru.lproj/Localizable.strings`
  - `git diff --check`
  - `./script/build_and_run.sh --verify`
  - `swift test --package-path CleanMacCore`
- Manual checks:
  - Visual screenshots confirm RU/light and EN/dark states with sidebar controls visible.
- Evidence to collect:
  - Build/test command exit status.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- sidebar controls are clipped or hidden at the bottom;
- changing language does not refresh visible strings;
- changing appearance only affects one surface;
- the update requires new dependencies.

## Result

- Status: complete
- Verification result: Passed. `plutil`, `git diff --check`, `./script/build_and_run.sh --verify`, and `swift test --package-path CleanMacCore` pass; screenshots `/tmp/cleanmac-sidebar-controls-en-dark.png` and `/tmp/cleanmac-sidebar-controls-final.png` confirm EN/dark and RU/light states.
- Notes: Language and appearance are stored through `@AppStorage`; localization lookup now uses the selected bundle while the first default language follows system preferences.
