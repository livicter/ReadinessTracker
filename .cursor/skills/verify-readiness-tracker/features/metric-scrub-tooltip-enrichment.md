# Metric Scrub Tooltip Enrichment (Honest #246)

## Intent
Apple Health–style chart inspect: Advanced Metric Detail scrub tooltip now surfaces
**z-score** and **day-over-day Δ** already on `AnalyzedDataPoint`, not only percentDeviation + outlier.

## Surface
- Today → Breakdown → metric → Advanced Metric Detail → drag on chart
- Tooltip lines: value, `% vs baseline`, `±N.Nσ`, `Day Δ ±N%`
- A11y: `metric.chart.selection` (+ `.zscore` / `.dayDelta` when children exposed)
- `ChartScrubSelection.enrichedCalloutText` for VoiceOver

## Verify
- Unit: `ChartScrubSelectionTests.testEnrichedCalloutText`
- UITest: `testMetricScrubTooltipEnrichmentSurface`; shot `.audit/verify-metric-scrub-tooltip-enrichment.png`

## Non-goals
- No classic MetricDetailView overlay stack (#247+)
- No re-ship of MA/EMA/volatility/zone cards
