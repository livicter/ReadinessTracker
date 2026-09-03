---
name: verify-readiness-tracker
description: Prove ReadinessTracker (iOS) still works. Use before declaring a UI or logic change done, after a CI failure, or when starting a Mac-mini verification loop. Surface: iOS Simulator via xcodebuild.
---

# Verify ReadinessTracker

## Launch

Primary gate (same as GitHub Actions):

```bash
./scripts/ci-verify.sh
```

Optional overrides:

```bash
DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' ./scripts/ci-verify.sh
DERIVED_DATA_PATH=/tmp/ReadinessTracker-CI-DD ./scripts/ci-verify.sh
```

Ready when the script prints `TEST SUCCEEDED` and exits 0. Result bundle lands at `.audit/ci-result.xcresult` by default.

For a visual proof after tests (Mac mini only):

```bash
xcrun simctl bootstatus booted -b || true
# App is installed by the test run as com.readiness.ReadinessTracker
xcrun simctl launch booted com.readiness.ReadinessTracker || true
xcrun simctl io booted screenshot .audit/verify-dashboard.png
```

## Doctor

```bash
test -d ReadinessTracker.xcodeproj
xcodebuild -version
xcrun simctl list devices available | grep -q iPhone
./scripts/ci-verify.sh >/dev/null  # or run with -quiet path once
```

If doctor fails: fix Xcode/simulator availability before driving UI.

## Drive

1. Run `./scripts/ci-verify.sh` — this is the mandatory gate for every change that touches Swift under `ReadinessTracker/` or `ReadinessTrackerTests/`.
2. For UI/theme work, capture `.audit/verify-dashboard.png` and confirm bright (light) appearance: white/gray grouped background, dark labels, Today tab.
3. Do not treat "it compiles" as proof. Unit tests + (for UI) a simulator screenshot are the proof.

## Evidence

Keep proofs under `.audit/`:

- `ci-result.xcresult` or CI logs
- `verify-dashboard.png` for visual changes
- Append a row to `.audit/bright-apple-design.tsv` or a new `.audit/<task>.tsv` decision trail for multi-step loops

## Cleanup

```bash
# Never kill by process name. Only remove derived data you created.
rm -rf /tmp/ReadinessTracker-CI-DD
# Keep .audit evidence.
```

## Helpers

- `scripts/ci-verify.sh` — CI/local unit-test gate
- Feature map: `features/` in this skill folder
