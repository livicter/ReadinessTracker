# Today dashboard (bright mode)

## Sub-features
- Source chips: selected is dark text on #E5E5EA
- Morning/Evening cards open Check-in for that time
- Recovery & Strain header + wheel opens RecoveryStrainDetailView
- Sleep Performance / HRV / Debt / Quality / Consistency (or Not recorded last night)
- Body & activity: steps, activity minutes, calories, SpO2, nutrition, cycle if opted in
- Pull to refresh

## How to get to it
Launch the app. Land on Today.

## Driving it with simulator
1. `./scripts/ci-verify.sh`
2. `xcrun simctl launch booted com.readiness.ReadinessTracker`
3. `xcrun simctl io booted screenshot .audit/verify-dashboard.png`

## Gotchas
- App is forced light via `preferredColorScheme(.light)`.
- WHOOP is a HealthKit source label, not a DataSource case.
