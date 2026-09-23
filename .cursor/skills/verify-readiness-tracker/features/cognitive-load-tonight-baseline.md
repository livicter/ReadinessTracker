# Cognitive Load Tonight|Baseline (Honest #128)

## Intent
Elevate morning check-in `mentalFatigue` + `workloadStress` (1–5) into a
WHOOP-style **Tonight | Baseline** dual near Check-in Insights. These feed
cognitive-lag scoring but were buried vs feel/alcohol/stress Insights.
CheckInStatusCard wells stay chrome-only — not re-chromed.

## Surface
- Today → after Check-in Insights, before Workout RPE
- Tonight fatigue /5 (caption: Stress N/5) vs 7-day fatigue baseline (caption: Stress avg)
- Clear / Loaded / Heavy / Drained from peak(fatigue, stress)
- A11y: `checkin.cognitive.card`, `checkin.cognitive.baseline`, `checkin.cognitive.spark`

## Verify
- UITest: `testCognitiveLoadTonightBaselineSurface`
- Shot: `.audit/verify-cognitive-load-tonight-baseline.png`
- Fixture: mornings seed fatigue/stress (today 2/3; older 1…5)

## Non-goals
- No re-chrome of CheckInStatusCard wells
- No sleep-stack dual clones
