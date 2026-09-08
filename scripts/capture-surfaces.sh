#!/usr/bin/env bash
# Capture Today, WHOOP stack, Body & activity, Body metric detail, Settings, Check-in, History, Weekly Report, Journal, Journal impact, rings, ring detail, sleep quality, sleep debt, sleep disturbances, sleep stages hypnogram, metric detail scrub, classic MetricDetailView scrub, strain/recovery balance, Recommendations, Coaching, Sleep Performance, and Sleep HRV via XCUITest.
# UITests write PNGs to /tmp/rt-audit. This script copies them into .audit/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="ReadinessTracker.xcodeproj"
SCHEME="ReadinessTracker"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-UI-DD}"
SHOT_SRC="/tmp/rt-audit"
SHOT_DST="${SHOT_DST:-$ROOT/.audit}"

pick_destination() {
  if [[ -n "${DESTINATION:-}" ]]; then
    printf '%s\n' "$DESTINATION"
    return
  fi
  local name
  name="$(xcrun simctl list devices available | awk -F'[()]' '/iPhone/ && /Booted|Shutdown/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); print $1; exit}')"
  if [[ -n "$name" ]]; then
    printf 'platform=iOS Simulator,name=%s\n' "$name"
  else
    printf 'platform=iOS Simulator,name=iPhone 16\n'
  fi
}

DEST="$(pick_destination)"
echo "==> Destination: $DEST"
rm -rf "$SHOT_SRC"
mkdir -p "$SHOT_SRC" "$SHOT_DST"

xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -only-testing:ReadinessTrackerUITests \
  CODE_SIGNING_ALLOWED=NO

for f in verify-dashboard.png verify-whoop-stack.png verify-body-activity.png verify-body-detail.png verify-settings-sources.png verify-rings.png verify-ring-detail.png verify-sleep-quality.png verify-sleep-debt.png verify-checkin.png verify-history.png verify-journal.png verify-journal-impact.png verify-sleep-disturbances.png verify-weekly-report.png verify-sleep-stages.png verify-metric-detail-scrub.png verify-metric-detail-classic-scrub.png verify-strain-recovery.png verify-recommendations.png verify-coaching.png verify-sleep-performance.png verify-sleep-hrv.png; do
  if [[ ! -s "$SHOT_SRC/$f" ]]; then
    echo "missing $SHOT_SRC/$f" >&2
    exit 1
  fi
  cp "$SHOT_SRC/$f" "$SHOT_DST/$f"
  echo "==> $SHOT_DST/$f"
done

echo "==> SURFACES CAPTURED"
