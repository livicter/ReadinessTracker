# Body Mass Tonight|Baseline (Honest #181)

## Why
1. Prefer `bodyMass` — unused body-composition after blood glucose.
2. Latest kg vs 7-day baseline; readiness-adjacent composition without sleep-stack duals.
3. After Blood Glucose — not chrome-only.

## Plumbing
- Model: `bodyMassKg: Double?` on DailyHealthData
- HK: read `.bodyMass`; mostRecent kilogram
- Fixture: today 72.4; older 71.0…74.0; nil every 5th

## Surface
- Today body after Blood Glucose → **Body Mass**
- Steady / Higher / Lower vs |Δ|<0.5 / up / down
- A11y: `body.mass.card`, `body.mass.baseline`, `body.mass.spark`

## Verify
- `testBodyMassTonightBaselineSurface`
- `.audit/verify-body-mass-tonight-baseline.png`
