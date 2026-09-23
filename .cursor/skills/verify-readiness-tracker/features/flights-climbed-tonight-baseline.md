# Flights Climbed Tonight|Baseline (Honest #141)

## Why
1. Resting HR already elevated (`RestingHRCard` + Watch snapshot).
2. HRV already in Watch snapshot + recovery stack — not unused.
3. `flightsClimbed` unused sparse HK — strongest unused real elevation (body activity).

## Plumbing
- Model: `flightsClimbed: Double?`
- HK: read `.flightsClimbed`; day cumulativeSum (count)
- Fixture: today 12; older 3…20; nil every 5th

## Surface
- Today body activity after Steps → **Flights Climbed**
- High / Active / Light / Low
- A11y: `body.flights.card`, `body.flights.baseline`, `body.flights.spark`

## Verify
- `testFlightsClimbedTonightBaselineSurface`
- `.audit/verify-flights-climbed-tonight-baseline.png`
