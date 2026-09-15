#!/usr/bin/env bash
# Render WatchComplicationCornerChrome → .audit/verify-watch-complication-corner.png via unit test ImageRenderer.
# accessoryCorner: compact rings + colored readiness/G/W/S widgetLabel cues; Watch Widgets compiles WatchCornerComplicationView.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WatchCompCornerCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-watch-complication-corner.png"
SENTINEL="/tmp/rt-audit/CAPTURE_WATCH_COMPLICATION_CORNER"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

run_tests() {
  xcodebuild "$@" \
    -project ReadinessTracker.xcodeproj \
    -scheme ReadinessTracker \
    -destination "$DEST" \
    -derivedDataPath "$DERIVED" \
    -only-testing:ReadinessTrackerTests/WatchComplicationCaptureTests/testCaptureWatchComplicationCornerPNGWhenRequested \
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
cp -f "$TMP_PNG" .audit/verify-watch-complication-corner.png
echo "==> wrote .audit/verify-watch-complication-corner.png ($(wc -c < .audit/verify-watch-complication-corner.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of WatchComplicationCornerChrome (rings + colored R/G/W/S widgetLabel cues) via WatchComplicationCaptureTests; Watch Widgets extension also compiles WatchCornerComplicationView."
