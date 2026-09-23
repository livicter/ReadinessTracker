# Trends RecoveryTrajectoryView (Honest #265)

## Intent
Mount existing `RecoveryTrajectoryView` on `TrendDetailView` when
`filteredHistory.count >= 5`, with activeCalories strain series — classic
Metric Detail parity. Elevates unused post-strain trajectory on Trends.
Reuses component; no trajectory-logic rewrite.

## Surface
- History → Browse Trends → TrendDetailView
- **Post-Strain Recovery** after Weekly Pattern
- Strain: `filteredHistory.map { ($0.date, $0.activeCalories) }`
- Metric series: `depthTimelinePoints` + `scrubAnalysisMetric`
- A11y: `trends.recoveryTrajectory`

## Verify
- UITest: `testTrendsRecoveryTrajectorySurface`
- Shot: `.audit/verify-trends-recovery-trajectory.png`

## Non-goals
- No classic MA7 toggle; no BAC / HK duals
