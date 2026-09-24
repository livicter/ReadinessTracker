# Day Detail SmartInsightsView on Strain (Honest #311)

## Intent
Mount existing `SmartInsightsView` for Strain/activeCalories when
`strainSeriesThroughDay.count >= 3` — Sleep #267 / HRV #290 / RHR #296 dual.
Thinnest Strain Day Detail track entry; reuses series already used for
RecoveryTrajectory strainHistory. No rewrite / no new HK.

## Surface
- History → day row → DayDetailView
- Insights card for Active Calories after RHR SmartInsights
- A11y: `day.detail.strain.smartInsights`

## Verify
- UITest: `testDayDetailStrainSmartInsightsSurface`
- Shot: `.audit/verify-day-detail-strain-smart-insights.png`

## Non-goals
- No Strain WeeklyPattern / histogram / overlays yet; no BAC / HK duals
