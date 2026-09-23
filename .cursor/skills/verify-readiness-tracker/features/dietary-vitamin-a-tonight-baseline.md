# Vitamin A Tonight|Baseline (Honest #202)

## Why
1. Prefer `dietaryVitaminA` — clear leftover vitamin after folate.
2. Higher-is-better soft ~900 mcg RDA-style goal.
3. After Dietary Folate — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminAMcg: Double?`
- HK: read `.dietaryVitaminA`; cumulativeSum micrograms
- Fixture: today 950; older 400…1400; nil every 5th

## Surface
- Today body after Dietary Folate → **Vitamin A**
- Met / Building / Low / Very low vs soft 900 mcg
- A11y: `body.vitamina.card`, `body.vitamina.baseline`, `body.vitamina.spark`

## Verify
- `testDietaryVitaminATonightBaselineSurface`
- `.audit/verify-dietary-vitamin-a-tonight-baseline.png`
