# Simulator task READY impact (Honest #515)

## Why
Richer simulation — each today task shows estimated READY lift; cumulative lift updates when checked.

## Surface
- `sim.load.tasks.impact`
- Per-row `+N` capsules

## Verify
- `testReadinessLoadSimulatorSurface`
- `.audit/verify-readiness-load-simulator-task-impact.png`
