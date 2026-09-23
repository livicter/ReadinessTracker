# Env Sound Reduction Tonight|Baseline (Honest #138)

## Why this signal
1. Skin temperature already has Tonight|Baseline + °C Δ (`SkinTemperatureCard`) — not thin.
2. Watch `sleepScore` already drives complications + Today breakdown / SleepQualityTrend.
3. `environmentalSoundReduction` (AirPods Pro ANC dB) was unused sparse HK — strongest unused real elevation.

## Plumbing
- Model: `environmentalSoundReductionDBA: Double?` (Codable)
- HK: read `.environmentalSoundReduction`; day-average dB A-weighted
- Fixture: today 18 dBA; older 8…29; nil every 5th

## Surface
- Today → vitals after Headphone Audio → **Sound Reduction**
- Strong / Good / Light / Minimal vs 12 dBA guide
- A11y: `vitals.soundred.card`, `vitals.soundred.baseline`, `vitals.soundred.spark`

## Verify
- UITest: `testEnvSoundReductionTonightBaselineSurface`
- Shot: `.audit/verify-env-sound-reduction-tonight-baseline.png`
