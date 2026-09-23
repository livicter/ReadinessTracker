# Saturated Fat Tonight|Baseline (Honest #193)

## Why
1. Prefer `dietaryFatSaturated` — clear intake leftover after cholesterol.
2. Lower-is-better soft 20 g / caution 30 g.
3. After Dietary Cholesterol — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `saturatedFatGrams: Double?`
- HK: read `.dietaryFatSaturated`; cumulativeSum grams
- Fixture: today 18; older 8…32; nil every 5th

## Surface
- Today body after Dietary Cholesterol → **Saturated Fat**
- Clear / Moderate / Elevated / High vs soft 20 g
- A11y: `body.satfat.card`, `body.satfat.baseline`, `body.satfat.spark`

## Verify
- `testDietarySatFatTonightBaselineSurface`
- `.audit/verify-dietary-sat-fat-tonight-baseline.png`
