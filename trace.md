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

## 2026-07-12 - TASK-034 - Symlinked restore parent

- Symptom: the first forged-destination test reached the injected move handler when the missing destination's parent was a symlink from an allowed cache root to an outside folder.
- Cause: resolving symlinks on the complete destination URL did not reliably resolve an existing symlink ancestor when the final destination did not exist.
- Fix: require the original parent to exist as a directory, canonicalize that parent first, append only the final path component, and then enforce the category allowlist on the rebuilt destination.
- Status: resolved; the focused regression and all 23 `CleanMacCore` tests pass, and the forged destination never reaches the move handler.

## 2026-07-12 - TASK-034 - Independent persistence and restore review

- Symptom: independent review found that separate `WindowGroup` snapshots could overwrite newer history, failed saves were suppressed, and string validation still left a narrow validation-to-move race.
- Cause: each window saved its complete local array with `try?`, while the default restore ended in path-based `FileManager.moveItem` after canonical checks.
- Fix: history writes now read, merge, and atomically replace records while preserving terminal restored state; the UI reports write failures; the production move walks every source/destination directory component through `openat(..., O_NOFOLLOW)`, pins the resulting descriptors, and uses `renameatx_np(RENAME_EXCL)`.
- Status: resolved; the multi-window merge regression, direct/nested/symlink Trash fixtures, intermediate-component regression, exclusive no-overwrite restore tests, all 23 core tests, and the app build/launch pass.

## 2026-07-12 - TASK-035 - Bounded map root starvation

- Symptom: the first live Home scan collapsed 7.44 GB into the root `Other` segment even though later top-level folders should have been visible.
- Cause: depth-first enumeration let one early deep subtree consume the global 5,000-node map budget before later root folders were registered.
- Fix: kept the bounded deep-tree budget but reserved a capped set of direct root nodes, so later top-level folders retain truthful totals and only unavailable deeper detail collapses into `Other`; added a regression with a deep early folder and a large late root folder.
- Status: resolved; 28 core tests pass and the live whole-disk map shows distinct Applications, System, Users, Library, var, opt, usr, tmp, and bin branches.

## 2026-07-12 - TASK-035 - Generated app Finder metadata

- Symptom: the first final `./script/build_and_run.sh --verify` pass built successfully but ad-hoc signing rejected `com.apple.FinderInfo` on the generated Debug app.
- Cause: Finder/File Provider metadata was attached to the build product, matching the previously documented local signing behavior.
- Fix: cleared extended attributes only from `build/XcodeData/Build/Products/Debug/CleanMac.app` and repeated the standard verification command.
- Status: resolved; the repeated check reports a valid on-disk signature and satisfied designated requirement.

## 2026-07-12 - TASK-036 - Repeated generated app Finder metadata

- Symptom: the first onboarding launch verification built successfully but signing again rejected `com.apple.FinderInfo` on the generated Debug app.
- Cause: the same local Finder/File Provider metadata behavior already documented for TASK-035 recurred after rebuilding the app.
- Fix: cleared extended attributes only from the generated Debug `.app` and repeated the standard verification command without touching source or user files.
- Status: resolved; the final app is valid on disk, satisfies its designated requirement, and launches into the first onboarding page.

## 2026-07-12 - TASK-036 - Finder metadata between release signing passes

- Symptom: the first Release packaging run copied the current app into `dist`, but the second codesign pass rejected FinderInfo that File Provider attached after the first pass.
- Cause: the script sanitized before and after the pair of signing commands, leaving a short unsanitized interval between nested-code signing and outer-app signing.
- Fix: sanitize the generated app between both signing passes for Developer ID and ad-hoc paths, then retain the existing fresh-ZIP verification.
- Status: resolved; packaging completes, the ZIP checksum passes, and strict signature verification succeeds for both the fresh extraction and the sanitized local `dist/CleanMac.app`.

## 2026-07-12 - TASK-037 - Menu popover ignored selected appearance

- Symptom: the first reference-based menu used a fixed purple palette; after replacing it with semantic colors, live dark-theme review still showed a light popover while the main CleanMac window was dark.
- Cause: the `.window` `MenuBarExtra` presentation did not honor `preferredColorScheme`, so its SwiftUI environment remained light even though the stored CleanMac appearance was dark.
- Fix: removed the fixed reference palette, used adaptive system materials/semantic colors, and injected `CleanMacAppearance.colorScheme` directly into the menu popover environment.
- Status: resolved; live Russian screenshots confirm distinct light and dark popovers, and the original light preference was restored after review.

## 2026-07-12 - TASK-038 - Background launch window lifecycle

- Symptom: removing unconditional `NSApp.activate` stopped forced foreground activation, but SwiftUI still created a main window during background launch; the first immediate suppression also hid the initial window during a normal test launch because `NSApp.isActive` was still false in `didFinishLaunching`.
- Cause: initial SwiftUI window creation and macOS activation settle on different lifecycle turns, and `applicationShouldHandleReopen` is not guaranteed for the first process launch.
- Fix: create the initial window transparent for 0.2 seconds, then show it if the app became active or order it out if the launch stayed in the background; activation, reopen, and menu-bar Open clear suppression and reveal the existing window.
- Status: resolved; background launch has zero main windows, explicit activation shows one, and menu-bar Open restores it. The initial build also required a direct `ServiceManagement` import in `SettingsView`, and the known FinderInfo build-product attribute was cleared before the successful signed launch rerun.

## 2026-07-12 - TASK-038 - File Provider metadata during Release signing

- Symptom: the first local package refresh built Release successfully, but File Provider attached `com.apple.FinderInfo` after sanitization and before the second outer codesign pass.
- Cause: sanitizing once between signing steps still leaves a narrow external metadata race on the `Documents`-backed `dist` folder.
- Fix: wrapped every app signing and local verification pass in a bounded three-attempt sanitize-and-retry helper, preserving strict fresh-ZIP verification as the final source of truth.
- Status: resolved for the distributable; packaging created `CleanMac-13fc508-unsigned.zip` and its fresh extraction satisfies the designated requirement. File Provider can still reattach FinderInfo later to the convenience `dist/CleanMac.app`, so the verified ZIP remains the release source of truth.

## 2026-07-12 - TASK-040 - Repeated generated app Finder metadata

- Symptom: the first duplicate-finder launch verification built successfully but ad-hoc signing rejected `com.apple.FinderInfo` on the generated Debug app.
- Cause: the known local Finder/File Provider metadata behavior recurred on the build product.
- Fix: cleared extended attributes only from `build/XcodeData/Build/Products/Debug/CleanMac.app` and repeated the standard verification command without touching source or user files.
- Status: resolved; the repeated verification reported a valid on-disk signature and launched the current Debug app.

## 2026-07-12 - TASK-041 - Non-portable checksum path

- Symptom: the first downloaded `v0.3.0` checksum contained the absolute local `/Users/admin/Documents/CleanMac/dist/...` path, so `shasum -c` could resolve the developer machine's file instead of the ZIP beside the downloaded checksum.
- Cause: `package_release.sh` passed the absolute `ZIP_PATH` directly to `shasum`.
- Fix: generate the checksum from inside `dist` using only the ZIP basename, replace the GitHub checksum asset, and repeat verification from a clean temporary download directory.
- Status: resolved; the published checksum now references `CleanMac-515f591-unsigned.zip`, and clean-directory verification checks the downloaded ZIP successfully.

## 2026-07-12 - TASK-042 - Existing release made tag workflow fail

- Symptom: the `v0.3.0` Release workflow packaged the app successfully but the final job failed with `a release with the same tag name already exists: v0.3.0`.
- Cause: the workflow always called `gh release create`, while `v0.3.0` had already been published and verified through the approved local release flow.
- Fix: query the tag first; create only when missing, otherwise upload the same ZIP/checksum names with `--clobber` while preserving the current title and English notes.
- Status: resolved for future executions; the exact existing-release branch refreshed both `v0.3.0` assets successfully and clean-download SHA-256 verification passed. The historical failed run remains unchanged because reruns use the workflow stored at the tagged commit.

## 2026-07-12 - TASK-043 - Custom folder segment did not open

- Symptom: clicking `Своя папка` in Disk Analysis or Duplicate Finder did not reliably activate the source or show the native folder picker.
- Cause: both views called synchronous `NSOpenPanel.runModal()` directly from the segmented Picker's `onChange` callback while SwiftUI was still applying the source-state transaction.
- Fix: use an intercepting source Binding, defer panel presentation to the next main-actor turn, and mutate the source only after a folder is selected; cancel leaves the previous source unchanged.
- Status: resolved; live Russian checks opened both native panels, verified cancel fallback, selected `/Users/admin/Documents` in both sections, and confirmed that no scan started automatically.

## 2026-07-12 - TASK-044 - Requested section was consumed before scene restoration

- Symptom: the first live route check consumed the requested Disk Analysis section but the restored main window still displayed Overview.
- Cause: `onAppear` applied the external selection before SwiftUI restored the existing `@SceneStorage` sidebar value.
- Fix: consume the requested section from an ID-driven task after one main-actor yield, then clear the one-shot preference.
- Status: resolved; the second clean launch opened directly on the Russian Disk Analysis screen and did not start a scan.

## 2026-07-12 - TASK-046 - System alias escaped the first protected-root check

- Symptom: the first full 47-test run let `/etc/hosts` pass inspection even though `/private/etc` was protected.
- Cause: Foundation path resolution did not canonicalize the existing `/etc` parent alias in this validation path.
- Fix: explicitly protect `/etc`, `/var/db`, `/var/root`, and `/var/vm` alongside their `/private` targets, then rerun the focused and full suites.
- Status: resolved; the alias regression and all four shredder tests pass, and all 47 core tests are green.

## 2026-07-12 - TASK-046 - Repeated generated app Finder metadata

- Symptom: the first final launch verification built successfully but ad-hoc signing rejected `com.apple.FinderInfo` on the generated Debug app.
- Cause: the known local Finder/File Provider metadata behavior recurred on the build product.
- Fix: cleared extended attributes only from `build/XcodeData/Build/Products/Debug/CleanMac.app` and repeated the standard verification command.
- Status: resolved; the Debug app is valid on disk, satisfies its designated requirement, and launches successfully.

## 2026-07-13 - TASK-047 - Finder metadata on local convenience app

- Symptom: the local Release ZIP and checksum passed, but a later direct signature check of `dist/CleanMac.app` found `com.apple.FinderInfo` reattached after packaging.
- Cause: File Provider can mutate the Documents-backed convenience copy after the packaging script sanitizes and signs it.
- Fix: treated the fresh ZIP extraction as the distribution source of truth, matching the packaging contract, and repeated checksum, version, architecture, and strict signature verification on both a clean local extraction and a clean GitHub asset download.
- Status: resolved for the release artifact; both fresh extractions are valid, while the mutable convenience app is not used as release evidence.

## 2026-07-13 - TASK-048 - Debug launch signing metadata race

- Symptom: the first `./script/build_and_run.sh --verify` pass built Debug successfully, then strict ad-hoc signature verification rejected `com.apple.FinderInfo` on the generated app bundle.
- Cause: the same local Finder/File Provider metadata race documented for release packaging can reattach Finder metadata between bundle sanitization, signing, and verification.
- Fix: hardened `script/build_and_run.sh` with the same bounded sanitize-and-retry wrapper used by release packaging, including `SetFile -a bc` when available.
- Status: resolved; the repeated `./script/build_and_run.sh --verify` pass produced a valid signed Debug app and launched CleanMac.

## 2026-07-13 - TASK-051 - System maintenance permission denial

- Symptom: Free Memory reported `/usr/sbin/purge` exit code 1 with `Operation not permitted`; Flush DNS could partially fail when signalling `mDNSResponder`.
- Cause: modern macOS can deny these maintenance commands to a normal app process even though the paths exist.
- Fix: System maintenance now runs only fixed absolute scripts through the macOS administrator authorization prompt after the user clicks a button, with no stored credentials, privileged helper, scheduling, or user-provided shell input.
- Status: resolved in code and verified by build/test checks; the actual RAM purge and DNS flush were intentionally not executed during automated verification.

## 2026-07-13 - TASK-053 - DMG inherited File Provider metadata

- Symptom: the first DMG was created, but strict verification of `CleanMac.app` inside the mounted image rejected `com.apple.FinderInfo`, so checksum generation correctly did not run.
- Cause: the first DMG staging folder lived under the Desktop-backed repository `dist/`, where File Provider could reattach metadata between sanitization and image creation.
- Fix: stage the DMG in `/private/tmp`, copy without resource forks or extended attributes, sanitize there, then create and verify the read-only image from that isolated copy.
- Status: resolved; the repeated package run verifies the DMG checksum, mounted app signature, and `/Applications` shortcut before writing release checksums.

## 2026-07-13 - TASK-054 - Unavailable App Store SF Symbol

- Symptom: the Applications sidebar icon was blank with `appstore`, while letter-based and hand-drawn substitutes did not resemble the native App Store artwork.
- Cause: `appstore` is not available as an SF Symbol on the current macOS, so `NSImage(systemSymbolName:)` returns `nil`.
- Fix: load the installed App Store application icon through `NSWorkspace`, render the Retina `NSImage` directly in SwiftUI, and keep `square.stack.3d.up.fill` only as a fallback when App Store is unavailable.
- Status: resolved; live selected and unselected sidebar screenshots show the native App Store icon clearly.

## 2026-07-13 - TASK-054 - Runtime package descendants were undercounted

- Symptom: the first stale-runtime probe measured less space than `du` for an old Codex installer directory.
- Cause: the shared scanner skipped package descendants, but Codex runtimes contain package-shaped directories whose contents still consume disk space.
- Fix: enumerate package descendants only for the narrowly scoped stale-runtime category and raise its dedicated safety cap to 100,000 descendants while preserving the existing cap and package behavior for every other category.
- Status: resolved; the real read-only probe reports two eligible directories totaling 1,772,158,976 bytes and excludes `codex-primary-runtime`.

## 2026-07-13 - TASK-055 - Finder Applications icon rendered as stripes

- Symptom: the full App Store icon was the only colored sidebar item; replacing it with the complete system `SidebarApplicationsFolder.icns` made SwiftUI composite several bitmap representations into a striped mark.
- Cause: the Finder `.icns` contains eight point/scale representations, and passing that multi-representation `NSImage` through the resizable template path did not select one stable bitmap.
- Fix: select the exact 36×36 Retina representation, create a single 18-point `NSImage`, mark it as a template, and tint it with the existing selected/unselected icon color.
- Status: resolved; live screenshots show one crisp gray mark when unselected and the same mark in white when selected.

## 2026-07-13 - TASK-056 - Shredder animation clipped in the standard window

- Symptom: the first live destruction-animation pass started below the static Shredder header, warning, and queue controls, so the lower fragments, progress, and completion state were clipped in the standard window.
- Cause: the normal workspace panels remained mounted while an irreversible operation was running, leaving too little vertical space for the complete focused animation scene.
- Fix: while an animation session exists, replace the normal Shredder content with one stable focused operation view that contains the Quick Look preview, mechanism, falling strips, real progress, and final state.
- Status: resolved; disposable-file screenshots show the complete scene at the 98% finalizing state and at the 100% post-unlink success state without clipping.
