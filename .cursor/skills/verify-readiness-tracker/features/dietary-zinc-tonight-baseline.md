# Dietary Zinc Tonight|Baseline (Honest #200)

## Why
1. Prefer `dietaryZinc` — clear leftover mineral after magnesium.
2. Higher-is-better soft ~11 mg RDA-style goal.
3. After Dietary Magnesium — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `zincMg: Double?`
- HK: read `.dietaryZinc`; cumulativeSum milligrams
- Fixture: today 10.5; older 4.0…16.0; nil every 5th

## Surface
- Today body after Dietary Magnesium → **Dietary Zinc**
- Met / Building / Low / Very low vs soft 11 mg
- A11y: `body.zinc.card`, `body.zinc.baseline`, `body.zinc.spark`

## Verify
- `testDietaryZincTonightBaselineSurface`
- `.audit/verify-dietary-zinc-tonight-baseline.png`
