# Trends Scrub Tooltip Enrichment (Honest #250)

## Intent
Mirror Metric Detail #246/#249 on `TrendDetailView`: scrub `ChartTooltip` surfaces
`AnalyzedDataPoint` percentDeviation, zScore, rateOfChange (Day Δ), and outlier —
previously `deviation: nil` / `isOutlier: false`.

## Surface
- History → Browse Trends → TrendDetailView → drag on Multi-Metric chart
- Primary depth metric series analyzed via `TrendAnalysisEngine.analyze`
- Tooltip: value, `% vs baseline`, `±N.Nσ`, `Day Δ ±N%`
- A11y: `trends.chart.selection`; z/Δ reuse `metric.chart.selection.zscore` / `.dayDelta`
- VoiceOver: `ChartScrubSelection.enrichedCalloutText`

## Verify
- Unit: `ChartScrubSelectionTests.testEnrichedCalloutText` (shared)
- UITest: `testTrendsScrubTooltipEnrichmentSurface`
- Shot: `.audit/verify-trends-scrub-tooltip-enrichment.png`

## Non-goals
- No Metric Detail tooltip re-ship; no classic overlays/strips
- No BAC / new HK duals
