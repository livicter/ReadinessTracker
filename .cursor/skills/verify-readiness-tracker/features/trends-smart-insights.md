# Trends SmartInsightsView (Honest #263)

## Intent
Mount existing `SmartInsightsView` on `TrendDetailView` when the primary
depth series has ≥3 points — presentation parity with classic Metric Detail.
Reuses component; no insight-logic rewrite.

## Surface
- History → Browse Trends → TrendDetailView
- Insights card after distribution histogram (when ≥3 days)
- Wired with `scrubAnalysisMetric` + `depthTimelinePoints`
- A11y: `trends.smartInsights`

## Verify
- UITest: `testTrendsSmartInsightsSurface`
- Shot: `.audit/verify-trends-smart-insights.png`

## Non-goals
- No WeeklyPatternView / RecoveryTrajectoryView (→ #264+); no BAC / HK duals
