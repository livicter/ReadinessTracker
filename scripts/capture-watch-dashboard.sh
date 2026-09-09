#!/usr/bin/env bash
# Render WatchDashboardChrome → .audit/verify-watch-dashboard.png via unit test ImageRenderer.
# Same CompactTripleRingsView / TripleRingGeometry compiled into the Watch App target.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WatchCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-watch-dashboard.png"
SENTINEL="/tmp/rt-audit/CAPTURE_WATCH_DASHBOARD"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/WatchDashboardCaptureTests \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-watch-dashboard.png
echo "==> wrote .audit/verify-watch-dashboard.png ($(wc -c < .audit/verify-watch-dashboard.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of WatchDashboardChrome (shared CompactTripleRingsView) via WatchDashboardCaptureTests; Watch App also compiles TripleRingGeometry + CompactTripleRingsView."
