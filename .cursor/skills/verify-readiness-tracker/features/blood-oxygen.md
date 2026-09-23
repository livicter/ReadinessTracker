# Blood Oxygen (Honest #107)

## Intent
WHOOP / Google Health–style SpO₂ glance on Today WHOOP stack and Recovery & Strain Advanced Metrics. Wires `DailyHealthData.bloodOxygen` that previously only fed the 5% breakdown bar and body metric tile.

## Surface
- Today → WHOOP stack → **Blood Oxygen** (after Skin Temperature)
- Recovery & Strain → Advanced Metrics → Blood Oxygen
- A11y: `blood.oxygen.card`, `blood.oxygen.baseline`, `blood.oxygen.spark`

## Verify
- UITest: `testBloodOxygenSurface` soft-asserts title + Tonight|Baseline; shot `.audit/verify-blood-oxygen.png`
- Fixture varies nightly SpO₂ (today 97%)

## Soft bands
- Absolute: <95% Below Typical, <92% Low
- vs baseline: ±1 pp Normal band on chart

## Non-goals
- No new readiness weight (still 5% via existing spo2Score)
- No pulse-ox live streaming UI
