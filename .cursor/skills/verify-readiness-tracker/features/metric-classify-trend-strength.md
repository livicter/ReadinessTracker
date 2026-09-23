# Classify Trend Strength Badge (Honest #253)

## Intent
Elevate unused `TrendAnalysisEngine.classifyTrend`: Advanced already computed
`trendClassification` from slope/R² but never rendered. Surface a trend-strength
callout (label + R²) on Advanced Metric Detail; mirrored on classic.

## Surface
- Today → Breakdown → Sleep → Advanced Metric Detail hero (below % TrendBadge)
- Today → Metrics → Sleep → classic MetricDetailView hero
- Labels from `TrendStrength.rawValue` (Strong Up / Improving / Stable / …)
- Caption: Regression fit R²
- A11y: `metric.trend.strength`, `metric.classic.trend.strength`

## Verify
- UITest: `testMetricClassifyTrendStrengthSurface`
- Shot: `.audit/verify-metric-classify-trend-strength.png`

## Non-goals
- No new HK duals / BAC; no classic MA7 / Watch chrome
