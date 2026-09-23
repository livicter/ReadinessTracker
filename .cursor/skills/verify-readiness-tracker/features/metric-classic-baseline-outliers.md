# Classic Baseline Bands + OutlierCallout (Honest #251)

## Intent
Presentation parity: classic `MetricDetailView` elevates z-score baseline bands and
`isOutlier` callouts already on `AnalyzedDataPoint` — previously Advanced-only chrome.

## Surface
- Today → Metrics → Sleep card → MetricDetailView
- Toggle chips **Baseline Bands** + **Outliers** (default on)
- Chart: ±2σ band rectangles + baseline rule + red outlier halos
- **Highlights** section: up to 3 `OutlierCallout` rows when outliers exist
- A11y: `metric.classic.baselineBands` / `.toggle`, `.outliers` / `.toggle`, `.outlierList`

## Verify
- UITest: `testMetricClassicBaselineOutliersSurface`
- Shot: `.audit/verify-metric-classic-baseline-outliers.png`

## Non-goals
- No Advanced re-ship; no new HK duals / BAC
- No Watch dual-callout depth (→ #252+)
