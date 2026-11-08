# Honest #716 / #755: Simulator climb ceiling (WHOOP wells)

SurfaceID: `sim.load.ready.climb.ceiling`
Idle Wide (headroom > 14) = ghost/hairline 8/28 using secondaryText; active Room (headroom <= 14) = 14 fill + 28 hairline (caution); active Near (headroom <= 5) = 14 fill + 28 hairline (good); active Cap (headroom == 0) = 14 fill + 28 hairline (optimal).
Proof: `.audit/verify-simulator-climb-ceiling.png`
UITest: `testReadinessLoadSimulatorSurface`
