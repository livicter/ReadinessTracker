# Trends Day Δ Strip (Honest #261)

## Intent
Elevate unused `AnalyzedDataPoint.rateOfChange` on `TrendDetailView` primary
depth series as a Day Δ strip. Completes the classic #248 strip triad on Trends
(Volatility #259, Momentum #260, Day Δ #261).

## Surface
- History → Browse Trends → TrendDetailView → Depth Timeline card
- Toggle chip **Day Δ** (default on; beside Momentum)
- Strip: **Day-over-Day Change** bar chart + Up / Flat / Down
  (respects `scrubAnalysisMetric.higherIsBetter`)
- A11y: `trends.dayDelta`, `trends.dayDelta.toggle`

## Verify
- UITest: `testTrendsDayDeltaSurface`
- Shot: `.audit/verify-trends-day-delta.png`

## Non-goals
- No MA14/EMA overlays on Trends multi-metric chart; no BAC / HK duals
