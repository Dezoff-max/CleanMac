# Contract

## Task

- ID: TASK-055
- Title: Monochrome Retina Applications sidebar icon
- Mode: continue

## Planner Notes

- Why this task now: loading the full App Store application icon made Applications the only colored sidebar row, while loading the complete Finder `.icns` as one SwiftUI image composited several bitmap representations and produced a striped mark.
- Expected value: Applications remains immediately recognizable while following the same monochrome selected, unselected, hover, and focus behavior as every other sidebar icon.
- Main risk: multi-representation `.icns` rendering can stack variants, and an unavailable private resource could leave the row blank.
- Safety choice: use Finder's system `SidebarApplicationsFolder.icns`, extract exactly its 36-pixel Retina representation into one 18-point template image, tint it with the existing sidebar state color, and retain a monochrome SF Symbol fallback.

## Builder Scope

- Allowed files:
  - `CleanMac/Views/SidebarView.swift`;
  - Loop documentation.
- Allowed commands:
  - inspect system icon representations;
  - Debug and Release builds;
  - app launch and selected/unselected visual verification;
  - full core tests, release packaging, checksums, and git checks;
  - approved commit and GitHub PR update.
- Out of scope:
  - changing navigation behavior or labels;
  - copying Apple icon assets into the repository;
  - cleanup, application removal, Shredder, RAM, or DNS execution.
- Dependencies allowed: none
- Destructive actions allowed: replacing generated ignored `dist/` artifacts only

## Evaluator Checklist

- Done criteria:
  - Applications is not colored when unselected;
  - the icon is the recognizable macOS Applications/App Store mark rather than a generic letter or improvised drawing;
  - one Retina bitmap representation is rendered, with no stacked or striped variants;
  - unselected state uses the same monochrome icon color as peer rows;
  - selected state uses the same white icon color as peer rows;
  - missing system resource falls back to a visible monochrome SF Symbol;
  - no binary Apple asset is committed.
- Required verification:
  - `./script/build_and_run.sh --verify`;
  - selected and unselected live sidebar screenshots;
  - `swift test --package-path CleanMacCore`;
  - `./script/package_release.sh`;
  - `zsh -lc 'cd dist && shasum -a 256 -c *.sha256'`;
  - `git diff --check`.
- Manual checks:
  - do not accept cleanup, application-removal, Shredder, RAM, or DNS actions during visual verification.

## Result

- Status: complete
- Verification result: passed. The Debug app built, signed, and launched; the unselected Applications row showed one crisp gray system mark and the selected row showed the same mark in white; the icon no longer contains color or stacked `.icns` representations; core tests, release package, checksums, and git checks passed.
- Notes: the icon is loaded from the local macOS system at runtime, so no Apple binary artwork was added to the repository. The known CoreSimulator version warning remains unrelated and non-blocking.
