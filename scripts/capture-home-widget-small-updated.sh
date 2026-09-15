#!/usr/bin/env bash
# Render HomeWidgetSmallChrome (live Updated) → .audit/verify-home-widget-small-updated.png
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WidgetSmallUpdatedCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-home-widget-small-updated.png"
SENTINEL="/tmp/rt-audit/CAPTURE_HOME_WIDGET_SMALL_UPDATED"
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
    -only-testing:ReadinessTrackerTests/HomeWidgetCaptureTests/testCaptureHomeWidgetSmallUpdatedPNGWhenRequested \
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
cp -f "$TMP_PNG" .audit/verify-home-widget-small-updated.png
echo "==> wrote .audit/verify-home-widget-small-updated.png ($(wc -c < .audit/verify-home-widget-small-updated.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of HomeWidgetSmallChrome (live Text style .relative Updated cue on small) via HomeWidgetCaptureTests; mirrors SmallWidgetView Honest #51."
