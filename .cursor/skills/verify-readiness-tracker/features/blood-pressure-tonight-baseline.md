# Blood Pressure Tonight|Baseline (Honest #188)

## Why
1. Prefer blood pressure — unused vitals (systolic/diastolic).
2. Combined card; systolic drives spark/baseline; soft AHA glance bands.
3. After Blood Glucose — not chrome-only; avoids sleep-stack / SpO2-RR re-chrome.

## Plumbing
- Model: `bloodPressureSystolicMmHg`, `bloodPressureDiastolicMmHg`
- HK: read `.bloodPressureSystolic` / `.bloodPressureDiastolic`; mostRecent mmHg
- Fixture: today 118/74; older sys 110…134, dia 68…83; nil every 5th

## Surface
- Today body after Blood Glucose → **Blood Pressure**
- Optimal / Elevated / High / Very high vs systolic bands
- A11y: `body.bp.card`, `body.bp.baseline`, `body.bp.spark`

## Verify
- `testBloodPressureTonightBaselineSurface`
- `.audit/verify-blood-pressure-tonight-baseline.png`
