# Trends Rolling Volatility Strip (Honest #259)

## Intent
Elevate unused `TrendAnalysisEngine.rollingVolatility` /
`AnalyzedDataPoint.volatility` on `TrendDetailView` primary depth series.
Parity with Advanced #240 and classic Metric Detail #248 strips.

## Surface
- History → Browse Trends → TrendDetailView → Depth Timeline card
- Toggle chip **Volatility** (default on; beside Baseline Bands)
- Strip: **7-Day Volatility** (CV %) with Low / Mild / High soft bands
- A11y: `trends.volatility`, `trends.volatility.toggle`

## Verify
- UITest: `testTrendsRollingVolatilitySurface`
- Shot: `.audit/verify-trends-rolling-volatility.png`

## Non-goals
- No momentum / Day Δ strips (→ #260+); no BAC / HK duals
