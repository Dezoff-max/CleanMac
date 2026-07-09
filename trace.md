# Trace

Append-only trace of failures, restarts, and judgment divergences.

## 2026-07-09 - TASK-016 - Thin icon rejected

- Symptom: the generated minimal broom looked like a thin stroke in the window/menu bar, and the Dock still appeared to show the older icon.
- Cause: the menu bar asset used template rendering and the minimal silhouette was too narrow at Retina menu bar size; Dock also needed LaunchServices/Dock cache refresh after the asset rebuild.
- Fix: restarted as TASK-017 with the user's supplied detailed broom PNG, removed menu bar template rendering, rebuilt the app, and refreshed LaunchServices/Dock registration.
- Status: resolved in TASK-017.

## 2026-07-09 - TASK-015 - Test threshold mismatch

- Symptom: `testDownloadsReviewUsesSmartRules` initially included a recent small file.
- Cause: the test used a 64-byte "large download" threshold, but APFS allocated size for tiny files is several KB.
- Fix: raised the test threshold and fixture size to model allocated-size behavior more realistically.
- Status: resolved; `swift test --package-path CleanMacCore` passes.
