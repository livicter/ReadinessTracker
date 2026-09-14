#!/usr/bin/env bash
# Render HomeWidgetCheckInChrome → .audit/verify-home-widget-deeplinks.png via unit test ImageRenderer.
# Shows medium + large Home widget chrome with Check-in / Evening / Trends deep-link controls
# (real widgets use Link → readinesstracker://checkin/{morning|evening} + readinesstracker://trends).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WidgetDeepLinksCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-home-widget-deeplinks.png"
SENTINEL="/tmp/rt-audit/CAPTURE_HOME_WIDGET_DEEPLINKS"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/HomeWidgetCheckInCaptureTests/testCaptureHomeWidgetDeepLinksPNGWhenRequested \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-home-widget-deeplinks.png
echo "==> wrote .audit/verify-home-widget-deeplinks.png ($(wc -c < .audit/verify-home-widget-deeplinks.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of HomeWidgetCheckInChrome (Evening + Trends Links) via HomeWidgetCheckInCaptureTests."
