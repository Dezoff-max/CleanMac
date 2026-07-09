# Contract

## Task

- ID: TASK-016
- Title: Unified minimal broom icon
- Mode: continue

## Planner Notes

- Why this task now: the user asked for a minimal Retina-readable broom icon in the menu bar, then clarified that the same icon must be used everywhere.
- Expected value: make CleanMac visually consistent across Dock, menu bar, in-app brand surfaces, design assets, and docs.
- Main risk: menu bar icons need template/tint behavior, while app/brand icons need color and readability.
- UX constraint: keep one shared broom silhouette; use template rendering for menu bar so macOS tints it correctly in light/dark menu bars.

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
- Out of scope:
  - changing app behavior;
  - changing bundle identifier/signing/release workflows;
  - adding third-party dependencies.
- Dependencies allowed: no
- Destructive actions allowed: no

## Evaluator Checklist

- Done criteria:
  - Menu bar icon is a minimal broom silhouette at 18/36/54 px and uses template rendering.
  - AppIcon, BrandIcon, `Design/`, and `docs/assets` use the same broom shape.
  - Retina sizes are present and valid.
  - App builds and launches with the new asset catalog.
- Required verification:
  - `./script/build_and_run.sh --verify`
  - PNG dimension checks for updated assets
  - JSON validation for updated asset catalogs
- Manual checks:
  - Visual screenshot confirms the menu bar icon is visible in the real menu bar.
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
- Verification result: Passed. Asset PNG dimensions and JSON are valid, `./script/build_and_run.sh --verify` passes, and `/tmp/cleanmac-menubar-icon-check.png` confirms the new menu bar icon is visible while the in-app brand icon uses the same broom shape.
- Notes: Pillow was not needed; icons were generated deterministically with AppKit/CoreGraphics.
