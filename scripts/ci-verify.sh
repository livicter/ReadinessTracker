#!/usr/bin/env bash
# Local parity with GitHub Actions CI: build + unit tests on iOS Simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="ReadinessTracker.xcodeproj"
SCHEME="ReadinessTracker"
DERIVED="${DERIVED_DATA_PATH:-/tmp/ReadinessTracker-CI-DD}"
RESULT_BUNDLE="${RESULT_BUNDLE_PATH:-$ROOT/.audit/ci-result.xcresult}"

mkdir -p "$(dirname "$RESULT_BUNDLE")" .audit

pick_destination() {
  if [[ -n "${DESTINATION:-}" ]]; then
    printf '%s\n' "$DESTINATION"
    return
  fi
  # Prefer an available iPhone simulator; fall back to generic latest iPhone.
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
echo "==> DerivedData: $DERIVED"
xcodebuild -version

rm -rf "$RESULT_BUNDLE"

set -x
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DEST" \
  -derivedDataPath "$DERIVED" \
  -resultBundlePath "$RESULT_BUNDLE" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet
set +x

echo "==> TEST SUCCEEDED"
echo "==> Result bundle: $RESULT_BUNDLE"
