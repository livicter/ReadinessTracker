# Dietary Sodium Tonight|Baseline (Honest #190)

## Why
1. Prefer unused dietary leftover — `dietarySodium` (mg), hydration/readiness-adjacent.
2. Skipped height/BMI (poor Tonight UX), sleeping wrist temp (sleep-stack / skinTemp overlap), electrodermal (obscure).
3. After Dietary Sugar — lower-is-better micronutrient; avoids SpO2/RR/bodyTemp re-chrome.

## Plumbing
- NutritionSummary: `sodiumMg: Double?`
- HK: read `.dietarySodium`; cumulativeSum milligrams
- Fixture: today 1850; older 1200…2800; nil every 5th

## Surface
- Today body after Dietary Sugar → **Dietary Sodium**
- Clear / Moderate / Elevated / High vs soft 2300 mg + caution 3000
- A11y: `body.sodium.card`, `body.sodium.baseline`, `body.sodium.spark`

## Verify
- `testDietarySodiumTonightBaselineSurface`
- `.audit/verify-dietary-sodium-tonight-baseline.png`
