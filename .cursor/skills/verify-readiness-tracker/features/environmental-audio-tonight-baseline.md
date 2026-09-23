# Environmental Audio Tonight|Baseline (Honest #136)

## Intent
Wire HealthKit `environmentalAudioExposure` into `DailyHealthData` + HK auth/fetch,
then elevate as Tonight | Baseline on Today vitals (after Walking HR / SpO2).
Not a sleep-stack dual. Deep/REM % already live on Watch Sleep glance — audio
was stronger unused sparse HK.

## Plumbing
- Model: `environmentalAudioExposureDBA: Double?` (Codable)
- HK: read `.environmentalAudioExposure`; day-average dB A-weighted
- Fixture: today 62 dBA; older 52…79; nil every 4th

## Surface
- Today → vitals → **Environmental Audio**
- Quiet / Moderate / Elevated / Loud vs 70 dBA dashed guide
- A11y: `vitals.envaudio.card`, `vitals.envaudio.baseline`, `vitals.envaudio.spark`

## Verify
- UITest: `testEnvironmentalAudioTonightBaselineSurface`
- Shot: `.audit/verify-environmental-audio-tonight-baseline.png`
