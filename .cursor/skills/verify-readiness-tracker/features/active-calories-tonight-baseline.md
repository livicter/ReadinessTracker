# Active Calories Tonight|Baseline (Honest #131)

## Intent
Elevate HealthKit / Apple Watch `activeCalories` (`activeEnergyBurned`) into a
WHOOP-style **Tonight | Baseline** dual on Today Body after Steps. Soft 500 cal
goal matches MetricType “Active” band. Body calories tile + Metrics MetricCard
stay glance chrome — not re-chromed. Watch snapshot already carries this field.

## Why this signal
Check-in stack is largely covered. VO2 / walking HR are not in `DailyHealthData`.
`activeCalories` is real HK + Watch payload, fixture-varied, and still dual-less
vs Steps / Workout Minutes / TRIMP.

## Surface
- Today → Body → **Active Calories** (after Steps, before Hydration)
- Tonight cal vs 7-day baseline; Sedentary / Light / Active
- A11y: `body.calories.card`, `body.calories.baseline`, `body.calories.spark`

## Verify
- UITest: `testActiveCaloriesTonightBaselineSurface`
- Shot: `.audit/verify-active-calories-tonight-baseline.png`
- Fixture: today 420 cal; older 280…559 (DataStore)

## Non-goals
- No re-chrome of Body calories tile / Metrics wells
- No sleep-stack dual clones
