# Day Detail SmartInsightsView (Honest #267)

## Intent
Mount existing `SmartInsightsView` on `DayDetailView` for the Sleep series
when the 7-day window has ≥3 points — Metric Detail / Trends #263 parity.
Elevates unused insight presentation on Day Detail; reuses component.

## Surface
- History → day row → DayDetailView
- Insights card after 7-day context charts
- Sleep hours from `sevenDayWindow`; current = day’s sleepHours
- A11y: `day.detail.smartInsights`

## Verify
- UITest: `testDayDetailSmartInsightsSurface`
- Shot: `.audit/verify-day-detail-smart-insights.png`

## Non-goals
- No WeeklyPattern / RecoveryTrajectory on Day Detail yet; no BAC / HK duals
