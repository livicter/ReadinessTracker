# Watch Strain Tonight|Baseline (Honest #135)

## Intent
Elevate the WHOOP-style **strain 0–21** already written into the Watch
complication App Group snapshot (`Key.strain`) but still unused by Watch faces
(rings-only / sample fallback). Tonight | Baseline on Today Recovery & Strain —
same number iOS pushes to Watch. Complements Daily TRIMP; not a sleep dual.

## Why not environmental audio
Watch snapshot still had an unused live field (strain). Prefer elevating that
over a new sparse HK type.

## Surface
- Today → Recovery & Strain → **Watch Strain** (after Daily TRIMP)
- Watch rectangular complication also shows strain when App Group has it
- A11y: `watch.strain.card`, `watch.strain.baseline`, `watch.strain.spark`

## Verify
- UITest: `testWatchStrainTonightBaselineSurface`
- Shot: `.audit/verify-watch-strain-tonight-baseline.png`
- Fixture: StrainCalculator on seeded HR/sessions (no new seed required)
