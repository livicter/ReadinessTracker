# Classic MetricDetailView MA14 + EMA (Honest #247)

## Intent
Presentation parity: classic `MetricDetailView` (Metrics → Sleep via MetricCard) consumes
unused `AnalyzedDataPoint.movingAverage14` + `ema7` already elevated on Advanced.
Subset only — Volatility / Momentum / Day Δ strips deferred to #248+.

## Surface
- Today → Metrics → Sleep card → MetricDetailView
- Toggle chips **MA14** + **EMA** (default on); prefer 30D for MA14 coverage
- Main Trend chart: dashed recovery-tint MA14 + HRV-tint EMA lines (same styling as Advanced)
- A11y: `metric.classic.overlays`, `.ma14` / `.ma14.toggle`, `.ema` / `.ema.toggle`

## Verify
- UITest: `testMetricClassicOverlaysMA14EMASurface`
- Shot: `.audit/verify-metric-classic-overlays-ma14-ema.png`

## Non-goals
- No Advanced-only re-ship; no Volatility/Momentum/Day Δ strips (→ #248)
- No classic scrub tooltip enrichment (→ #248 runner-up)
- No BAC / new HK duals
