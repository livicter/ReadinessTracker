# Honest #716 / #755: Simulator climb ceiling (WHOOP wells)

Headroom from full-queue READY to absolute hard ceiling 100. Cap/Near/Room/Wide dial.
Idle Wide (headroom > 14) = ghost/hairline 8/28 using secondaryText; active Room (headroom <= 14) = 14 fill + 28 hairline (caution); active Near (headroom <= 5) = 14 fill + 28 hairline (good); active Cap (headroom == 0) = 14 fill + 28 hairline (optimal).
SurfaceID: `sim.load.ready.climb.ceiling`
Proof: `.audit/verify-simulator-climb-ceiling.png`
