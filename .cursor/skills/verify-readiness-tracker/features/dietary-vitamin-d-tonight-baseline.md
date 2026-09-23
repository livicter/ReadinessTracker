# Vitamin D Tonight|Baseline (Honest #195)

## Why
1. Prefer `dietaryVitaminD` — clear vitamin leftover after vitamin C.
2. Higher-is-better soft ~600 IU RDA-style goal.
3. After Vitamin C — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminDIU: Double?`
- HK: read `.dietaryVitaminD`; cumulativeSum internationalUnit
- Fixture: today 720; older 300…1000; nil every 5th

## Surface
- Today body after Vitamin C → **Vitamin D**
- Met / Building / Low / Very low vs soft 600 IU
- A11y: `body.vitamind.card`, `body.vitamind.baseline`, `body.vitamind.spark`

## Verify
- `testDietaryVitaminDTonightBaselineSurface`
- `.audit/verify-dietary-vitamin-d-tonight-baseline.png`
