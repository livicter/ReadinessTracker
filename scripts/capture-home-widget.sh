#!/usr/bin/env bash
# Render HomeWidgetSmallChrome → .audit/verify-home-widget.png via unit test ImageRenderer.
# Same CompactTripleRingsView / TripleRingGeometry compiled into the widget target.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WidgetCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-home-widget.png"
SENTINEL="/tmp/rt-audit/CAPTURE_HOME_WIDGET"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/HomeWidgetCaptureTests \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-home-widget.png
echo "==> wrote .audit/verify-home-widget.png ($(wc -c < .audit/verify-home-widget.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of HomeWidgetSmallChrome (shared CompactTripleRingsView) via HomeWidgetCaptureTests; widget target also compiles the same views."
