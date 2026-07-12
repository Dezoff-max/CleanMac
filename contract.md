# Contract

## Task

- ID: TASK-042
- Title: Idempotent GitHub Release publishing
- Mode: continue

## Planner Notes

- Why this task now: the `v0.3.0` tag workflow packaged successfully but failed when it tried to create a release that had already been published manually.
- Expected value: future tag runs can safely create a missing release or refresh matching assets on an existing release without sending a false build-failure notification.
- Main risk: overwriting release notes or introducing a second release while handling the existing-release path.
- Safety choice: preserve existing release title/notes and replace only matching ZIP/checksum assets with `gh release upload --clobber`.

## Builder Scope

- Allowed files:
  - `.github/workflows/release.yml`;
  - Loop documentation files.
- Allowed commands:
  - read-only Actions run/log/release inspection;
  - YAML and embedded shell syntax checks;
  - execute the approved existing-release branch against `v0.3.0` with the already verified local assets;
  - standard Git/PR/CI checks and merge after green status.
- Out of scope:
  - moving or recreating `v0.3.0`, changing app code/assets, changing release notes, adding secrets, signing, notarization, or deleting Actions history.
- Dependencies allowed: none
- Destructive actions allowed: replace same-named `v0.3.0` release assets only; no user files

## Evaluator Checklist

- Done criteria:
  - Missing releases still use `gh release create` with the existing title and notes.
  - Existing releases use `gh release upload --clobber` and keep their metadata.
  - The exact existing-release shell path succeeds for `v0.3.0` and leaves exactly the verified ZIP and checksum assets.
  - Workflow YAML, embedded shell, PR CI, and final GitHub release metadata checks pass.
- Required verification:
  - Ruby YAML parse;
  - extracted publish-step `bash -n`;
  - controlled existing-release execution for `v0.3.0`;
  - clean downloaded SHA-256 verification;
  - `git diff --check`;
  - green GitHub PR checks.
- Manual checks:
  - Confirm `v0.3.0` remains public/latest with its English release notes unchanged.
  - Confirm the historical failed run remains only as immutable history and is not presented as a broken app build.

## Result

- Status: complete
- Verification result: workflow YAML parsed; embedded shell passed `bash -n`; the stubbed missing-release path called `gh release create`; the exact existing-release path successfully refreshed `v0.3.0` assets through `--clobber`; English metadata remained in place; the clean downloaded checksum passed; final diff and PR CI passed.
- Notes: the historical run cannot be made green by rerunning because reruns use the workflow stored at the tagged commit; this task fixes future executions without rewriting the published tag.
