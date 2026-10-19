# Simulator seed from density forecast (Honest #547)

## Why
Air seed uses today vs 7d mean — forecast seed leans levers toward tomorrow’s density trajectory.

## Surface
- `sim.load.seed.forecast`

## Verify
- `testReadinessLoadSimulatorSurface`
- `.audit/verify-readiness-load-simulator-seed-forecast.png`
