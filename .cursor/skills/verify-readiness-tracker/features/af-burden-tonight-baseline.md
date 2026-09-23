# AF Burden Tonight|Baseline (Honest #168)

## Why
1. Prefer `atrialFibrillationBurden` — wireable cardio % of time in AF as Today vitals.
2. Stronger unused sparse HK than perfusion / falls for a Tonight|Baseline dual.
3. After HR Recovery — not sleep-stack; not chrome-only.

## Plumbing
- Model: `atrialFibrillationBurdenPercent: Double?` (HK % → 0…100)
- HK: read `.atrialFibrillationBurden`; discreteAverage; iOS 16+
- Fixture: today 0.4; older 0.0…3.9; nil every 5th

## Surface
- Today vitals after HR Recovery → **AF Burden**
- Clear / Low / Watch / Elevated vs ≤0.5 / ≤2 / ≤5 %
- A11y: `vitals.afBurden.card`, `vitals.afBurden.baseline`, `vitals.afBurden.spark`

## Verify
- `testAFBurdenTonightBaselineSurface`
- `.audit/verify-af-burden-tonight-baseline.png`
