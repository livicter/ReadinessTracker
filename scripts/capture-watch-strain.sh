#!/usr/bin/env bash
# Render WatchStrainChrome → .audit/verify-watch-strain.png via unit test ImageRenderer.
# Same CompactStrainRecoveryWheel / StrainRecoveryDualArcGeometry compiled into the Watch App target.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
DEST="${DESTINATION:-platform=iOS Simulator,name=iPhone Air}"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-WatchStrainCapture-DD}"
TMP_PNG="/tmp/rt-audit/verify-watch-strain.png"
SENTINEL="/tmp/rt-audit/CAPTURE_WATCH_STRAIN"
mkdir -p .audit /tmp/rt-audit
rm -f "$TMP_PNG"
: > "$SENTINEL"
trap 'rm -f "$SENTINEL"' EXIT

xcodebuild test \
  -project ReadinessTracker.xcodeproj \
  -scheme ReadinessTracker \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerTests/WatchStrainCaptureTests \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

[[ -s "$TMP_PNG" ]] || { echo "missing tmp PNG at $TMP_PNG"; exit 1; }
cp -f "$TMP_PNG" .audit/verify-watch-strain.png
echo "==> wrote .audit/verify-watch-strain.png ($(wc -c < .audit/verify-watch-strain.png | tr -d ' ') bytes)"
echo "==> capture method: ImageRenderer of WatchStrainChrome (dual callout + day + Updated cue; shared CompactStrainRecoveryWheel) via WatchStrainCaptureTests; Watch App also compiles StrainRecoveryDualArcGeometry + CompactStrainRecoveryWheel."
