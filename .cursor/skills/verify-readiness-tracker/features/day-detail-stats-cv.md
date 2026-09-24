# Day Detail Statistics CV% (Honest #275)

## Intent
Elevate unused `coefficientOfVariation` on `DayDetailView` for Sleep through
day — classic #254 / Trends #256 Volatility CV% presentation parity.

## Surface
- History → day row → DayDetailView
- Statistics card with Volatility CV% after classifyTrend callout
- A11y: `day.detail.stats.cv`

## Verify
- UITest: `testDayDetailStatsCVSurface`
- Shot: `.audit/verify-day-detail-stats-cv.png`

## Non-goals
- No rollingVolatility / momentum / Day Δ strips yet (→ #276+); no MA14/EMA; no BAC / HK duals
