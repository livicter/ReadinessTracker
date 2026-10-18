# Water Temperature card → MetricDetail (Honest #491)

## Why
Tonight|Baseline water temp card lacked classic MetricDetail Steps-parity nav.

## Surface
- Card: `body.waterTemperature.md.nav` (was `.card`)
- Detail: `MetricDetailView(.waterTemperature)` °C
- Soft bands: Warm ≥28 / Mild ≥20 / Cool ≥12 / Cold
- Always-hosted NavigationLink + compositingGroup; no nested a11y ids on baseline

## Verify
- `testWaterTemperatureCardMetricDetailNavSurface`
- `.audit/verify-water-temperature-metric-detail.png`
- `.audit/verify-water-temperature-card-back.png`
