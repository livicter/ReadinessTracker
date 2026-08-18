# ReadinessTracker — WHOOP + Google Health Parity Roadmap

## Goal
Close parity gaps with WHOOP and Google Health apps by adding the highest-impact missing features in focused phases.

## Current State
- Phase 1 (WHOOP-grade readiness/strain model) is complete and verified.
- All 10 Phase 1 tasks done: HR sample model, adaptive baselines, TRIMP strain 0-21, multi-metric recovery 0-100, HealthKit wiring, dashboard/detail UI, unit tests.
- Last verification: `xcodebuild ... test` → **TEST SUCCEEDED** (5 tests, 0 failures).

## Phase 1 — WHOOP-Grade Readiness/Strain Model ✅

| Task | Status |
|------|--------|
| 1. HR sample model and data model extensions | complete |
| 2. Adaptive baseline manager (7/14/30-day windows) | complete |
| 3. TRIMP-like strain calculator (0-21) | complete |
| 4. Recovery calculator with multi-metric model | complete |
| 5. Wire new calculators into ReadinessCalculator | complete |
| 6. Fetch HR samples and max HR in HealthKitManager | complete |
| 7. Update dashboard strain/recovery display | complete |
| 8. Revive RecoveryStrainDetailView | complete |
| 9. Add temp/resp subscores to ReadinessScoreDetailView | complete |
| 10. Unit tests | complete |

## Phase 2 — Full WHOOP + Google Health Parity (All Four Tracks)

User wants all four options. We will run them as sequential phases so each stays reviewable and testable.

### Phase 2A: Real HRV RMSSD from RR intervals ✅
**Goal:** Replace SDNN-based HRV with RMSSD, the metric WHOOP actually uses for recovery.

- Fetch RR-interval / HRV samples from HealthKit. ✅
- Add `HRVCalculator` with RMSSD and optional SDNN. ✅
- Update `RecoveryCalculator` to use RMSSD. ✅
- Add unit tests for RMSSD math. ✅

**Note:** UI label change landed in `ReadinessDetailView.swift`; project does not contain `ReadinessScoreDetailView.swift`.

### Phase 2B: Workout-level strain ✅
**Goal:** Per-workout cardiovascular strain, WHOOP-style.

- Add `StrainSession` model. ✅
- Fetch `HKWorkout` samples from HealthKit. ✅
- Calculate per-workout TRIMP and aggregate daily strain. ✅
- Show workout list in `RecoveryStrainDetailView`. ✅

### Phase 2C: SpO2 + nutrition + menstrual cycle (Google Health breadth) ✅
**Goal:** Use additional HealthKit metrics that Google Health surfaces.

- Score SpO2 in recovery.
- Fetch nutrition (water, caffeine, protein) and include in recovery/strain context.
- Add menstrual cycle logging/impact (optional, privacy-first).
- Update `ReadinessScoreDetailView` and `RecoveryStrainDetailView`.

**Status:** implementation complete, all tests pass (26 tests, 0 failures).

### Phase 2D: Trends + insights + weekly report ✅
**Goal:** Analytics layer using all new data.

- 7/30/90-day trend cards.
- Automated weekly summary with strain/recovery balance.
- Wire `AIRecommendations` to strain/recovery/workout data.

**Status:** implementation complete; final review fixes applied and verified (38 tests, 0 failures).

## Execution Order

Proposed order: **2A → 2B → 2C → 2D**

Reason: RMSSD improves the core recovery signal first; workout strain builds on existing strain math; breadth metrics come after core signal is solid; analytics/reporting uses everything.

## Glassy UI Redesign ✅

- New branch `feature/glassy-ui-redesign`.
- Glass design system + all views converted to glassmorphism.
- Final test run: **TEST SUCCEEDED** — 38 tests, 0 failures.

## Apple Health Native UI Redesign ✅

- Apple Health design system + all views converted.
- Glassmorphism remnants removed.
- Final test run: **TEST SUCCEEDED** — 38 tests, 0 failures.

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
