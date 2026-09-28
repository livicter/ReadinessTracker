# Metric Detail SpO2-host HRV↔SpO2 tag (Honest #357)

## Intent
On SpO2 MetricDetail, tag the primary SpO2↔HRV correlation as
`metric.detail.metricCorrelation.hrvSpo2` (classic) and mount the explicit
HRV↔SpO2 dual on Advanced when metric is Blood Oxygen — completes SpO2-host
correl duals with Day Detail #343. No new SurfaceID. No new HK.

## Surface
- Today → Breakdown SpO2 → MetricDetail / Advanced
- A11y: `metric.detail.metricCorrelation.hrvSpo2`

## Verify
- UITest: `testMetricDetailMetricCorrelationSpo2HostHRVSurface`
- Shot: `.audit/verify-metric-detail-metric-correlation-spo2-host-hrv.png`

## Non-goals
- No Trends SpO2; no BAC / HK; no RecoveryTrajectory-on-Strain; no Body Activity SI
