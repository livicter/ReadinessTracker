# Honest #715 / #754: Simulator climb hold (WHOOP wells)

SurfaceID: `sim.load.ready.climb.hold`
Idle None (no Optimal intercept) = ghost/hairline 8/28 using secondaryText; active Brief (hold < 2) = 14 fill + 28 hairline (caution); active Steady (hold >= 2) = 14 fill + 28 hairline (good); active Locked (hold >= 4) = 14 fill + 28 hairline (optimal).
Proof: `.audit/verify-simulator-climb-hold.png`
UITest: `testReadinessLoadSimulatorSurface`
