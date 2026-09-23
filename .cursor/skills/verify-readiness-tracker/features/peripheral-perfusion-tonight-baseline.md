# Peripheral Perfusion Index Tonight|Baseline (Honest #169)

## Why
1. Prefer `peripheralPerfusionIndex` — SpO2-adjacent perfusion % for Today vitals.
2. Stronger unused sparse HK than falls count for a Tonight|Baseline dual.
3. After AF Burden — not sleep-stack; not chrome-only.

## Plumbing
- Model: `peripheralPerfusionIndexPercent: Double?`
- HK: `.peripheralPerfusionIndex` discreteAverage
- Fixture: today 3.2; older 0.8…5.7; nil every 5th

## Surface
- **Perfusion Index** after AF Burden
- Strong / Solid / Fair / Low vs ≥5 / ≥2 / ≥0.5 %
- A11y: `vitals.ppi.*`

## Verify
- `testPeripheralPerfusionTonightBaselineSurface`
- `.audit/verify-peripheral-perfusion-tonight-baseline.png`
