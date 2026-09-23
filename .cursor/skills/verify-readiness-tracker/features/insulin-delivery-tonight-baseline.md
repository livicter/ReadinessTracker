# Insulin Delivery Tonight|Baseline (Honest #179)

## Why
1. Prefer `insulinDelivery` — remaining medical-sparse unused HK after inhaler.
2. Cumulative IU; metabolic-adjacent without sleep-stack duals.
3. After Inhaler Usage — not chrome-only.

## Plumbing
- Model: `insulinDeliveryIU: Double?` on DailyHealthData
- HK: read `.insulinDelivery`; cumulativeSum internationalUnit
- Fixture: today 32; older 15…60; nil every 5th

## Surface
- Today body after Inhaler Usage → **Insulin Delivery**
- None / Light / Steady / Elevated / High vs ≤0 / <20 / <50 / <80 / ≥80
- A11y: `body.insulin.card`, `body.insulin.baseline`, `body.insulin.spark`

## Verify
- `testInsulinDeliveryTonightBaselineSurface`
- `.audit/verify-insulin-delivery-tonight-baseline.png`
