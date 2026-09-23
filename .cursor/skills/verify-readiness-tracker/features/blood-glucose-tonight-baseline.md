# Blood Glucose Tonight|Baseline (Honest #180)

## Why
1. Prefer `bloodGlucose` — unused vitals-adjacent after dietary + medical-sparse exhausted.
2. Day average mg/dL pairs with insulin delivery without sleep-stack duals.
3. After Insulin Delivery — not chrome-only.

## Plumbing
- Model: `bloodGlucoseMgDl: Double?` on DailyHealthData
- HK: read `.bloodGlucose`; discreteAverage milligramsPerDeciliter
- Fixture: today 98; older 85…140; nil every 5th

## Surface
- Today body after Insulin Delivery → **Blood Glucose**
- Low / Optimal / Elevated / High / Very high vs <70 / <100 / <126 / <180 / ≥180
- A11y: `body.glucose.card`, `body.glucose.baseline`, `body.glucose.spark`

## Verify
- `testBloodGlucoseTonightBaselineSurface`
- `.audit/verify-blood-glucose-tonight-baseline.png`
