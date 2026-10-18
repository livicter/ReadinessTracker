# Peak Expiratory Flow card → MetricDetail (Honest #492)

## Why
Tonight|Baseline PEF card lacked classic MetricDetail Steps-parity nav.

## Surface
- Card: `body.pef.md.nav` (was `.card`)
- Detail: `MetricDetailView(.peakExpiratoryFlow)` L/min
- Soft bands: Strong ≥450 / Solid ≥350 / Fair ≥250 / Low
- Always-hosted NavigationLink + compositingGroup; no nested a11y ids on baseline

## Verify
- `testPeakExpiratoryFlowCardMetricDetailNavSurface`
- `.audit/verify-peak-expiratory-flow-metric-detail.png`
- `.audit/verify-peak-expiratory-flow-card-back.png`
