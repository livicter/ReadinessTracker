# Dietary Energy Tonight|Baseline (Honest #172)

## Why
1. Prefer `dietaryEnergyConsumed` — unused readiness-adjacent dietary leftover (protein/caffeine/hydration already shipped).
2. Completes nutrition Tonight|Baseline set without sleep-stack duals.
3. After Protein — not chrome-only.

## Plumbing
- Model: `NutritionSummary.energyKcal: Double?`
- HK: read `.dietaryEnergyConsumed`; cumulativeSum kilocalorie
- Fixture: today 2100; older 1400…2800; nil every 5th

## Surface
- Today Body after Protein → **Dietary Energy**
- Soft 2000 kcal goal — Goal met / On track / Building / Low
- A11y: `body.energy.card`, `body.energy.baseline`, `body.energy.spark`

## Verify
- `testDietaryEnergyTonightBaselineSurface`
- `.audit/verify-dietary-energy-tonight-baseline.png`
