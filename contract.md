# Contract

## Task

- ID: TASK-017
- Title: Supplied broom icon restore
- Mode: continue

## Planner Notes

- Why this task now: the user rejected the previous thin minimal icon and supplied the exact broom artwork to use.
- Expected value: make CleanMac visually consistent across Dock, menu bar, in-app brand surfaces, design assets, and docs with the supplied artwork.
- Main risk: macOS can keep the old Dock icon in LaunchServices/Dock caches after a rebuild.
- UX constraint: keep the same supplied image everywhere; do not template-tint the menu bar asset because that collapses the detailed icon into a thin monochrome shape.

## Builder Scope

- Allowed files:
  - `CleanMac/Assets.xcassets/**`
  - `Design/**`
  - `docs/assets/**`
  - `project-analysis.md`
  - `roadmap.md`
  - `contract.md`
  - `progress.md`
  - `trace.md`
- Allowed commands:
  - `./script/build_and_run.sh --verify`
  - image dimension/JSON validation commands
  - read-only inspection commands
  - LaunchServices registration refresh and `killall Dock`
- Out of scope:
  - changing app behavior;
  - changing bundle identifier/signing/release workflows;
  - adding third-party dependencies.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - AppIcon, BrandIcon, MenuBarIcon, `Design/`, and `docs/assets` use the supplied broom artwork.
  - MenuBarIcon is stored as an original color image at 18/36/54 px, without template rendering.
  - Retina sizes are present and valid.
  - App builds and launches with the new asset catalog.
  - LaunchServices/Dock cache is refreshed and a screenshot confirms the Dock shows the new icon.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - PNG dimension checks for updated assets
  - JSON validation for updated asset catalogs
- Manual checks:
  - Visual screenshot confirms the in-app brand icon, real menu bar icon, and Dock icon use the supplied artwork.
- Evidence to collect:
  - Build/run command exit status.
  - Visual screenshot path.
  - File list touched.

## Restart Signals

Restart or shrink the task if:
- asset catalog compilation fails;
- the menu bar icon remains unreadable after template rendering;
- the update requires new dependencies.

## Result

- Status: complete
- Verification result: Passed. Asset PNG dimensions and JSON are valid, `./script/build_and_run.sh --verify` passes, `/tmp/cleanmac-supplied-icon-preview.png` previews the supplied artwork at app/menu sizes, and `/tmp/cleanmac-icon-runtime-after-refresh.png` confirms the in-app, menu bar, and Dock icons after LaunchServices/Dock refresh.
- Notes: Pillow was not needed; icons were generated from the supplied PNG with system image tooling.
