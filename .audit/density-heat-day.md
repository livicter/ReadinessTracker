# Honest #526 / #688 / #795: Density heat.day (WHOOP wells)

Fitbit/Health selected-day chip-dot strip under the 7-day density heatmap.
Chrome-only WHOOP wells on the existing Honest #526 / #688 heat.day strip.
Container: idle (filled == 0) = ghost/hairline 8/28 secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. Selected-day container keeps a thicker hairline.
Dots: idle (gap) = ghost/hairline 8/28 secondaryText; filled = solid dayAccent fill (filled/gap encoding preserved, not flattened to a uniform 8/14 wash) plus 28% hairline in the matching complete/partial tone.
No negative state (density is non-negative).
Copy, accessibilityIdentifier, accessibilityLabel, tap-to-select / spark-scrub math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.heat.day` / `health.air.density.heat.day`
Proof: `.audit/verify-density-heat-day.png`
