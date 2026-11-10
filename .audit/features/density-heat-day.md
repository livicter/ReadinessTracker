# Honest #526 / #688 / #795: Density heat.day (WHOOP wells)

Chrome-only WHOOP wells on the existing density heat.day strip (`fitbit.air.density.heat.day` / `health.air.density.heat.day`).
Container: idle (filled == 0) = ghost/hairline 8/28 secondaryText; active complete (filled == total) = 14/28 optimal; else/partial = 14/28 accent. Selected-day container keeps a thicker hairline. No negative state (density is non-negative).
Per-dot fill stays the filled/gap encoding (dayAccent vs ghost) and is not replaced by a uniform 8/14 wash. Gap dots use ghost/hairline 8/28 secondaryText; filled dots keep solid dayAccent plus a 28% hairline in the matching complete/partial tone.
Copy, accessibilityIdentifier, accessibilityLabel, tap-to-select / spark-scrub math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.heat.day` / `health.air.density.heat.day`
Proof: UITest → `.audit/verify-density-heat-day.png`
