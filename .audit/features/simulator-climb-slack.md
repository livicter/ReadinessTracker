# Honest #713 / #752: Simulator climb slack (WHOOP wells)

SurfaceID: `sim.load.ready.climb.slack`
Idle Short (no Optimal intercept) = ghost/hairline 8/28 using secondaryText; active None (slack == 0, intercept exists) = 14 fill + 28 hairline (caution); active Tight (slack == 1) = 14 fill + 28 hairline (caution); active Soft (slack == 2) = 14 fill + 28 hairline (good); active Fat (slack >= 3) = 14 fill + 28 hairline (optimal).
Proof: `.audit/verify-simulator-climb-slack.png`
UITest: `testReadinessLoadSimulatorSurface`
