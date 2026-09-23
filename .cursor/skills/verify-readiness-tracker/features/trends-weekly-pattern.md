# Trends WeeklyPatternView (Honest #264)

## Intent
Mount existing `WeeklyPatternView` on `TrendDetailView` when the primary
depth series has ≥7 points — elevates unused `TrendAnalysisEngine.weeklyPattern`
presentation parity with classic Metric Detail.

## Surface
- History → Browse Trends → TrendDetailView
- Weekly Pattern card after Smart Insights (when ≥7 days)
- Wired with `scrubAnalysisMetric` + `depthTimelinePoints`
- A11y: `trends.weeklyPattern`

## Verify
- UITest: `testTrendsWeeklyPatternSurface`
- Shot: `.audit/verify-trends-weekly-pattern.png`

## Non-goals
- No RecoveryTrajectoryView (→ #265+); no BAC / HK duals
