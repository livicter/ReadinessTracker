# Day Detail WeeklyPatternView on SpO2 (Honest #327)

## Intent
Mount existing `WeeklyPatternView` for SpO2 when `spo2SeriesThroughDay.count >= 7`
— Sleep #268 / Strain #312 dual. Uses #326 series helper. No new HK.

## Surface
- History → day row → DayDetailView
- Weekly pattern card for Blood Oxygen after Strain WeeklyPattern
- A11y: `day.detail.spo2.weeklyPattern`

## Verify
- UITest: `testDayDetailSpO2WeeklyPatternSurface`
- Shot: `.audit/verify-day-detail-spo2-weekly-pattern.png`

## Non-goals
- No SpO2 histogram / classifyTrend yet; no BAC / HK duals
