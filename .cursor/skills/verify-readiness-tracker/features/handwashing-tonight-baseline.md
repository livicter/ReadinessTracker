# Handwashing Tonight|Baseline (Honest #186)

## Why
1. Prefer \`handwashingEvent\` — unused hygiene-sparse HK category after toothbrushing.
2. Total duration (minutes) mirrors toothbrushing UX.
3. After Toothbrushing — not chrome-only; avoids sleep-stack duals.

## Plumbing
- Model: \`handwashingMinutes: Double?\` on DailyHealthData
- HK: read \`.handwashingEvent\`; sum sample durations → minutes
- Fixture: today 1.4; older 0.3…2.0; nil every 5th

## Surface
- Today body after Toothbrushing → **Handwashing**
- Met / Steady / Building / Light / Missed vs soft 1 min + baseline
- A11y: \`body.wash.card\`, \`body.wash.baseline\`, \`body.wash.spark\`

## Verify
- \`testHandwashingTonightBaselineSurface\`
- \`.audit/verify-handwashing-tonight-baseline.png\`
