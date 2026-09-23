# Classic Distribution Histogram (Honest #252)

## Intent
Presentation parity: wire existing `DistributionHistogramView` onto classic
`MetricDetailView` (Advanced already shows it when ≥5 days).

## Surface
- Today → Metrics → Sleep card → MetricDetailView
- **Distribution** card after Statistics when period has ≥5 points
- A11y: `metric.classic.histogram`

## Verify
- UITest: `testMetricClassicDistributionHistogramSurface`
- Shot: `.audit/verify-metric-classic-distribution-histogram.png`

## Non-goals
- No Advanced histogram re-ship; no MA7 toggle / Watch duals (→ #253+)
- No BAC / new HK duals
