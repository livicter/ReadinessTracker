#!/usr/bin/env bash
# Render WatchComplicationInlineChrome → .audit/verify-watch-complication-inline.png via unit test ImageRenderer.
# accessoryInline: colored readiness + short G/W/S cues; Watch Widgets compiles WatchInlineComplicationView.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WatchCompInlineCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-watch-complication-inline.png"
SENTINEL="/tmp/rt-audit/CAPTURE_WATCH_COMPLICATION_INLINE"
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
    -only-testing:ReadinessTrackerTests/WatchComplicationCaptureTests/testCaptureWatchComplicationInlinePNGWhenRequested \
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
cp -f "$TMP_PNG" .audit/verify-watch-complication-inline.png
echo "==> wrote .audit/verify-watch-complication-inline.png ($(wc -c < .audit/verify-watch-complication-inline.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of WatchComplicationInlineChrome (colored readiness + G/W/S cues) via WatchComplicationCaptureTests; Watch Widgets extension also compiles WatchInlineComplicationView."
