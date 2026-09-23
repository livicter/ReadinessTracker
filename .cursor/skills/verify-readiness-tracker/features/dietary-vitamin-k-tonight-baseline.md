# Vitamin K Tonight|Baseline (Honest #204)

## Why
1. Prefer `dietaryVitaminK` — clear leftover vitamin after vitamin E.
2. Higher-is-better soft ~120 mcg RDA-style goal.
3. After Vitamin E — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminKMcg: Double?`
- HK: read `.dietaryVitaminK`; cumulativeSum micrograms
- Fixture: today 130; older 40…200; nil every 5th

## Surface
- Today body after Vitamin E → **Vitamin K**
- Met / Building / Low / Very low vs soft 120 mcg
- A11y: `body.vitamink.card`, `body.vitamink.baseline`, `body.vitamink.spark`

## Verify
- `testDietaryVitaminKTonightBaselineSurface`
- `.audit/verify-dietary-vitamin-k-tonight-baseline.png`
