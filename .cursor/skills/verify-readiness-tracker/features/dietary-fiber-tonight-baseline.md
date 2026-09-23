# Dietary Fiber Tonight|Baseline (Honest #175)

## Why
1. Prefer `dietaryFiber` — next unused dietary leftover after fat.
2. Completes nutrition macros/fiber cluster without sleep-stack duals.
3. After Dietary Fat — not chrome-only.

## Plumbing
- Model: `NutritionSummary.fiberGrams: Double?`
- HK: read `.dietaryFiber`; cumulativeSum gram
- Fixture: today 28; older 12…40; nil every 5th

## Surface
- Today Body after Dietary Fat → **Dietary Fiber**
- Soft 30 g goal — Goal met / On track / Building / Low
- A11y: `body.fiber.card`, `body.fiber.baseline`, `body.fiber.spark`

## Verify
- `testDietaryFiberTonightBaselineSurface`
- `.audit/verify-dietary-fiber-tonight-baseline.png`
