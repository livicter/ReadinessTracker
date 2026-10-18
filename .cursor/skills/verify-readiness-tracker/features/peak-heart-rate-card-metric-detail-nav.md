# Peak Heart Rate card → MetricDetail (Honest #496)

## Why
Tonight|Baseline peak HR card lacked classic MetricDetail Steps-parity nav.

## Surface
- Card: `vitals.peakhr.md.nav` (was `.card`)
- Detail: `MetricDetailView(.peakHeartRate)` bpm from `maxHeartRate` (lower softer for recovery)
- Soft bands: Soft <150 / Steady <165 / Elevated <180 / High peak

## Verify
- `testPeakHeartRateCardMetricDetailNavSurface`
