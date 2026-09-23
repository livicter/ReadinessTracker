# Walking Heart Rate Tonight|Baseline (Honest #134)

## Intent
Wire HealthKit `walkingHeartRateAverage` into `DailyHealthData` + HK auth/fetch,
then elevate as a WHOOP-style **Tonight | Baseline** dual on Today vitals near
Peak HR / VO2 / Resting HR. Not a sleep dual.

## Plumbing
- Model: `DailyHealthData.walkingHeartRateAverage: Double?` (Codable)
- HK: read `.walkingHeartRateAverage`; day-average via HKStatisticsQuery
- Fixture: today 98 bpm; older 88…109; nil every 4th (sim has no samples)

## Surface
- Today → vitals → **Walking Heart Rate** (after VO2 Max)
- Tonight bpm vs 7-day avg; Easy / Steady / Elevated / High
- A11y: `vitals.walkinghr.card`, `vitals.walkinghr.baseline`, `vitals.walkinghr.spark`

## Verify
- UITest: `testWalkingHRTonightBaselineSurface`
- Shot: `.audit/verify-walking-hr-tonight-baseline.png`
