# Classic Scrub Tooltip Enrichment (Honest #249)

## Intent
Mirror Advanced #246 on classic `MetricDetailView`: scrub `ChartTooltip` surfaces
`AnalyzedDataPoint` percentDeviation, zScore, rateOfChange (Day Δ), and outlier —
previously called with `deviation: nil` / `isOutlier: false`.

## Surface
- Today → Metrics → Sleep card → MetricDetailView → drag on Trend chart
- Tooltip: value, `% vs baseline`, `±N.Nσ`, `Day Δ ±N%` (+ Outlier when |z|>2)
- A11y: `metric.classic.selection`; z/Δ reuse shared `metric.chart.selection.zscore` / `.dayDelta`
- VoiceOver: `ChartScrubSelection.enrichedCalloutText`

## Verify
- Unit: `ChartScrubSelectionTests.testEnrichedCalloutText` (shared)
- UITest: `testMetricClassicScrubTooltipEnrichmentSurface`
- Shot: `.audit/verify-metric-classic-scrub-tooltip-enrichment.png`

## Non-goals
- No Advanced tooltip re-ship; no classic overlay/strip re-ship
- No BAC / new HK duals
