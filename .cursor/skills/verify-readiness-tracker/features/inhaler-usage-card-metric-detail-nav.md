# Inhaler Usage card → MetricDetail (Honest #495)

## Why
Tonight|Baseline inhaler card lacked classic MetricDetail Steps-parity nav.

## Surface
- Card: `body.inhaler.md.nav` (was `.card`)
- Detail: `MetricDetailView(.inhalerUsage)` puffs (lower is better)
- Soft bands: None ≤0 / Light ≤2 / Moderate ≤5 / Heavy

## Verify
- `testInhalerUsageCardMetricDetailNavSurface`
