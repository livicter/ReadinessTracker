# Protein Tonight|Baseline (Honest #126)

## Intent
Elevate `nutrition.proteinGrams` into a WHOOP-style **Tonight | Baseline** dual on Today Body next to Hydration / Caffeine. Soft 100 g goal matches NutritionSummary / coaching. NutritionSummaryCard protein well (#106) stays strain-detail glance — not re-chromed.

## Surface
- Today → Body → **Protein** (after Caffeine)
- Tonight g vs 7-day baseline; Met / On track / Building / Low; 7-day spark
- A11y: `body.protein.card`, `body.protein.baseline`, `body.protein.spark`

## Verify
- UITest: `testProteinTonightBaselineSurface`; shot `.audit/verify-protein-tonight-baseline.png`
- Fixture: today 95 g; older days 70…129 g (already varied in DataStore)

## Non-goals
- No re-chrome of NutritionSummaryCard wells
- No sleep-stack dual clones
