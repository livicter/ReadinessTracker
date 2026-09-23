# Steps Tonight|Baseline (Honest #121)

## Intent
Elevate Body `steps` into a WHOOP-style **Tonight | Baseline** dual on Today Body. The Body steps tile remains the glance chip; Metrics stay calories-heavy — this dual does not re-chrome the tile well.

## Surface
- Today → Body → **Steps** dual (after tile grid, before Cycle dual when tracking is on)
- Tonight vs 7-day baseline steps; % of 10k goal; Goal hit / On track / Building / Low
- A11y: `body.steps.card`, `body.steps.baseline`, `body.steps.spark`

## Verify
- UITest: `testStepsTonightBaselineSurface`; shot `.audit/verify-steps-tonight-baseline.png`
- Fixture: today 8200; older days 5500… vary for spark shape

## Non-goals
- No re-chrome of BodyMetricTile / detail sheet
- Nutrition water/caffeine/protein dual deferred
