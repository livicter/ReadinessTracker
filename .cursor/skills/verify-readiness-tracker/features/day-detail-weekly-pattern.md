# Day Detail WeeklyPatternView (Honest #268)

## Intent
Mount existing `WeeklyPatternView` on `DayDetailView` for Sleep series when
history through the day has ≥7 points — Metric Detail / Trends #264 parity.
Elevates `weeklyPattern` presentation on Day Detail; reuses component.

## Surface
- History → day row → DayDetailView
- Weekly Pattern card after Smart Insights
- Sleep series: `sleepSeriesThroughDay` (history ≤ day)
- A11y: `day.detail.weeklyPattern`

## Verify
- UITest: `testDayDetailWeeklyPatternSurface`
- Shot: `.audit/verify-day-detail-weekly-pattern.png`

## Non-goals
- No RecoveryTrajectoryView yet (→ #269); no BAC / HK duals
