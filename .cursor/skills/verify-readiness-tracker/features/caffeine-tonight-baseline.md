# Caffeine Tonight|Baseline (Honest #125)

## Intent
Elevate `nutrition.caffeineMg` into a WHOOP-style **Tonight | Baseline** dual on Today Body next to Hydration. Soft 200 mg limit matches NutritionSummary / coaching. NutritionSummaryCard caffeine well (#106) stays strain-detail glance — not re-chromed. Hydration companion caption may still mention caffeine.

## Surface
- Today → Body → **Caffeine** (after Hydration)
- Tonight mg vs 7-day baseline; Clear / Moderate / Elevated / High; 7-day spark
- A11y: `body.caffeine.card`, `body.caffeine.baseline`, `body.caffeine.spark`

## Verify
- UITest: `testCaffeineTonightBaselineSurface`; shot `.audit/verify-caffeine-tonight-baseline.png`
- Fixture: today 90 mg; older days 60…239 mg (already varied in DataStore)

## Non-goals
- No re-chrome of NutritionSummaryCard wells
- SpO₂ not in scope (#107 already elevated)
