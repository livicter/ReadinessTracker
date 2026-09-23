# Dietary Sugar Tonight|Baseline (Honest #176)

## Why
1. Prefer `dietarySugar` — next unused dietary leftover after fiber.
2. Completes nutrition intake duals before alcohol count; lower-is-better like caffeine.
3. After Dietary Fiber — not chrome-only.

## Plumbing
- Model: `NutritionSummary.sugarGrams: Double?`
- HK: read `.dietarySugar`; cumulativeSum gram
- Fixture: today 42; older 15…90; nil every 5th

## Surface
- Today Body after Dietary Fiber → **Dietary Sugar**
- Soft 50 g / caution 75 g — Clear / Moderate / Elevated / High
- A11y: `body.sugar.card`, `body.sugar.baseline`, `body.sugar.spark`

## Verify
- `testDietarySugarTonightBaselineSurface`
- `.audit/verify-dietary-sugar-tonight-baseline.png`
