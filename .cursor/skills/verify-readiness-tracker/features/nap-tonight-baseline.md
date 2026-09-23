# Nap Tonight|Baseline (Honest #130)

## Intent
Elevate morning check-in `hadNap` / `napQuality` (1–5) + duration into a
WHOOP-style **Tonight | Baseline** dual near Cognitive Load. Check-in nap was
unused on Today. Not a sleep-stack WHOOP dual — check-in stack only.
CheckInStatusCard wells stay chrome-only.

## Surface
- Today → after Cognitive Load, before Workout RPE
- Tonight quality /5 + duration caption vs 7-day nap-day baseline
- Restorative / Helpful / Fair / Poor / No nap
- A11y: `checkin.nap.card`, `checkin.nap.baseline`, `checkin.nap.spark`

## Verify
- UITest: `testNapTonightBaselineSurface`
- Shot: `.audit/verify-nap-tonight-baseline.png`
- Fixture: mornings seed naps (today 25 min · Q4; older varied + skip)

## Non-goals
- No re-chrome of CheckInStatusCard wells
- No sleep-stack dual clones
