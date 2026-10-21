# Settings Fitbit air density ring

## Sub-features
- Density ring + Sleep/Vitals/Move bars on Settings Fitbit air status
- SurfaceID `settings.fitbit.air.ring`

## How to get to it (user POV)
Settings → Data Sources → Fitbit (when connected with a day) → Air tonight ring

## Driving it with the harness
UITest `testFitbitSettingsAirStatusSurface` asserts `settings.fitbit.air.ring` (soft fallback) and saves `.audit/verify-fitbit-settings-air-ring.png`.

## Gotchas
Ring only when Fitbit authenticated and air chips non-empty.
