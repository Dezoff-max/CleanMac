# AGENTS.md

## Project Reading Order

1. Read this file first.
2. Read `project-analysis.md`.
3. Read `contract.md`.
4. Read `roadmap.md`.
5. Read `progress.md`.
6. Read `trace.md`.
7. Read `verification.md`.
8. Inspect the relevant source files before editing.

Follow the closest nested `AGENTS.md` when one exists.

## Project Rules

- Answer the user in Russian.
- Preserve the current stack: macOS SwiftUI app plus `CleanMacCore` Swift package.
- Prefer small, reviewable changes over broad rewrites.
- Keep cleanup operations safe by default: scan before delete, require confirmation before destructive actions, and avoid real deletion in UI-only tasks.
- Do not add dependencies, change deployment targets, publish, notarize, or run destructive commands without explicit approval.
- Do not copy or expose secrets, tokens, or private configuration.

## Commands

- Install: none required.
- Run: `./script/build_and_run.sh`
- Verify launch: `./script/build_and_run.sh --verify`
- Package: `./script/package_release.sh`
- Test core: `swift test --package-path CleanMacCore`
- Build app: `xcodebuild -project CleanMac.xcodeproj -scheme CleanMac -configuration Debug -derivedDataPath build/XcodeData build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY=""`

## Verification

- Run the narrowest check that proves the task.
- For app UI or lifecycle changes, run `./script/build_and_run.sh --verify` and `swift test --package-path CleanMacCore`.
- For release or packaging changes, run `./script/package_release.sh`.
- Do not mark a task complete when verification fails or was not run.
- If verification repeats the same failure, update `trace.md` and restart from a smaller contract.

## Progress Updates

After each completed loop, append to `progress.md`:
- date;
- task ID and title;
- what changed;
- files touched;
- checks run;
- result;
- next step;
- bottleneck;
- handoff note.
