# Day Detail SpO2 Baseline Bands ±2σ (Honest #333)

## Intent
Dual of Sleep #273 / Strain #318. Add `spo2BaselineStats` (≥5) and a
Blood Oxygen Trend host chart (Strain #318 pattern) with ±2σ bands + baseline
rule. No chrome-only — real series + engine stdDev/mean/zScore.

## Surface
- History → day row → DayDetailView → 7-Day Context
- Blood Oxygen Trend card with Baseline ±2σ legend
- A11y: `day.detail.spo2.baselineBands`

## Verify
- UITest: `testDayDetailSpO2BaselineBandsSurface`
- Shot: `.audit/verify-day-detail-spo2-baseline-bands.png`

## Non-goals
- No MA/EMA overlays yet; no BAC / HK duals; no RecoveryTrajectory-on-SpO2
