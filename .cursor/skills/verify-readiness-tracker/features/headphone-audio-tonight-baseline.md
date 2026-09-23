# Headphone Audio Tonight|Baseline (Honest #137)

## Why this signal
1. Skin temperature already has Tonight|Baseline + °C deviation (`SkinTemperatureCard`).
2. Watch gym/work dual scores already drive complications + Watch dashboard.
3. Headphone audio exposure was unused sparse HK — strongest unused real elevation.

## Plumbing
- Model: `headphoneAudioExposureDBA: Double?` (Codable)
- HK: read `.headphoneAudioExposure`; day-average dB A-weighted
- Fixture: today 68 dBA; older 55…84; nil every 5th

## Surface
- Today → vitals after Environmental Audio → **Headphone Audio**
- A11y: `vitals.headaudio.card`, `vitals.headaudio.baseline`, `vitals.headaudio.spark`

## Verify
- UITest: `testHeadphoneAudioTonightBaselineSurface`
- Shot: `.audit/verify-headphone-audio-tonight-baseline.png`
