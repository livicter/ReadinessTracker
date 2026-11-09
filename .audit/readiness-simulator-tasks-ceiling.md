# Honest #559 / #767: Simulator projected READY ceiling (WHOOP wells)

Dual-rail now→ceiling if all remaining tasks checked.
Idle (no ordered tasks checked yet and remain > 0) = ghost/hairline 8/28 using secondaryText; active complete (`remain == 0`) = 14 fill + 28 hairline (optimal); active partial (some checked, remain > 0) = 14/28 accent; active negative (`ceilingReady < nowReady`) = 14/28 strain.
SurfaceID: `sim.load.tasks.ceiling`
Proof: `.audit/verify-simulator-tasks-ceiling.png`
