# Hydration Tonight|Baseline (Honest #122)

## Intent
Elevate `nutrition.waterLiters` into a WHOOP-style **Tonight | Baseline** dual on Today Body. NutritionSummaryCard (#106) stays the Recovery & Strain detail glance with circular wells — not re-chromed. Body water/caffeine/protein tiles remain glance chips.

## Surface
- Today → Body → **Hydration** (after Steps dual)
- Tonight vs 7-day water (L); soft 2.5 L goal; status from coaching thresholds (water / caffeine / protein)
- Companion caption: caffeine mg · protein g
- A11y: `body.hydration.card`, `body.hydration.baseline`, `body.hydration.spark`

## Verify
- UITest: `testHydrationTonightBaselineSurface`; shot `.audit/verify-hydration-tonight-baseline.png`
- Fixture: today 2.1 L / 90 mg / 95 g; older days vary water 1.4…2.5 L for spark shape

## Non-goals
- No re-chrome of NutritionSummaryCard metric wells
- No new readiness score term
