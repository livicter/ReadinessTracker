# Honest #714 / #753: Simulator climb overshoot (WHOOP wells)

SurfaceID: `sim.load.ready.climb.overshoot`
Idle Short (overshoot < 0) = ghost/hairline 8/28 using secondaryText; active Exact (overshoot == 0) = 14 fill + 28 hairline (caution); active Soft (overshoot >= 1) = 14 fill + 28 hairline (good); active High (overshoot >= 8) = 14 fill + 28 hairline (optimal).
Proof: `.audit/verify-simulator-climb-overshoot.png`
UITest: `testReadinessLoadSimulatorSurface`
