# Trends OutlierCallout List (Honest #257)

## Intent
Elevate unused `AnalyzedDataPoint.isOutlier` on `TrendDetailView` via the
shared `OutlierCallout` list (up to 3). Scrub tooltip already flags outliers;
classic #251 / Advanced Highlights already list them — Trends did not.

## Surface
- History → Browse Trends → TrendDetailView
- **Highlights** section after depth timeline when |z|>2 outliers exist
- A11y: `trends.outliers`, `trends.outlierList`

## Verify
- UITest: `testTrendsOutlierCalloutSurface`
- Shot: `.audit/verify-trends-outlier-callout.png`

## Non-goals
- No Trends baseline-band / strip engines; no BAC / HK duals
