# Heart Rate Recovery Tonight|Baseline (Honest #167)

## Why
1. Prefer `heartRateRecoveryOneMinute` — readiness recovery signal (bpm drop post-workout).
2. Stronger unused vitals than AF burden / peripheral perfusion for daily Tonight|Baseline.
3. Vitals after Walking HR — not sleep-stack dual; not chrome-only.

## Plumbing
- Model: `heartRateRecoveryOneMinuteBpm: Double?`
- HK: read `.heartRateRecoveryOneMinute`; discreteAverage count/min; iOS 16+
- Fixture: today 22; older 12…31; nil every 5th

## Surface
- Today vitals after Walking HR → **HR Recovery**
- Strong / Solid / Fair / Slow vs ≥25 / ≥18 / ≥12 bpm
- A11y: `vitals.hrr.card`, `vitals.hrr.baseline`, `vitals.hrr.spark`

## Verify
- `testHeartRateRecoveryTonightBaselineSurface`
- `.audit/verify-heart-rate-recovery-tonight-baseline.png`
