# ReadinessTracker Phase 2C — Breadth Metrics (SpO2 + Nutrition + Menstrual Cycle) Design

## Goal
Add Google Health-style breadth metrics: score SpO2 in recovery, surface hydration/caffeine/protein context, and optionally log menstrual cycle impact.

## Background
- `HealthKitManager` already fetches `bloodOxygen` but it is not used in scoring.
- Nutrition types (water, caffeine, protein) are not fetched.
- Menstrual cycle data is not accessed.

## Architecture

```
HealthKit nutrition + SpO2 + menstrual flow
        │
        ▼
NutritionSummary + spo2 + menstrualFlow
        │
        ▼
DailyHealthData
        │
        ▼
RecoveryCalculator (SpO2 score + optional menstrual adjustment)
        │
        ▼
ReadinessDetailView / RecoveryStrainDetailView
```

## Components

### 1. NutritionSummary model (new)
`ReadinessTracker/Models/NutritionSummary.swift`

```swift
import Foundation

struct NutritionSummary: Codable, Hashable {
    let waterLiters: Double?
    let caffeineMg: Double?
    let proteinGrams: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
    }
}
```

### 2. DailyHealthData extension
`ReadinessTracker/Models/HealthData.swift`

Changes:
- Add `let nutrition: NutritionSummary`.
- Add `let menstrualFlow: Bool` (true if any flow logged that day).
- Add defaults in modern init.
- Add empty defaults in legacy init.
- Add to `CodingKeys` and custom decoder.

### 3. RecoveryCalculator updates
`ReadinessTracker/Models/RecoveryCalculator.swift`

Changes:
- Add `spo2Score` to `RecoveryBreakdown`.
- Adjust weights:
  - HRV: 30% (down from 35%)
  - Sleep: 25%
  - RHR: 20%
  - SpO2: 5% (new)
  - Temp: 10%
  - Resp: 10%
- Add `scoreSpO2(_:)`:
  - `≥ 0.98` → 100
  - `≤ 0.90` → 0
  - Linear between
- Add optional menstrual adjustment:
  - If `UserSettings.shared.trackMenstrualCycle` and `data.menstrualFlow`, reduce total score by a small configurable amount (default 3 points, capped so total stays 0-100).

### 4. HealthKitManager updates
`ReadinessTracker/Services/HealthKitManager.swift`

Changes:
- Add nutrition types to authorization:
  - `HKQuantityTypeIdentifierDietaryWater`
  - `HKQuantityTypeIdentifierDietaryCaffeine`
  - `HKQuantityTypeIdentifierDietaryProtein`
- Add menstrual type to authorization:
  - `HKCategoryTypeIdentifierMenstrualFlow`
- Add fetch methods:
  - `fetchNutrition(predicate:) -> NutritionSummary`
  - `fetchMenstrualFlow(predicate:) -> Bool`
- Wire into `fetchTodayData()` and `fetchHistoricalData()`.

### 5. UI updates
- `ReadinessDetailView`: add SpO2 breakdown row.
- `RecoveryStrainDetailView`: add Nutrition card showing water/caffeine/protein when available.
- `UserSettings`: add `trackMenstrualCycle: Bool = false`.

### 6. Tests
- `NutritionSummaryTests`: encode/decode.
- `RecoveryCalculatorTests`: SpO2 scoring and menstrual adjustment.

## Backward Compatibility
- `DailyHealthData` custom decoder defaults missing `nutrition` and `menstrualFlow`.
- SpO2 score returns neutral 75 when no data.
- Menstrual tracking is opt-in and off by default.

## Success Criteria
- App builds with zero errors.
- Unit tests for SpO2 and nutrition pass.
- Existing tests still pass.
- New metrics appear in detail views.

## Out of Scope
- Detailed meal logging.
- Predicting menstrual cycle phases.
- Health Connect integration (Android-only).
