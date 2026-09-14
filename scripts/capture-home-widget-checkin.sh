#!/usr/bin/env bash
# Render HomeWidgetCheckInChrome → .audit/verify-home-widget-checkin.png via unit test ImageRenderer.
# Shows medium + large Home widget chrome with Fitness-style Check-in control
# (real widgets use Link / widgetURL → readinesstracker://checkin/morning).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WidgetCheckInCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-home-widget-checkin.png"
SENTINEL="/tmp/rt-audit/CAPTURE_HOME_WIDGET_CHECKIN"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/HomeWidgetCheckInCaptureTests/testCaptureHomeWidgetCheckInPNGWhenRequested \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-home-widget-checkin.png
echo "==> wrote .audit/verify-home-widget-checkin.png ($(wc -c < .audit/verify-home-widget-checkin.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of HomeWidgetCheckInChrome (medium+large Check-in control) via HomeWidgetCheckInCaptureTests; widget target uses Link/widgetURL."
