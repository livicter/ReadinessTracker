# Sleep HRV Frequency Domain (#104)

## Intent
WHOOP-style nocturnal autonomic balance: LF / HF power share and LF/HF ratio on the Sleep HRV card. Wires existing `HRVFrequencyAnalyzer` (previously unused). Synthetic RR (≥280) when beat-to-beat absent.

## Surface
- Today → Sleep HRV → **Frequency Domain** (after Poincaré)
- A11y: `sleep.hrv.frequency`, `sleep.hrv.lf`, `sleep.hrv.hf`, `sleep.hrv.lfhf`

## Verify
- UITest: `testSleepHRVSurface` soft-asserts labels + ids; shot `.audit/verify-sleep-hrv.png`

## Non-goals
- No new scoring formula
- No live HealthKit RR ingestion in this PR
