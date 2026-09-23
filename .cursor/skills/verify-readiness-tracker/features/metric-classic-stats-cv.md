# Classic Statistics CV% (Honest #254)

## Intent
Elevate unused `TrendAnalysisEngine.coefficientOfVariation` on classic
`MetricDetailView` Statistics grid. Advanced already shows Volatility CV%;
classic previously showed Average/Best/Worst/Data Points only.

## Surface
- Today → Metrics → Sleep → MetricDetailView → Statistics
- Fourth tile: **Volatility** `N%` unit **CV**
- A11y: `metric.classic.stats.cv`

## Verify
- UITest: `testMetricClassicStatsCVSurface`
- Shot: `.audit/verify-metric-classic-stats-cv.png`

## Non-goals
- No Advanced stats re-ship; no Trends classifyTrend/histogram (→ #255+)
- No BAC / HK duals
