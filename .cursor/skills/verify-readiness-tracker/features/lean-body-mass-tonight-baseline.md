# Lean Body Mass Tonight|Baseline (Honest #182)

## Why
1. Prefer `leanBodyMass` — next unused body-composition after bodyMass.
2. Latest kg vs 7-day baseline; readiness-adjacent without sleep-stack duals.
3. After Body Mass — not chrome-only.

## Plumbing
- Model: `leanBodyMassKg: Double?` on DailyHealthData
- HK: read `.leanBodyMass`; mostRecent kilogram
- Fixture: today 56.8; older 55.5…58.0; nil every 5th

## Surface
- Today body after Body Mass → **Lean Body Mass**
- Steady / Up / Down vs |Δ|<0.3 / up / down
- A11y: `body.lean.card`, `body.lean.baseline`, `body.lean.spark`

## Verify
- `testLeanBodyMassTonightBaselineSurface`
- `.audit/verify-lean-body-mass-tonight-baseline.png`
