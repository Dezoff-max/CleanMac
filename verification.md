# Verification

## Package Manager

- Detected package manager: SwiftPM for `CleanMacCore`; Xcode project for the macOS app.
- Detection source: `CleanMacCore/Package.swift`, `CleanMac.xcodeproj`, `script/*.sh`.

## Commands

- Install: none required.
- Run/dev: `./script/build_and_run.sh`
- Verify launch: `./script/build_and_run.sh --verify`
- Build: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`
- Test: `swift test --package-path CleanMacCore`
- Package: `./script/package_release.sh`
- Lint/typecheck: no dedicated lint command found.

## Manual Checklist

- `contract.md` defines done criteria and allowed files before implementation.
- Relevant files were inspected before editing.
- The smallest useful change was made.
- Existing user work was preserved.
- No secrets were copied or logged.
- No destructive cleanup behavior was introduced unless explicitly requested.
- Documentation was updated when behavior changed.
- `progress.md` was updated after verification.
- `trace.md` was updated when verification failed or the loop restarted.

## Success Criteria

- The selected task's definition of done is met.
- The selected task's contract is satisfied.
- The relevant verification command or manual check passes.
- Any known failures are documented clearly.

## If Checks Fail

1. Read the error output.
2. Fix only failures caused by the current task.
3. Re-run the relevant check.
4. If the failure is unrelated or out of scope, document it in `progress.md` and do not mark the task complete.

## Verification Matrix

| Area | Command or check | When to run | Success signal | Fallback |
| --- | --- | --- | --- | --- |
| macOS app launch | `./script/build_and_run.sh --verify` | UI, app lifecycle, assets, or project changes | Build succeeds and `pgrep -x CleanMac` finds the app | Run the xcodebuild command from this file and inspect launch logs |
| Core package | `swift test --package-path CleanMacCore` | Core model, scanner, or package changes | All tests pass | Run `cd CleanMacCore && swift test` |
| Release package | `./script/package_release.sh` | Packaging, release, or CI artifact changes | `dist/*.zip` and `.sha256` are created and checksum passes | Inspect `build/XcodeData/Build/Products/Release` |
| CI | GitHub Actions run | After pushed app/build changes | Test, Debug build, and release artifact jobs are green | Inspect failing job logs and reproduce locally |
