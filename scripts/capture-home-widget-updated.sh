#!/usr/bin/env bash
# Render HomeWidgetUpdatedChrome → .audit/verify-home-widget-updated.png via unit test ImageRenderer.
# Medium Home widget chrome with Fitness-style “Updated …” from App Group lastUpdate.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WidgetUpdatedCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-home-widget-updated.png"
SENTINEL="/tmp/rt-audit/CAPTURE_HOME_WIDGET_UPDATED"
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
    -only-testing:ReadinessTrackerTests/HomeWidgetCaptureTests/testCaptureHomeWidgetUpdatedPNGWhenRequested \
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
cp -f "$TMP_PNG" .audit/verify-home-widget-updated.png
echo "==> wrote .audit/verify-home-widget-updated.png ($(wc -c < .audit/verify-home-widget-updated.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of HomeWidgetUpdatedChrome (medium + Updated cue) via HomeWidgetCaptureTests; widget Medium/Large/ExtraLargeWidgetView also surface App Group lastUpdate."
