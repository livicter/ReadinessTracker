# Active Calories card → MetricDetail nav (Honest #369)

## Intent
WHOOP `active.calories.card` was display-only on Body stack. Wire to classic
`MetricDetailView(.activeCalories)` for unused presentation parity with Blood Oxygen
(#358) and Resting HR (#367). Chart/spark `allowsHitTesting(false)`. Keep SurfaceID
`active.calories.card` / `metric.detail`. No new HK / Google Health.

## Surface
- Today Body → Active Calories card → MetricDetailView (title Active Calories)
- A11y: `active.calories.card` → `metric.detail`

## Verify
- UITest: `testActiveCaloriesCardMetricDetailNavSurface`
- Shot: `.audit/verify-active-calories-metric-detail.png`

## Non-goals
- No Trends/BAC; no Secrets; no Connect
