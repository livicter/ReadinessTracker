# UV Exposure Tonight|Baseline (Honest #140)

## Why
1. Watch sleepHours / sleepEfficiency already dualled on Today sleep stack
   (SleepEfficiencyCard, TimeInBed, SleepPerformance) — avoid sleep-stack clones.
2. `uvExposure` was unused sparse HK — strongest unused real elevation.

## Plumbing
- Model: `uvExposureIndex: Double?`
- HK: read `.uvExposure`; day discreteAverage (count / UV index)
- Fixture: today 4.5; older 1.0…8.9; nil every 5th

## Surface
- Today vitals after Time in Daylight → **UV Exposure**
- Low / Moderate / High / Very High (WHO bands)
- A11y: `vitals.uv.card`, `vitals.uv.baseline`, `vitals.uv.spark`

## Verify
- `testUVExposureTonightBaselineSurface`
- `.audit/verify-uv-exposure-tonight-baseline.png`
