# Trends Classify Trend + Histogram (Honest #255)

## Intent
Elevate unused `TrendAnalysisEngine.classifyTrend` on `TrendDetailView` primary
depth series (Metric Detail #253 parity). Also wire existing
`DistributionHistogramView` when ≥5 days.

## Surface
- History → Browse Trends → TrendDetailView
- Strength callout below summary (TrendStrength + R²)
- Distribution card after depth timeline (≥5 points)
- A11y: `trends.trend.strength`, `trends.histogram`

## Verify
- UITest: `testTrendsClassifyTrendStrengthSurface`
- Shot: `.audit/verify-trends-classify-trend-strength.png`

## Non-goals
- No classic MA7 toggle; no BAC / HK duals
