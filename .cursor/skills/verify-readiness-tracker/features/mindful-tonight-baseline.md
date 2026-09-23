# Mindful Tonight|Baseline (Honest #189)

## Why
1. Prefer `bodyTemperature` skipped — already wired as `skinTemperature` → SkinTemperatureCard (re-chrome).
2. Prefer `mindfulSession` — unused category; total duration minutes.
3. After Handwashing — recovery UX; avoids sleep-stack / SpO2-RR re-chrome.

## Plumbing
- Model: `mindfulMinutes: Double?` on DailyHealthData
- HK: read `.mindfulSession`; sum sample durations → minutes
- Fixture: today 12; older 5…20; nil every 5th

## Surface
- Today body after Handwashing → **Mindful**
- Met / Steady / Building / Light / Missed vs soft 10 min + baseline
- A11y: `body.mindful.card`, `body.mindful.baseline`, `body.mindful.spark`

## Verify
- `testMindfulTonightBaselineSurface`
- `.audit/verify-mindful-tonight-baseline.png`
