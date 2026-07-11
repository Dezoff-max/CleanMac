# Trace

Append-only trace of failures, restarts, and judgment divergences.

## 2026-07-09 - TASK-018 - Background under sidebar

- Symptom: the first main-window background implementation used a root detail `ZStack`, and visual QA showed detail content bleeding under the native sidebar.
- Cause: the custom root background changed how the translucent `NavigationSplitView` sidebar composited with detail content.
- Fix: moved the background into the shared `PageContainer`, so each page owns its content background while the split view keeps native sidebar behavior.
- Status: resolved; `/tmp/cleanmac-background-settings.png` shows Settings with the background and clean sidebar.

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

## 2026-07-11 - TASK-030 - Debug Automation signing

- Symptom: the first ad-hoc Debug signing pass rejected Finder metadata; after sanitizing the bundle, the app still terminated at launch because hardened runtime blocked `CleanMac.debug.dylib` for having no shared Team ID with the ad-hoc main executable.
- Cause: Xcode's Debug product uses separate preview/debug dynamic libraries, while ad-hoc signatures have no stable Team ID for hardened library validation. The raw build bundle also retained extended attributes that codesign refuses.
- Fix: sanitize only the generated bundle, build Debug with `ENABLE_DEBUG_DYLIB=NO` so it has one executable, then sign the app ad-hoc with hardened runtime and the Automation entitlement. Release remains hardened and is signed in two passes so only the outer app receives the Automation entitlement. Because File Provider can reattach Finder metadata to `dist/CleanMac.app`, packaging now strictly verifies a fresh extraction of the metadata-free ZIP.
- Status: resolved; `./script/build_and_run.sh --verify` launches successfully with `adhoc,runtime`, and the extracted Release ZIP passes strict signature, usage-description, and entitlement inspection.

## 2026-07-11 - TASK-033 - Invisible About metadata rows

- Symptom: the first custom About layout exposed all metadata to accessibility, but the four custom `HStack` rows rendered as empty bands in the live light and dark windows.
- Cause: the bespoke label/value row did not receive a stable native macOS layout under the fixed auxiliary window, even after contrast and height adjustments.
- Fix: replaced the custom row layout with native `LabeledContent`, kept the compact fixed-size scene, and rechecked both languages and appearances in the running app.
- Status: resolved; the live Russian/light and English/dark passes rendered every remaining metadata value before the user simplified the final card to Developer and License only.
