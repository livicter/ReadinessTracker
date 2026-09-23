# Dietary Cholesterol Tonight|Baseline (Honest #192)

## Why
1. Prefer `dietaryCholesterol` — clear intake UX leftover after Na/K.
2. Lower-is-better soft 300 mg / caution 400 mg.
3. After Dietary Potassium — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `cholesterolMg: Double?`
- HK: read `.dietaryCholesterol`; cumulativeSum milligrams
- Fixture: today 220; older 120…400; nil every 5th

## Surface
- Today body after Dietary Potassium → **Dietary Cholesterol**
- Clear / Moderate / Elevated / High vs soft 300 mg
- A11y: `body.cholesterol.card`, `body.cholesterol.baseline`, `body.cholesterol.spark`

## Verify
- `testDietaryCholesterolTonightBaselineSurface`
- `.audit/verify-dietary-cholesterol-tonight-baseline.png`
