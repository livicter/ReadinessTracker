# Metric Detail SpO2-host Strain↔SpO2 (Honest #356)

## Intent
Extend #349 so MetricCorrelationView Strain↔SpO2 also mounts when metric is
Blood Oxygen — completes SpO2-host correl duals with Day Detail (Sleep #346,
RHR #355). Same SurfaceID. Hosts: classic + Advanced. No new HK.

## Surface
- Today → Breakdown SpO2 → AdvancedMetricDetailView
- A11y: `metric.detail.metricCorrelation.strainSpo2`

## Verify
- UITest: `testMetricDetailMetricCorrelationSpo2HostStrainSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-spo2-host-strain.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
