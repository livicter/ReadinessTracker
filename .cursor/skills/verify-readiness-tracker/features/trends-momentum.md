# Trends Momentum Strip (Honest #260)

## Intent
Elevate unused `TrendAnalysisEngine.momentum` / `AnalyzedDataPoint.momentum`
on `TrendDetailView` primary depth series. Parity with Advanced #241 and
classic Metric Detail #248 momentum strip.

## Surface
- History → Browse Trends → TrendDetailView → Depth Timeline card
- Toggle chip **Momentum** (default on; beside Volatility)
- Strip: **7-Day Momentum** with zero baseline + Rising / Flat / Fading
  (respects `scrubAnalysisMetric.higherIsBetter`)
- A11y: `trends.momentum`, `trends.momentum.toggle`

## Verify
- UITest: `testTrendsMomentumSurface`
- Shot: `.audit/verify-trends-momentum.png`

## Non-goals
- No Day Δ / ROC strip yet (→ #261+); no BAC / HK duals
