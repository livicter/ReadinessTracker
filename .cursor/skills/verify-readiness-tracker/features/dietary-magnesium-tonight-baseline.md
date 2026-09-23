# Dietary Magnesium Tonight|Baseline (Honest #199)

## Why
1. Prefer `dietaryMagnesium` — strong mineral Today UX after calcium/iron.
2. Higher-is-better soft ~400 mg RDA-style goal.
3. After Dietary Calcium — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `magnesiumMg: Double?`
- HK: read `.dietaryMagnesium`; cumulativeSum milligrams
- Fixture: today 380; older 180…520; nil every 5th

## Surface
- Today body after Dietary Calcium → **Dietary Magnesium**
- Met / Building / Low / Very low vs soft 400 mg
- A11y: `body.magnesium.card`, `body.magnesium.baseline`, `body.magnesium.spark`

## Verify
- `testDietaryMagnesiumTonightBaselineSurface`
- `.audit/verify-dietary-magnesium-tonight-baseline.png`
