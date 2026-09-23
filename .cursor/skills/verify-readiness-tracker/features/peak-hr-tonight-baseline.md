# Peak Heart Rate Tonight|Baseline (Honest #132)

## Intent
Elevate `DailyHealthData.maxHeartRate` (HealthKit daytime peak / strain path)
into a WHOOP-style **Tonight | Baseline** dual on Today vitals after Resting HR.
HeartRateZonesCard in Recovery detail keeps zone math — this surfaces the peak
itself, which was thin on Today.

## Why not VO2 / walking HR
Those are not in `DailyHealthData` yet. `maxHeartRate` is already fetched from
HK, used by strain/TRIMP/zones, and fixture-backed — strongest unused dual.

## Surface
- Today → WHOOP vitals → **Peak Heart Rate** (after Resting HR)
- Tonight peak bpm vs 7-day peak avg; High / Elevated / Steady / Soft
- A11y: `vitals.peakhr.card`, `vitals.peakhr.baseline`, `vitals.peakhr.spark`

## Verify
- UITest: `testPeakHeartRateTonightBaselineSurface`
- Shot: `.audit/verify-peak-hr-tonight-baseline.png`
- Fixture: today 185; older 155…184; nil every 4th rest-ish day

## Non-goals
- No re-chrome of HeartRateZonesCard / RestingHRCard
- No sleep-stack dual clones
