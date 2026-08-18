# ReadinessTracker Phase 2B — Workout-Level Strain Design

## Goal
Add WHOOP-style per-workout cardiovascular strain by computing TRIMP for each `HKWorkout` using heart-rate samples captured during the workout interval.

## Background
- Phase 1 added daily `hrSamples` and a TRIMP-based `StrainCalculator` that aggregates them into a 0-21 daily strain score.
- `HealthKitManager` already fetches `HKWorkout` samples to compute `workoutMinutes`.
- `RecoveryStrainDetailView` shows a daily strain breakdown but has no workout-level visibility.

## Architecture

```
HKWorkout samples for the day
        │
        ▼
StrainSession(workoutType, start, end, estimatedTRIMP)
        │
        ▼
Filter DailyHealthData.hrSamples by workout interval
        │
        ▼
StrainCalculator.workoutTRIMP(samples, restingHR, maxHR) ──► actualTRIMP
        │
        ▼
DailyHealthData.strainSessions: [StrainSession]
        │
        ▼
RecoveryStrainDetailView workout list
```

## Components

### 1. StrainSession model (new)
`ReadinessTracker/Models/StrainSession.swift`

```swift
import Foundation

struct StrainSession: Codable, Identifiable, Hashable {
    let id: UUID
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let durationMinutes: Double
    let trimp: Double
    let contribution: Double // portion of daily 0-21 strain from this workout

    init(
        id: UUID = UUID(),
        workoutType: String,
        startDate: Date,
        endDate: Date,
        trimp: Double,
        contribution: Double
    ) {
        self.id = id
        self.workoutType = workoutType
        self.startDate = startDate
        self.endDate = endDate
        self.durationMinutes = endDate.timeIntervalSince(startDate) / 60
        self.trimp = trimp
        self.contribution = contribution
    }
}
```

### 2. DailyHealthData extension
`ReadinessTracker/Models/HealthData.swift`

Changes:
- Add `let strainSessions: [StrainSession]`.
- Add default `[]` in the modern initializer.
- Add `[]` in the legacy initializer.
- Add `strainSessions` to `CodingKeys` and custom decoder with fallback to `[]`.

### 3. StrainCalculator updates
`ReadinessTracker/Models/StrainCalculator.swift`

Changes:
- Extract the per-minute TRIMP logic into a reusable helper:
  `static func trimp(from samples: [HRSample], restingHR: Double, maxHR: Double) -> Double`
- Update `strainFromHRSamples(_:)` to call the helper with the full day's samples.
- Add `static func calculateSessions(from data: DailyHealthData, history: [DailyHealthData]) -> [StrainSession]` that:
  1. Takes each `StrainSession` placeholder (type/start/end from HealthKit workout).
  2. Filters `data.hrSamples` to those within `[startDate, endDate]`.
  3. Computes TRIMP for that interval.
  4. Computes contribution as `(sessionTRIMP / totalDayTRIMP) * dailyStrain` when total > 0; otherwise distributes by duration.

Note: The actual placeholder-to-filled-session flow will be driven by `HealthKitManager`, which has the raw `HKWorkout` list. `StrainCalculator` will provide a helper that enriches a placeholder session with HR-derived TRIMP.

```swift
static func trimp(for workout: StrainSession, using data: DailyHealthData) -> Double {
    guard data.restingHeartRate > 0,
          let maxHR = data.maxHeartRate ?? (UserSettings.load().estimatedMaxHeartRate > 0 ? Double(UserSettings.load().estimatedMaxHeartRate) : nil)
    else { return 0 }

    let workoutSamples = data.hrSamples.filter { $0.timestamp >= workout.startDate && $0.timestamp <= workout.endDate }
    return trimp(from: workoutSamples, restingHR: data.restingHeartRate, maxHR: maxHR)
}
```

### 4. HealthKitManager updates
`ReadinessTracker/Services/HealthKitManager.swift`

Changes:
- Replace `fetchWorkoutMinutes(startOfDay:endOfDay:)` with `fetchWorkouts(startOfDay:endOfDay:) -> [StrainSession]`.
- For each `HKWorkout`:
  - Map `workoutActivityType` to a readable name (e.g., "Running", "Cycling", "Strength Training", "Other").
  - Create a `StrainSession` placeholder with `trimp: 0` and `contribution: 0`.
- Pass the workout sessions into `DailyHealthData`.
- Keep a computed `workoutMinutes` equivalent from the sum of session durations for fallback strain scoring.

### 5. RecoveryStrainDetailView updates
`ReadinessTracker/Views/RecoveryStrainDetailView.swift`

Changes:
- Add a "Workouts" section below the strain breakdown.
- For each `data.strainSessions`, show:
  - Workout type icon/name.
  - Duration.
  - TRIMP points.
  - Contribution to daily strain (optional bar).
- If no workouts, show a compact "No recorded workouts" line.

### 6. Unit tests (new)
`ReadinessTrackerTests/StrainSessionTests.swift`

Tests:
- `testWorkoutTRIMPFromHRSamples`: synthetic HR samples inside/outside workout interval yield correct TRIMP.
- `testFallbackWorkoutWithoutHRSamples`: workout with no HR samples gets duration-based estimate.
- `testDailyDataEncodesStrainSessions`: encode/decode round-trip preserves sessions.

## Data Flow

1. User refreshes data.
2. `HealthKitManager.fetchTodayData()` queries `HKWorkout` samples for the day and builds `[StrainSession]` placeholders.
3. `DailyHealthData` stores `hrSamples` and `strainSessions`.
4. `StrainCalculator` computes daily strain; views display workout-level detail from `data.strainSessions`.
5. For historical backfill, `fetchHistoricalData()` builds the same placeholders.

## Error Handling

- If HealthKit workout access is denied, `strainSessions` remains empty; daily strain falls back to existing active-calories/workout-minutes logic.
- If a workout has no HR samples, show the session with `trimp: 0` and optionally a duration-based estimate in the detail view.
- Backward compatibility: old persisted data loads with `strainSessions = []`.

## Backward Compatibility

- `DailyHealthData` custom decoder defaults missing `strainSessions` to `[]`.
- `StrainCalculator.calculate` still returns 0-21; workouts are additive detail, not a replacement for the daily score.

## Success Criteria

- App builds with zero errors.
- Unit tests for workout TRIMP pass.
- Existing Phase 2A tests still pass.
- `RecoveryStrainDetailView` shows workout list when HealthKit workouts exist.

## Out of Scope

- Live strain during an active workout (real-time).
- Editing or manually adding workouts.
- GPS/pace-based workout intensity.
