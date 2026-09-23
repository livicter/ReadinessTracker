# Classic MetricDetailView Strips (Honest #248)

## Intent
Finish classic overlay stack: Volatility / Momentum / Day Δ strips on `MetricDetailView`
(Metrics → Sleep via MetricCard). Reuses Advanced #240–#243 strip patterns over
`AnalyzedDataPoint.volatility` / `momentum` / `rateOfChange`.

## Surface
- Today → Metrics → Sleep card → MetricDetailView
- Toggle chips: Volatility, Momentum, Day Δ (default on; with MA14/EMA from #247)
- Strips above main Trend chart (same layout order as Advanced)
- A11y: `metric.classic.strips`, `.volatility` / `.momentum` / `.roc` (+ `.toggle`)

## Verify
- UITest: `testMetricClassicStripsSurface`
- Shot: `.audit/verify-metric-classic-strips.png`

## Non-goals
- No re-ship of Advanced strips or classic MA14/EMA (#247)
- No classic scrub tooltip enrichment (→ #249)
- No BAC / new HK duals
