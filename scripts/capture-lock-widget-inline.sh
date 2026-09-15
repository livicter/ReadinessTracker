#!/usr/bin/env bash
# Render LockScreenInlineChrome → .audit/verify-lock-widget-inline.png via unit test ImageRenderer.
# accessoryInline is text-only (readiness + short G/W/S cues); widget target compiles AccessoryInlineWidgetView.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-LockWidgetInlineCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-lock-widget-inline.png"
SENTINEL="/tmp/rt-audit/CAPTURE_LOCK_WIDGET_INLINE"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/LockWidgetCaptureTests/testCaptureLockWidgetInlinePNGWhenRequested \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-lock-widget-inline.png
echo "==> wrote .audit/verify-lock-widget-inline.png ($(wc -c < .audit/verify-lock-widget-inline.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of LockScreenInlineChrome (readiness + G/W/S text glance) via LockWidgetCaptureTests; widget target also compiles AccessoryInlineWidgetView."
