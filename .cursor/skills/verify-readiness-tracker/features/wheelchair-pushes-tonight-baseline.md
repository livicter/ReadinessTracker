# Wheelchair Pushes Tonight|Baseline (Honest #171)

## Why
1. Prefer `pushCount` — unused wheelchair mobility count; readiness/mobility-adjacent over inhaler/insulin.
2. Completes falls / steadiness mobility cluster without sleep-stack duals.
3. After Falls — not chrome-only.

## Plumbing
- Model: `pushCount: Double?`
- HK: read `.pushCount`; cumulativeSum count
- Fixture: today 1240; older 200…3200; nil every 5th

## Surface
- Today body after Falls → **Wheelchair Pushes**
- None / Light / Steady / Active vs ≤0 / <500 / <2000 / ≥2000
- A11y: `body.pushes.card`, `body.pushes.baseline`, `body.pushes.spark`

## Verify
- `testWheelchairPushesTonightBaselineSurface`
- `.audit/verify-wheelchair-pushes-tonight-baseline.png`
