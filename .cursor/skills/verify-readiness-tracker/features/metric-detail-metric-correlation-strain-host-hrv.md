# Metric Detail Strain-host HRV↔Strain (Honest #359)

## Intent
Extend #353 so MetricCorrelationView HRV↔Strain also mounts when metric is
Active Calories (Strain-host) — host dual parity after SpO2-host cluster
(#355–#357). Same SurfaceID. Hosts: classic + Advanced. No new HK.
Primary on Strain remains Sleep↔Strain (generic); HRV↔Strain is a distinct pair.

## Surface
- Today → Breakdown Active Calories / Strain → AdvancedMetricDetailView
- A11y: `metric.detail.metricCorrelation.hrvStrain` (same as #353)

## Verify
- UITest: `testMetricDetailMetricCorrelationStrainHostHRVSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-strain-host-hrv.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
