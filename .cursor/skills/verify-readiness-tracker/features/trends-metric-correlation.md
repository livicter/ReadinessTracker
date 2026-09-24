# Trends MetricCorrelationView (Honest #266)

## Intent
Replace bespoke Trends “Sleep vs Recovery” scatter with shared
`MetricCorrelationView` (Pearson `pearsonCorrelation`) — classic/Advanced
Metric Detail parity. Elevates unused shared engine presentation on Trends.

## Surface
- History → Browse Trends → TrendDetailView
- Correlation card when `filteredHistory.count >= 3`
- Pair from primary depth metric (e.g. Sleep↔HRV, RHR↔HRV, Cals↔Sleep)
- A11y: `trends.metricCorrelation`

## Verify
- UITest: `testTrendsMetricCorrelationSurface`
- Shot: `.audit/verify-trends-metric-correlation.png`

## Non-goals
- No classic MA7 toggle; no BAC / HK duals; no Day Detail duals yet
