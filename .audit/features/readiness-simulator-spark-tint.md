# Honest #512 / #782: Simulator spark tint (WHOOP wells)

Projection map bars + header tint follow the focused ring on Today’s Load Simulator.
Idle (`focusedRingValue == baseline`) = ghost/hairline 8/28 using secondaryText; active negative (`focusedRingValue < baseline`) = 14/28 strain; active positive (`focusedRingValue > baseline`) = 14/28 optimal. No mixed state.
SurfaceID: `sim.load.spark.tint` (legacy `sim.load.spark` retained)
Proof: UITest → `.audit/verify-readiness-load-simulator-spark-tint.png`
