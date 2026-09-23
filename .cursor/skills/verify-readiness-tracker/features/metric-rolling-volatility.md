# Metric Rolling Volatility (Honest #240)

## Intent
WHOOP / Google Health parity: show **rolling variability** on Metric Detail as a chart overlay/control.
Elevates unused `TrendAnalysisEngine.rollingVolatility` already computed onto `AnalyzedDataPoint.volatility`
but never drawn. Complements Baseline Bands / Moving Avg / Outliers toggles.

## Surface
- Today → Breakdown → metric row → Advanced Metric Detail
- Toggle chip **Volatility** (default on)
- Strip: **7-Day Volatility** (CV %) with Low / Mild / High soft bands
- A11y: `metric.chart.volatility`, `metric.chart.volatility.toggle`

## Verify
- UITest: `testMetricRollingVolatilitySurface` opens Sleep advanced detail, prefers 30D, asserts Volatility + strip; shot `.audit/verify-metric-rolling-volatility.png`

## Non-goals
- No momentum / EMA / rateOfChange overlays yet (#241+)
- No new HK quantities / bloodAlcoholContent
- No re-ship of zoneDistribution / recoveryTrajectory
