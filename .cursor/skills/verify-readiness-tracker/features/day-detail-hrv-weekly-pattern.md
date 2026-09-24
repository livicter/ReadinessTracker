# Day Detail WeeklyPatternView on HRV (Honest #294)

## Intent
Mount existing `WeeklyPatternView` on `DayDetailView` for HRV series when
`hrvSeriesThroughDay.count >= 7` — Sleep #268 dual. Reuses shared pattern
logic; no rewrite.

## Surface
- History → day row → DayDetailView
- Weekly Pattern card for HRV after Sleep Weekly Pattern
- A11y: `day.detail.hrv.weeklyPattern`

## Verify
- UITest: `testDayDetailHRVWeeklyPatternSurface`
- Shot: `.audit/verify-day-detail-hrv-weekly-pattern.png`

## Non-goals
- No RecoveryTrajectory / RHR track; no BAC / HK duals
