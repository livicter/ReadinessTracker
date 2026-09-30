# Body Fat card → MetricDetail nav (Honest #397)

## Intent
WHOOP `body.bodyFat.card` → classic `MetricDetailView(.bodyFat)`.

## Note
SurfaceIDs `body.bodyFat.*` disambiguate from dietary macro `body.fat.*` (`dietaryFatCard`).

## Verify
- UITest: `testBodyFatCardMetricDetailNavSurface`
