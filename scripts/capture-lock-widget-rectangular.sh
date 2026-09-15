#!/usr/bin/env bash
# Render LockScreenRectangularChrome → .audit/verify-lock-widget-rectangular.png via unit test ImageRenderer.
# Same CompactTripleRingsView / TripleRingGeometry compiled into the widget target.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-LockWidgetRectCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-lock-widget-rectangular.png"
SENTINEL="/tmp/rt-audit/CAPTURE_LOCK_WIDGET_RECTANGULAR"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/LockWidgetCaptureTests/testCaptureLockWidgetRectangularPNGWhenRequested \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-lock-widget-rectangular.png
echo "==> wrote .audit/verify-lock-widget-rectangular.png ($(wc -c < .audit/verify-lock-widget-rectangular.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of LockScreenRectangularChrome (shared CompactTripleRingsView) via LockWidgetCaptureTests; widget target also compiles the same views."
