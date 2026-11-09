# Honest #512 / #782: Simulator spark tint (WHOOP wells)

Projection map bars tint to the focused ring (interactive header + Chart). Visibility, copy, header tint Circle, Chart bar tint, interaction, and accessibilityIdentifier unchanged.
Idle (`focusedRingValue == baseline`) = ghost/hairline 8/28 using secondaryText; active negative (`focusedRingValue < baseline`) = 14/28 strain; active positive (`focusedRingValue > baseline`) = 14/28 optimal. No mixed state (single signed delta vs tonight baseline).
Well tone follows the focused-ring delta vs tonight baseline (same idea as #781 rings' READY-delta convention, but for `focusedRingValue`); do not use “any bar != baseline”.
SurfaceID: `sim.load.spark.tint` (legacy `sim.load.spark` retained on the Chart)
Proof: `.audit/verify-readiness-load-simulator-spark-tint.png`
