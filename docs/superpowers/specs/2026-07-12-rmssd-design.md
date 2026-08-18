# ReadinessTracker Phase 2A — Real HRV RMSSD Design

## Goal
Replace SDNN-based HRV recovery scoring with RMSSD computed from HealthKit heartbeat-series RR intervals, the metric WHOOP uses for recovery.

## Background
- Phase 1 stores HRV in `DailyHealthData.hrv` and tracks whether it is RMSSD via `hrvIsRMSSD: Bool`.
- `HealthKitManager` currently fetches `HKQuantityTypeIdentifierHeartRateVariabilitySDNN` only.
- `RecoveryCalculator.scoreHRV` uses `data.hrv` directly, ignoring `hrvIsRMSSD`.
- `HRVFrequencyAnalyzer` already works with raw RR intervals; we need a similar path for time-domain RMSSD.

## Architecture

```
HealthKit heartbeat series sample
        │
        ▼
HKHeartbeatSeriesQuery ──► [RR intervals in ms]
        │
        ▼
HRVCalculator.rmssd([RR]) ──► RMSSD (ms)
        │
        ▼
DailyHealthData(hrv: rmssd, hrvIsRMSSD: true)
        │
        ▼
RecoveryCalculator.scoreHRV(rmssd, history)
```

When no heartbeat-series sample exists for the day, the system falls back to the existing SDNN path and keeps `hrvIsRMSSD = false`.

## Components

### 1. HRVCalculator (new)
`ReadinessTracker/Models/HRVCalculator.swift`

Responsibilities:
- Compute RMSSD from an array of RR intervals in milliseconds.
- Compute SDNN from an array of RR intervals (optional helper for tests/validation).
- Provide a safe wrapper that returns `nil` for fewer than 2 intervals.

```swift
import Foundation

enum HRVCalculator {
    /// Root mean square of successive differences (RMSSD) in ms.
    static func rmssd(from rrIntervalsMs: [Double]) -> Double? {
        guard rrIntervalsMs.count >= 2 else { return nil }
        let diffs = zip(rrIntervalsMs.dropFirst(), rrIntervalsMs).map { $0 - $1 }
        let squared = diffs.map { $0 * $0 }
        let mean = squared.reduce(0, +) / Double(squared.count)
        return sqrt(mean)
    }

    /// Standard deviation of NN intervals (SDNN) in ms.
    static func sdnn(from rrIntervalsMs: [Double]) -> Double? {
        guard rrIntervalsMs.count >= 2 else { return nil }
        let mean = rrIntervalsMs.reduce(0, +) / Double(rrIntervalsMs.count)
        let variance = rrIntervalsMs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rrIntervalsMs.count)
        return sqrt(variance)
    }
}
```

### 2. HealthKitManager updates
`ReadinessTracker/Services/HealthKitManager.swift`

Changes:
- Add `HKObjectType.seriesType(forIdentifier: .heartbeat)!` to `typesToRead` in `requestAuthorization()`.
- Add `fetchHeartbeatSeriesRRIntervals(predicate:) async -> [Double]` using `HKHeartbeatSeriesQuery`.
- Add `fetchRMSSD(predicate:) async -> (value: Double, isRMSSD: Bool)` that tries heartbeat series first, then falls back to SDNN.
- Update `fetchTodayData()` and `fetchHistoricalData()` to use the new method and pass `hrvIsRMSSD`.

Heartbeat-series extraction:
```swift
private func fetchHeartbeatSeriesRRIntervals(predicate: NSPredicate) async -> [Double] {
    guard let seriesType = HKObjectType.seriesType(forIdentifier: .heartbeat) else { return [] }
    return await withCheckedContinuation { continuation in
        let query = HKSampleQuery(sampleType: seriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
            guard let seriesSamples = samples as? [HKHeartbeatSeriesSample], let first = seriesSamples.first else {
                continuation.resume(returning: [])
                return
            }
            var rrIntervals: [Double] = []
            var previousTimeSeconds: TimeInterval?
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: first) { _, timeSinceSampleStart, precededByGap, done, error in
                if let time = timeSinceSampleStart {
                    if let previous = previousTimeSeconds, !precededByGap {
                        let rrMs = (time - previous) * 1000.0
                        rrIntervals.append(rrMs)
                    }
                    previousTimeSeconds = time
                }
                if done {
                    continuation.resume(returning: rrIntervals)
                }
            }
            self.healthStore.execute(query)
        }
        self.healthStore.execute(query)
    }
}
```

Note: `HKHeartbeatSeriesQuery` provides `timeSinceSampleStart` as cumulative seconds from the series start. RR intervals are computed as differences between successive beats. Intervals preceded by a gap are discarded to avoid artifacts.

### 3. RecoveryCalculator updates
`ReadinessTracker/Models/RecoveryCalculator.swift`

Changes:
- `scoreHRV` already operates on a ratio vs baseline, so the math stays the same.
- Add an explicit comment/docstring that the input is expected to be RMSSD when `hrvIsRMSSD` is true.
- No functional change required; correctness comes from HealthKitManager now supplying real RMSSD.

### 4. UI label updates
`ReadinessTracker/Views/DashboardView.swift` and `ReadinessTracker/Views/ReadinessScoreDetailView.swift`

Changes:
- Where HRV is displayed as `"HRV"` / `"ms"`, show `"RMSSD"` when `data.hrvIsRMSSD` is true to signal the upgraded metric.
- Example: `Text(data.hrvIsRMSSD ? "RMSSD" : "HRV")`.

### 5. Unit tests (new)
`ReadinessTrackerTests/HRVCalculatorTests.swift`

Tests:
- `testRMSSDFromKnownRRIntervals` — fixed input yields known RMSSD.
- `testRMSSDLessThanTwoIntervalsReturnsNil` — guard works.
- `testSDNNFromKnownRRIntervals` — optional validation.
- `testRecoveryPrefersRMSSDWhenFlagSet` — mock `DailyHealthData` with `hrvIsRMSSD = true` and verify scoring path.

## Data Flow

1. App launches / user pulls to refresh.
2. `HealthKitManager.fetchTodayData()` builds the daily predicate.
3. `fetchRMSSD(predicate:)`:
   - Queries heartbeat series samples for the day.
   - If found, extracts RR intervals, computes RMSSD, returns `(rmssd, true)`.
   - If not found, queries SDNN, returns `(sdnn, false)`.
4. `DailyHealthData` stores `hrv` and `hrvIsRMSSD`.
5. `RecoveryCalculator` uses `hrv` for recovery score (ratio vs RMSSD or SDNN baseline).

## Error Handling

- If heartbeat-series query fails or returns no intervals, silently fall back to SDNN.
- If both fail, store `hrv: 0` and `hrvIsRMSSD: false`; `scoreHRV` returns the existing `50` default.
- `HRVCalculator` returns `nil` for invalid input; caller handles fallback.

## Backward Compatibility

- Existing persisted `DailyHealthData` has `hrvIsRMSSD` missing or false; custom decoder already defaults to `false`.
- Old SDNN data continues to score as before.
- New data uses RMSSD when available.

## Success Criteria

- App builds with zero errors.
- Unit tests for `HRVCalculator` pass.
- Existing Phase 1 tests still pass.
- UI shows "RMSSD" label when heartbeat-series data is available.
- Recovery score responds correctly to synthetic RMSSD inputs.

## Out of Scope

- Real-time RMSSD during active workouts.
- Frequency-domain analysis using RMSSD (existing `HRVFrequencyAnalyzer` stays separate).
- Cross-device RR-interval normalization beyond unit conversion.
