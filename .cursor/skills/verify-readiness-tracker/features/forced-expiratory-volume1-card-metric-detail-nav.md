# Forced Expiratory Volume 1 card → MetricDetail (Honest #494)

## Why
Tonight|Baseline FEV1 card lacked classic MetricDetail Steps-parity nav.

## Surface
- Card: `body.fev1.md.nav` (was `.card`)
- Detail: `MetricDetailView(.forcedExpiratoryVolume1)` L
- Soft bands: Strong ≥3.5 / Solid ≥2.8 / Fair ≥2.0 / Low

## Verify
- `testForcedExpiratoryVolume1CardMetricDetailNavSurface`
