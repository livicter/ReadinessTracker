# Metric EMA (Honest #242)

## Intent
WHOOP / Google Health / Stocks parity: show **7-day exponential moving average** on Advanced Metric Detail.
Elevates unused `AnalyzedDataPoint.ema7` from `TrendAnalysisEngine.exponentialMovingAverage`
(computed in `analyze()` but never drawn — only SMA "Moving Avg" was wired).

## Surface
- Today → Breakdown → metric row → Advanced Metric Detail
- Toggle chip **EMA** (default on)
- Main chart overlay: dashed green **7-day EMA** line (distinct from SMA dashes)
- Caption: "EMA responds faster than SMA to recent change"
- A11y: `metric.chart.ema`, `metric.chart.ema.toggle`

## Verify
- UITest: `testMetricEMASurface`; shot `.audit/verify-metric-ema.png`

## Non-goals
- No rateOfChange overlay yet (#243)
- No re-ship of volatility / momentum / zoneDistribution / recoveryTrajectory
- No new HK quantities / bloodAlcoholContent
