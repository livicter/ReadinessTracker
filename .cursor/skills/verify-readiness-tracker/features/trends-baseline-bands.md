# Trends Baseline Bands ±2σ (Honest #258)

## Intent
Complete classic #251 dual on Trends: outliers shipped in #257; elevate
±2σ baseline bands on the primary depth timeline. Soft-toggle + z-score
colored band rectangles + baseline rule (Advanced/classic parity) over
existing depth-series stats / zScore.

## Surface
- History → Browse Trends → TrendDetailView → Depth Timeline
- Toggle chip **Baseline Bands** (default on)
- Chart: per-day ±2σ rectangles (z-score tint) + dashed baseline rule
- Legend: **Baseline** ±2σ
- A11y: `trends.baselineBands`, `trends.baselineBands.toggle`

## Verify
- UITest: `testTrendsBaselineBandsSurface`
- Shot: `.audit/verify-trends-baseline-bands.png`

## Non-goals
- No Trends rollingVolatility / momentum strips (→ #259+); no BAC / HK duals
