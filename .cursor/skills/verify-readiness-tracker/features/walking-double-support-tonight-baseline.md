# Walking Double Support Tonight|Baseline (Honest #145)

## Why
1. Prefer unused sparse gait HK: `walkingDoubleSupportPercentage` over asymmetry/speed (strongest signal of both-feet contact).
2. Body stack after Walking Distance — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `walkingDoubleSupportPercent: Double?` (0…100)
- HK: read `.walkingDoubleSupportPercentage`; discreteAverage; fraction→percent
- Fixture: today 27.5; older 22…37; nil every 5th

## Surface
- Today body after Walking Distance → **Double Support**
- Typical / Dynamic / Elevated / High vs ~20–35% band
- A11y: `body.doubleSupport.card`, `body.doubleSupport.baseline`, `body.doubleSupport.spark`

## Verify
- `testWalkingDoubleSupportTonightBaselineSurface`
- `.audit/verify-walking-double-support-tonight-baseline.png`
