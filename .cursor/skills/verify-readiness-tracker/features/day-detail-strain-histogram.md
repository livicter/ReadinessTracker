# Day Detail DistributionHistogramView on Strain (Honest #313)

## Intent
Mount existing `DistributionHistogramView` for Strain/activeCalories when
`strainSeriesThroughDay.count >= 5` — Sleep #271 / HRV #282 / RHR #297 dual.
Continues Strain track after #311 SmartInsights + #312 WeeklyPattern.

## Surface
- History → day row → DayDetailView
- Distribution card for Active Calories after RHR histogram
- A11y: `day.detail.strain.histogram`

## Verify
- UITest: `testDayDetailStrainHistogramSurface`
- Shot: `.audit/verify-day-detail-strain-histogram.png`

## Non-goals
- No Strain classifyTrend / overlays yet; no BAC / HK duals
