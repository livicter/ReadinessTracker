# Metric Rate of Change (Honest #243)

## Intent
WHOOP / Google Health parity: show **day-over-day % change** on Advanced Metric Detail.
Elevates unused `AnalyzedDataPoint.rateOfChange` from `TrendAnalysisEngine.rateOfChange`
(computed in `analyze()` but never drawn). Distinct from 7-day Momentum (#241).

## Surface
- Today → Breakdown → metric row → Advanced Metric Detail
- Toggle chip **Day Δ** (default on)
- Strip: **Day-over-Day Change** bar chart with zero line + Up / Flat / Down soft bands
- A11y: `metric.chart.roc`, `metric.chart.roc.toggle`

## Verify
- UITest: `testMetricRateOfChangeSurface`; shot `.audit/verify-metric-rate-of-change.png`

## Non-goals
- No re-ship of EMA / momentum / volatility / zoneDistribution / recoveryTrajectory
- No new HK quantities / bloodAlcoholContent
