# Honest #629 / #641 / #800: Density tail meter (WHOOP wells)

Fitbit/Health air density Tail Ratio meter at the bottom of the Air card meter stack (after hist → gain/pain, below heatmap + WoW + forecast + streak + spark).
Chrome-only WHOOP wells on the existing Honest #629 / #641 tail meter container.
The ratio track already encodes the clamped 0...4 value (accent→tone gradient fill) and the 7-bin histogram already encodes tail category (warning left / accent mid / optimal right). Those fills are left intact — not flattened to a uniform 8/14 wash.
Idle (no density > 0 in the 14d window) = ghost/hairline 8/28 secondaryText; active complete (ratio >= 2, Fat) = 14/28 optimal; active negative (ratio < 0.5, Left, and has density) = 14/28 strain; else/partial (Balanced / Lean) = 14/28 accent.
The verb capsule keeps its existing tone. Label contrast holds (no white text on a light wash).
Copy, accessibilityIdentifier, accessibilityLabel, tail-ratio math, and READY formula unchanged. No new SID.
SurfaceID: `fitbit.air.density.tail` / `health.air.density.tail`
Proof: `.audit/verify-density-tail.png`
