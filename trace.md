# Trace

Append-only trace of failures, restarts, and judgment divergences.

## 2026-07-09 - TASK-015 - Test threshold mismatch

- Symptom: `testDownloadsReviewUsesSmartRules` initially included a recent small file.
- Cause: the test used a 64-byte "large download" threshold, but APFS allocated size for tiny files is several KB.
- Fix: raised the test threshold and fixture size to model allocated-size behavior more realistically.
- Status: resolved; `swift test --package-path CleanMacCore` passes.
