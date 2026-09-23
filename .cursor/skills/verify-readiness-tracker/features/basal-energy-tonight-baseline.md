# Basal Energy Tonight|Baseline (Honest #184)

## Why
1. Prefer `basalEnergyBurned` — unused resting kcal dual; Active Calories already ships active burn.
2. Completes energy pair without sleep-stack duals or re-chroming active wells.
3. After Active Calories — not chrome-only.

## Plumbing
- Model: `basalEnergyKcal: Double?` on DailyHealthData
- HK: read `.basalEnergyBurned`; cumulativeSum kilocalorie
- Fixture: today 1680; older 1500…1850; nil every 5th

## Surface
- Today body after Active Calories → **Basal Energy**
- Steady / Solid / Building / Low vs baseline & soft 1600 kcal
- A11y: `body.basal.card`, `body.basal.baseline`, `body.basal.spark`

## Verify
- `testBasalEnergyTonightBaselineSurface`
- `.audit/verify-basal-energy-tonight-baseline.png`
