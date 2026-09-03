# Today dashboard (bright mode)

## Sub-features
- Readiness hero rings and score
- Source picker (Apple Watch / Fitbit)
- Floating tab bar (Today selected)

## How to get to it (user POV)
Launch the app → land on Today.

## Driving it with simulator
1. `./scripts/ci-verify.sh`
2. `xcrun simctl launch booted com.readiness.ReadinessTracker`
3. `xcrun simctl io booted screenshot .audit/verify-dashboard.png`

## Gotchas
- App is forced light via `preferredColorScheme(.light)`.
- Simulator WatchConnectivity warnings are noise.
