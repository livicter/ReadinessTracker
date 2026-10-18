# Forced Vital Capacity card → MetricDetail (Honest #493)

## Why
Tonight|Baseline FVC card lacked classic MetricDetail Steps-parity nav.

## Surface
- Card: `body.fvc.md.nav` (was `.card`)
- Detail: `MetricDetailView(.forcedVitalCapacity)` L
- Soft bands: Strong ≥4.5 / Solid ≥3.5 / Fair ≥2.5 / Low
- Always-hosted NavigationLink + compositingGroup; no nested a11y ids on baseline

## Verify
- `testForcedVitalCapacityCardMetricDetailNavSurface`
- `.audit/verify-forced-vital-capacity-metric-detail.png`
- `.audit/verify-forced-vital-capacity-card-back.png`
