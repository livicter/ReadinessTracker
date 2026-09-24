# Day Detail Momentum Strip (Honest #277)

## Intent
Elevate unused `AnalyzedDataPoint.momentum` on `DayDetailView` Sleep through
day — classic #248 / Trends #260 parity. Toggle + Rising/Flat/Fading band
chart via `sleepAnalyzedThroughDay`.

## Surface
- History → day row → DayDetailView
- Momentum toggle beside Volatility; 7-Day Momentum strip
- A11y: `day.detail.momentum`, `day.detail.momentum.toggle`

## Verify
- UITest: `testDayDetailMomentumSurface`
- Shot: `.audit/verify-day-detail-momentum.png`

## Non-goals
- No Day Δ / rateOfChange yet (→ #278); no MA14/EMA; no BAC / HK duals
