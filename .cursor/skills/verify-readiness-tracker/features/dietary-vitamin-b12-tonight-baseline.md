# Vitamin B12 Tonight|Baseline (Honest #196)

## Why
1. Prefer `dietaryVitaminB12` — clear vitamin leftover after vitamin D.
2. Higher-is-better soft ~2.4 mcg RDA-style goal.
3. After Vitamin D — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminB12Mcg: Double?`
- HK: read `.dietaryVitaminB12`; cumulativeSum micrograms
- Fixture: today 2.8; older 1.0…4.0; nil every 5th

## Surface
- Today body after Vitamin D → **Vitamin B12**
- Met / Building / Low / Very low vs soft 2.4 mcg
- A11y: `body.b12.card`, `body.b12.baseline`, `body.b12.spark`

## Verify
- `testDietaryVitaminB12TonightBaselineSurface`
- `.audit/verify-dietary-vitamin-b12-tonight-baseline.png`
