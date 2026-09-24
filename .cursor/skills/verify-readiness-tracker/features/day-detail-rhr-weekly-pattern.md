# Day Detail WeeklyPatternView on RHR (Honest #308)

## Intent
Mount existing `WeeklyPatternView` on `DayDetailView` for RHR series when
`rhrSeriesThroughDay.count >= 7` — Sleep #268 / HRV #294 dual. Reuses shared
pattern logic (`metric.higherIsBetter` already false for restingHR); no rewrite.

## Surface
- History → day row → DayDetailView
- Weekly Pattern card for RHR after HRV Weekly Pattern
- A11y: `day.detail.rhr.weeklyPattern`

## Verify
- UITest: `testDayDetailRHRWeeklyPatternSurface`
- Shot: `.audit/verify-day-detail-rhr-weekly-pattern.png`

## Non-goals
- No RecoveryTrajectory yet (→ #309); no BAC / HK duals
