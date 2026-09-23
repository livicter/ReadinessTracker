# Dietary Manganese Tonight|Baseline (Honest #213)

## Why
1. Prefer `dietaryManganese` — next leftover mineral after selenium.
2. Higher-is-better soft ~2.3 mg RDA-style goal.
3. After Dietary Selenium — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `manganeseMg: Double?`
- HK: read `.dietaryManganese`; cumulativeSum milligrams
- Fixture: today 2.5; older 1.0…4.0; nil every 5th

## Surface
- Today body after Dietary Selenium → **Dietary Manganese**
- Met / Building / Low / Very low vs soft 2.3 mg
- A11y: `body.manganese.card`, `body.manganese.baseline`, `body.manganese.spark`

## Verify
- `testDietaryManganeseTonightBaselineSurface`
- `.audit/verify-dietary-manganese-tonight-baseline.png`
