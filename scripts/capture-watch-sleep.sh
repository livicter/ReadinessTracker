#!/usr/bin/env bash
# Render WatchSleepChrome → .audit/verify-watch-sleep.png via unit test ImageRenderer.
# Mirrors Watch App WatchSleepView (Hours|Eff callout + stage bar + legend).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WatchSleepCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-watch-sleep.png"
SENTINEL="/tmp/rt-audit/CAPTURE_WATCH_SLEEP"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
export CAPTURE_WATCH_SLEEP=1
trap 'rm -f "$SENTINEL"' EXIT

run_tests() {
  xcodebuild "$@" \
    -project ReadinessTracker.xcodeproj \
    -scheme ReadinessTracker \
    -destination "$DEST" \
    -derivedDataPath "$DERIVED" \
    -only-testing:ReadinessTrackerTests/WatchSleepCaptureTests/testCaptureWatchSleepPNGWhenRequested \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_ON_DEMAND_RESOURCES=NO \
    -quiet
}

if ! run_tests test; then
  echo "==> test hung/failed; trying build-for-testing + test-without-building" >&2
  xcodebuild build-for-testing \
    -project ReadinessTracker.xcodeproj \
    -scheme ReadinessTracker \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO \
    ENABLE_ON_DEMAND_RESOURCES=NO \
    -quiet
  killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
  sleep 2
  run_tests test-without-building
fi

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-watch-sleep.png
echo "==> wrote .audit/verify-watch-sleep.png ($(wc -c < .audit/verify-watch-sleep.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of WatchSleepChrome (Hours|Eff + stage legend) via WatchSleepCaptureTests; Watch App compiles WatchSleepView with same snapshot fields."
