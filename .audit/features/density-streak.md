# Honest #538 / #682 / #797: Density streak badge (WHOOP wells)

Chrome-only WHOOP wells on the existing density streak badge (`fitbit.air.density.streak` / `health.air.density.streak`).
Idle unused: badge mounts only when current > 0 or best > 0.
Active complete (current >= 3) = 14/28 optimal; active negative (current == 0, broken streak with a historical best) = 14/28 strain; else/partial (current 1–2) = 14/28 accent.
Inner day capsule keeps its existing tone. Calendar dots (streak.cal) are unchanged. Copy, accessibilityIdentifier, accessibilityLabel, expand-toggle math, and READY formula unchanged.
SurfaceID: `fitbit.air.density.streak` / `health.air.density.streak`
Proof: UITest → `.audit/verify-density-streak.png`
