# Metric Detail SpO2-host RHR↔SpO2 (Honest #355)

## Intent
Extend #348 so MetricCorrelationView RHR↔SpO2 also mounts when metric is
Blood Oxygen (SpO2-host) — Day Detail SpO2 correl cluster parity on the SpO2
MetricDetail page (already had Sleep↔SpO2 via #346). No new SurfaceID.
Hosts: classic + Advanced. No new HK.

## Surface
- Today → Metrics → Blood Oxygen / SpO2 breakdown → MetricDetailView
- A11y: `metric.detail.metricCorrelation.rhrSpo2` (same as #348)

## Verify
- UITest: `testMetricDetailMetricCorrelationSpo2HostRHRSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-spo2-host-rhr.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
