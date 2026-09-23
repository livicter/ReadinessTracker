# Today QuickTrendCard header wells

## Sub-features
- Quick Trends tiles on Today
- Leading SF Symbol in circular tint well

## How to get to it (user POV)
1. Open Today
2. Scroll to Quick Trends
3. Each trend card title shows a circular tint well

## Driving it with the harness
- UITest: `SurfacesUITests.testQuickTrendsSurface`
- Captures `.audit/verify-quick-trends.png`

## Gotchas
- Keep strength Capsule and % change row
- Do not invent Fitness+ chrome
