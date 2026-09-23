# Dietary Selenium Tonight|Baseline (Honest #212)

## Why
1. Prefer `dietarySelenium` — next leftover mineral after copper.
2. Higher-is-better soft ~55 mcg RDA-style goal.
3. After Dietary Copper — avoids sleep-stack / SpO2-RR / skinTemp re-chrome.

## Plumbing
- NutritionSummary: `seleniumMcg: Double?`
- HK: read `.dietarySelenium`; cumulativeSum micrograms
- Fixture: today 60; older 25…90; nil every 5th

## Surface
- Today body after Dietary Copper → **Dietary Selenium**
- Met / Building / Low / Very low vs soft 55 mcg
- A11y: `body.selenium.card`, `body.selenium.baseline`, `body.selenium.spark`

## Verify
- `testDietarySeleniumTonightBaselineSurface`
- `.audit/verify-dietary-selenium-tonight-baseline.png`
