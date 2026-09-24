# Day Detail WeeklyPatternView on Strain (Honest #312)

## Intent
Mount existing `WeeklyPatternView` for Strain/activeCalories when
`strainSeriesThroughDay.count >= 7` — Sleep #268 / HRV #294 / RHR #308 dual.
Continues Strain track after #311 SmartInsights. No rewrite / no new HK.

## Surface
- History → day row → DayDetailView
- Weekly Pattern card for Active Calories after RHR Weekly Pattern
- A11y: `day.detail.strain.weeklyPattern`

## Verify
- UITest: `testDayDetailStrainWeeklyPatternSurface`
- Shot: `.audit/verify-day-detail-strain-weekly-pattern.png`

## Non-goals
- No Strain histogram yet (→ #313); no BAC / HK duals
