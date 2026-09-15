#!/usr/bin/env bash
# Capture Today, WHOOP stack, Body & activity, Body metric detail, Settings, Check-in, History, Weekly Report, Journal, Journal impact, rings, ring detail, sleep quality, sleep debt, sleep disturbances, sleep stages hypnogram, metric detail scrub, classic MetricDetailView scrub, strain/recovery balance, strain/recovery dual-arc wheel, Recommendations, Coaching, Sleep Performance, Sleep HRV, Sleep Quality/Consistency, Respiratory Rate, Skin Temperature, History Trends detail, and Day Detail / Sleep Analysis night chrome via XCUITest.
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

# ImageRenderer chrome (not XCUITest): Home widget + Lock Screen accessory + Watch dashboard hero
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-HomeWidget" ./scripts/capture-home-widget.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-HomeWidgetLarge" ./scripts/capture-home-widget-large.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-HomeWidgetExtraLarge" ./scripts/capture-home-widget-extra-large.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-HomeWidgetUpdated" ./scripts/capture-home-widget-updated.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-HomeWidgetCheckIn" ./scripts/capture-home-widget-checkin.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-HomeWidgetDeepLinks" ./scripts/capture-home-widget-deeplinks.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-LockWidget" ./scripts/capture-lock-widget.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-LockWidgetRect" ./scripts/capture-lock-widget-rectangular.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-LockWidgetInline" ./scripts/capture-lock-widget-inline.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-WatchDash" ./scripts/capture-watch-dashboard.sh
DESTINATION="$DEST" DERIVED_DATA_PATH="${DERIVED}-WatchStrain" ./scripts/capture-watch-strain.sh
# Scripts write into .audit/; also ensure /tmp copies for the loop below
cp -f .audit/verify-home-widget.png "$SHOT_SRC/verify-home-widget.png"
cp -f .audit/verify-home-widget-large.png "$SHOT_SRC/verify-home-widget-large.png"
cp -f .audit/verify-home-widget-extra-large.png "$SHOT_SRC/verify-home-widget-extra-large.png"
cp -f .audit/verify-home-widget-updated.png "$SHOT_SRC/verify-home-widget-updated.png"
cp -f .audit/verify-home-widget-checkin.png "$SHOT_SRC/verify-home-widget-checkin.png"
cp -f .audit/verify-home-widget-deeplinks.png "$SHOT_SRC/verify-home-widget-deeplinks.png"
cp -f .audit/verify-lock-widget.png "$SHOT_SRC/verify-lock-widget.png"
cp -f .audit/verify-lock-widget-rectangular.png "$SHOT_SRC/verify-lock-widget-rectangular.png"
cp -f .audit/verify-lock-widget-inline.png "$SHOT_SRC/verify-lock-widget-inline.png"
cp -f .audit/verify-watch-dashboard.png "$SHOT_SRC/verify-watch-dashboard.png"
cp -f .audit/verify-watch-strain.png "$SHOT_SRC/verify-watch-strain.png"
cp -f .audit/verify-watch-complication.png "$SHOT_SRC/verify-watch-complication.png"

for f in verify-dashboard.png verify-whoop-stack.png verify-body-activity.png verify-body-detail.png verify-settings-sources.png verify-rings.png verify-ring-detail.png verify-sleep-quality.png verify-sleep-debt.png verify-checkin.png verify-history.png verify-journal.png verify-journal-impact.png verify-sleep-disturbances.png verify-weekly-report.png verify-sleep-stages.png verify-metric-detail-scrub.png verify-metric-detail-classic-scrub.png verify-strain-recovery.png verify-strain-wheel.png verify-recommendations.png verify-coaching.png verify-sleep-performance.png verify-sleep-hrv.png verify-respiratory.png verify-skin-temp.png verify-trends.png verify-day-detail.png verify-home-widget.png verify-home-widget-large.png verify-home-widget-extra-large.png verify-home-widget-updated.png verify-home-widget-checkin.png verify-home-widget-deeplinks.png verify-lock-widget.png verify-lock-widget-rectangular.png verify-lock-widget-inline.png verify-watch-dashboard.png verify-watch-strain.png verify-watch-complication.png; do
  if [[ ! -s "$SHOT_SRC/$f" ]]; then
    echo "missing $SHOT_SRC/$f" >&2
    exit 1
  fi
  cp "$SHOT_SRC/$f" "$SHOT_DST/$f"
  echo "==> $SHOT_DST/$f"
done

echo "==> SURFACES CAPTURED"
