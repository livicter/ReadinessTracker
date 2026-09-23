# Vitamin C Tonight|Baseline (Honest #194)

## Why
1. Prefer `dietaryVitaminC` — clear vitamin leftover after sat fat.
2. Higher-is-better soft ~90 mg RDA-style goal.
3. After Saturated Fat — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `vitaminCMg: Double?`
- HK: read `.dietaryVitaminC`; cumulativeSum milligrams
- Fixture: today 95; older 40…140; nil every 5th

## Surface
- Today body after Saturated Fat → **Vitamin C**
- Met / Building / Low / Very low vs soft 90 mg
- A11y: `body.vitaminc.card`, `body.vitaminc.baseline`, `body.vitaminc.spark`

## Verify
- `testDietaryVitaminCTonightBaselineSurface`
- `.audit/verify-dietary-vitamin-c-tonight-baseline.png`
