# Trends Statistics CV% (Honest #256)

## Intent
Elevate unused `TrendAnalysisEngine.coefficientOfVariation` on
`TrendDetailView` summary stats. Advanced + classic Metric Detail (#254)
already show Volatility CV%; Trends had Avg/Min/Max/Change only.

## Surface
- History → Browse Trends → TrendDetailView → summary card
- Volatility tile: `N%` (CV)
- A11y: `trends.stats.cv`

## Verify
- UITest: `testTrendsStatsCVSurface`
- Shot: `.audit/verify-trends-stats-cv.png`

## Non-goals
- No OutlierCallout list (→ #257+); no BAC / HK duals
