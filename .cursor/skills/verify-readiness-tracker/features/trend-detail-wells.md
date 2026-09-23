# Trend Detail summary wells

## Sub-features
- Trend Detail metric summary cards (Current / Avg / Best)
- Leading SF Symbol circular tint wells

## How to get to it (user POV)
1. History → Browse Trends
2. Open Trends detail
3. Summary cards show circular tint wells on metric icons

## Driving it with the harness
- UITest: `SurfacesUITests.testTrendsDetailSurface`
- Captures `.audit/verify-trends.png`

## Gotchas
- Metric toggle chips stay Capsules (filter chips)
- Do not invent Fitness+ chrome
