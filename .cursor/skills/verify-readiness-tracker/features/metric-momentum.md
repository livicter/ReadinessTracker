# Metric Momentum (Honest #241)

## Intent
WHOOP / Google Health parity: show **windowed momentum** (% change over 7 days) on Advanced Metric Detail.
Elevates unused `TrendAnalysisEngine.momentum` onto `AnalyzedDataPoint.momentum` + chart strip.
Complements Volatility (#240) / Baseline Bands / Moving Avg / Outliers.

## Surface
- Today → Breakdown → metric row → Advanced Metric Detail
- Toggle chip **Momentum** (default on)
- Strip: **7-Day Momentum** with zero baseline + Rising / Flat / Fading soft bands (respects higherIsBetter)
- A11y: `metric.chart.momentum`, `metric.chart.momentum.toggle`

## Verify
- UITest: `testMetricMomentumSurface`; shot `.audit/verify-metric-momentum.png`

## Non-goals
- No EMA / rateOfChange overlays yet (#242+)
- No new HK quantities / bloodAlcoholContent
- No re-ship of zoneDistribution / recoveryTrajectory / rollingVolatility
