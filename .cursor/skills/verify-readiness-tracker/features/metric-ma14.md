# Metric MA14 (Honest #244)

## Intent
WHOOP / Google Health / Stocks parity: dual moving-average windows on Advanced Metric Detail.
Elevates unused `AnalyzedDataPoint.movingAverage14` (computed in `analyze()`, never drawn).
Pairs with existing SMA-7 (`MA7` / former “Moving Avg”) and EMA-7.

## Surface
- Today → Breakdown → metric row → Advanced Metric Detail
- Toggle chips **MA7** + **MA14** (MA14 default on)
- Main chart: dashed recovery-tint **14-day MA** line
- Caption: "MA14 smooths longer trends than MA7"
- A11y: `metric.chart.ma14`, `metric.chart.ma14.toggle`

## Verify
- UITest: `testMetricMA14Surface`; shot `.audit/verify-metric-ma14.png`

## Non-goals
- No re-ship of EMA / momentum / volatility / rateOfChange / zoneDistribution / recoveryTrajectory
- No new HK quantities / bloodAlcoholContent
