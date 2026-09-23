# Heart Rate Zones (Honest #105)

## Intent
WHOOP / Apple Fitness–style daytime HR zone minutes on Recovery & Strain, using % heart-rate reserve (Karvonen). Wires `DailyHealthData.hrSamples` that previously had no zone UI.

## Surface
- Today → Balance / Recovery & Strain → **Heart Rate Zones** (after Strain Breakdown)
- A11y: `strain.hr.zones`, `strain.hr.zone.rest|light|moderate|hard|peak`

## Verify
- UITest: `testHeartRateZonesSurface` soft-asserts title + zone labels; shot `.audit/verify-hr-zones.png`
- Fixture seeds today `hrSamples` via `syntheticHRSamples`

## Non-goals
- No new readiness score term
- No live HealthKit zone streaming beyond existing sample ingest
