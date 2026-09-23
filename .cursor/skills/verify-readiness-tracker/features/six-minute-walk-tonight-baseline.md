# Six-Minute Walk Tonight|Baseline (Honest #151)

## Why
1. Prefer `sixMinuteWalkTestDistance` after stair ascent/descent — unused clinical mobility with clear readiness meaning (prefer over swim distance / underwater depth / cycling cadence).
2. Body stack after Stair Descent — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `sixMinuteWalkDistanceMeters: Double?`
- HK: read `.sixMinuteWalkTestDistance`; discreteAverage; meters
- Fixture: today 545; older 420…599; nil every 5th

## Surface
- Today body after Stair Descent → **Six-Minute Walk**
- Strong / Solid / Fair / Low vs ≥500 / ≥400 / ≥300 m
- A11y: `body.sixMinuteWalk.card`, `body.sixMinuteWalk.baseline`, `body.sixMinuteWalk.spark`

## Verify
- `testSixMinuteWalkTonightBaselineSurface`
- `.audit/verify-six-minute-walk-tonight-baseline.png`
