# Day Detail SpO2 OutlierCallout Highlights (Honest #332)

## Intent
Elevate unused `AnalyzedDataPoint.isOutlier` on SpO2 via OutlierCallout list
(up to 3) — Sleep #272 / Strain #317 dual. Soft empty when fixture has no |z|>2.

## Surface
- History → day row → DayDetailView
- SpO2 Highlights card when outliers present
- A11y: `day.detail.spo2.outlierList`

## Verify
- UITest: `testDayDetailSpO2OutlierCalloutSurface`
- Shot: `.audit/verify-day-detail-spo2-outlier-callout.png`

## Non-goals
- No Baseline Bands yet (→ #333); no BAC / HK duals
