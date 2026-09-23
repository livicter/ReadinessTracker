# Nutrition Summary (Honest #106)

## Intent
WHOOP / Google Health–style nutrition glance on Recovery & Strain: water, caffeine, and protein with soft targets aligned to coaching cues. Elevates sparse `NutritionRow` list into `NutritionSummaryCard` with Apple circular tint wells and progress capsules.

## Surface
- Today → Balance / Recovery & Strain → **Nutrition**
- A11y: `strain.nutrition`, `strain.nutrition.water|caffeine|protein`

## Verify
- UITest: `testNutritionSummarySurface` soft-asserts title + metric labels; shot `.audit/verify-nutrition.png`
- Fixture seeds `NutritionSummary(waterLiters: 2.1, caffeineMg: 90, proteinGrams: 95)`

## Soft targets
- Water goal 2.5 L (low cue under 1.5 L)
- Caffeine limit 200 mg (high cue at/above 250 mg)
- Protein goal 100 g

## Non-goals
- No new readiness score term
- No meal logging / barcode UX
