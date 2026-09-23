# Body Fat Tonight|Baseline (Honest #187)

## Why
1. Prefer `bodyFatPercentage` — unused body-composition after mass/lean/waist.
2. SpO2 / respiratoryRate already have Tonight|Baseline-style wells (not net-new).
3. After Waist Circumference — completes composition set; avoids sleep-stack / re-chrome.

## Plumbing
- Model: `bodyFatPercent: Double?` on DailyHealthData (0–100)
- HK: read `.bodyFatPercentage`; mostRecent percent (normalize fraction→%)
- Fixture: today 18.4; older 16.0…22.0; nil every 5th

## Surface
- Today body after Waist → **Body Fat**
- Steady / Down / Up vs baseline (lower often favorable)
- A11y: `body.fat.card`, `body.fat.baseline`, `body.fat.spark`

## Verify
- `testBodyFatTonightBaselineSurface`
- `.audit/verify-body-fat-tonight-baseline.png`
