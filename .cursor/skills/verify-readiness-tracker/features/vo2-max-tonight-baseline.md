# VO₂ Max Tonight|Baseline (Honest #133)

## Intent
Wire HealthKit `vo2Max` into `DailyHealthData` + HK auth/fetch, then elevate as
a WHOOP-style **Tonight | Baseline** dual on Today vitals after Peak HR.
Stronger GHealth/WHOOP cardio-fitness parity than walking HR. Not a sleep dual.

## Plumbing
- Model: `DailyHealthData.vo2Max: Double?` (Codable encode/decode)
- HK: read `HKQuantityTypeIdentifier.vo2Max`; `fetchVO2Max()` latest sample
- Fixture: today 48.5; older 42.0…50.9; nil every 5th (sim has no VO2 samples)

## Surface
- Today → vitals → **VO₂ Max** (after Peak Heart Rate)
- Tonight ml/kg·min vs 7-day avg; Elite / Strong / Fair / Building
- A11y: `vitals.vo2.card`, `vitals.vo2.baseline`, `vitals.vo2.spark`

## Verify
- UITest: `testVO2MaxTonightBaselineSurface`
- Shot: `.audit/verify-vo2-max-tonight-baseline.png`

## Non-goals
- No sleep-stack dual clones
- No re-chrome of Peak HR / SpO2 wells only
