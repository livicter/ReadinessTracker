# Dietary Iron Tonight|Baseline (Honest #197)

## Why
1. Prefer `dietaryIron` — clear micronutrient Today UX after vitamins.
2. Higher-is-better soft ~18 mg RDA-style goal.
3. After Vitamin B12 — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `ironMg: Double?`
- HK: read `.dietaryIron`; cumulativeSum milligrams
- Fixture: today 16; older 6…24; nil every 5th

## Surface
- Today body after Vitamin B12 → **Dietary Iron**
- Met / Building / Low / Very low vs soft 18 mg
- A11y: `body.iron.card`, `body.iron.baseline`, `body.iron.spark`

## Verify
- `testDietaryIronTonightBaselineSurface`
- `.audit/verify-dietary-iron-tonight-baseline.png`
