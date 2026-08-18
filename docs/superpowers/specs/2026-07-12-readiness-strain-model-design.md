# ReadinessTracker Phase 1 — WHOOP-Grade Readiness/Strain Model

## Goal
Replace the current simplified readiness/strain calculations with a WHOOP-like model:
- Cardiovascular strain score 0-21
- Recovery score 0-100 from HRV RMSSD, RHR, sleep performance vs personal baseline
- Integrate wrist skin temperature deviation, respiratory rate, and SpO2
- Adaptive 7/14/30-day baselines
- Strain-recovery balance visualization

## Current Gaps
- Strain is a rough `activeCalories/200 + workoutMinutes/30`, capped at 21. Not cardiovascular.
- Recovery is a weighted sum, but HRV uses SDNN from HealthKit, not RMSSD.
- Skin temp, respiratory rate, SpO2 are fetched but not used in scoring.
- Baseline is fixed 7-day rolling; no adaptation for training blocks or illness.

## Algorithm Design

### Strain Score 0-21
1. Fetch heart-rate samples for the day.
2. Assign TRIMP-like points per minute based on HR reserve:
   - `zone = (hr - restingHR) / (maxHR - restingHR)`
   - `points = 0.5 * exp(1.92 * zone)`
3. Sum points, normalize to 0-21 using user's 30-day max strain as reference.
4. Fallback: if no HR samples, estimate from active calories + workout minutes.

### Recovery Score 0-100
Inputs and weights:
- HRV RMSSD: 35%
- RHR vs baseline: 20%
- Sleep performance (duration + efficiency + stages): 25%
- Skin temp deviation: 10%
- Respiratory rate vs baseline: 10%

Each subscore:
- `subscore = 100 * (1 - normalizedDeviation)`
- Deviations beyond 2σ cap at ±100
- Higher HRV = better; lower RHR = better; stable temp/resp = better

### Baseline Manager
- Maintain 7-day, 14-day, 30-day rolling baselines per metric.
- Use 14-day as primary for HRV/RHR; 7-day for sleep; 30-day for strain max.
- Detect and flag outliers (≥2σ) for user review.

### Data Model Changes
- `DailyHealthData`: add `maxHeartRate`, `hrSamples: [HRSample]`.
- `UserSettings`: add `age`, `maxHeartRate` (auto from HealthKit or manual).
- New `StrainSession` model for workout-level strain.

### UI Changes
- New `StrainScoreDetailView`: 0-21 ring, zone distribution, timeline.
- Update `RecoveryStrainDetailView`: strain vs recovery balance chart.
- Update `DashboardView`: show strain score next to recovery.
- Update `ReadinessScoreDetailView`: show subscore breakdown with temp/resp/SpO2.

### Testing
- Unit tests for strain calculation with synthetic HR data.
- Unit tests for recovery subscores.
- Build and run on simulator with sample HealthKit data.

## Out of Scope
- Real-time strain during workout (v2).
- On-device ML model (v3).
- Google Health Connect / nutrition / menstrual cycle (Phase 2).

## Success Criteria
- App builds with zero errors.
- Strain score stays 0-21 for synthetic data.
- Recovery score 0-100 responds correctly to simulated high/low HRV, RHR, sleep.
- New metrics appear in detail views.
