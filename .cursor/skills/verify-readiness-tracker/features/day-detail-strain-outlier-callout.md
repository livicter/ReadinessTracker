# Day Detail Strain OutlierCallout (Honest #317)

## Intent
Elevate unused `AnalyzedDataPoint.isOutlier` on Strain through day —
Sleep #272 / HRV #286 / RHR #301 dual. Highlights list (up to 3) via
`strainAnalyzedThroughDay`; values in cal.

## Surface
- History → day row → DayDetailView
- "Strain Highlights" OutlierCallout list after RHR Highlights
- A11y: `day.detail.strain.outlierList`

## Verify
- UITest: `testDayDetailStrainOutlierCalloutSurface`
- Shot: `.audit/verify-day-detail-strain-outlier-callout.png`

## Non-goals
- Soft when fixture lacks |z|>2 outliers; no BAC / HK duals
- Baseline Bands → #318
