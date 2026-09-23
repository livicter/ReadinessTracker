# Sleep HRV Poincaré (#103)

## Intent
WHOOP-style nocturnal HRV analysis: successive RR-interval scatter (Poincaré) on the Sleep HRV card. Uses existing `PoincarePlotView`; synthetic RR when beat-to-beat samples are absent (scaled to Tonight RMSSD).

## Surface
- Today → Sleep HRV card → **Poincaré Plot** section
- A11y: `sleep.hrv.poincare` (`SurfaceID.sleepHRVPoincare`)
- Soft labels: "Poincaré Plot", SD1/SD2 badges from plot

## Verify
- UITest: `testSleepHRVSurface` soft-asserts plot label + id; shot `.audit/verify-sleep-hrv.png`
- TREE GUARD already lists `verify-sleep-hrv.png`

## Non-goals
- No new readiness scoring
- No HealthKit beat-to-beat wiring in this PR (synthetic fixture path)
