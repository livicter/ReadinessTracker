# ReadinessTracker — Sleep Cycle + Depth Timeline UI/UX Enhancement Design

## Goal

Bring the app to Apple Health / Google Health parity for sleep and timeline analytics by adding a real hypnogram, sleep-cycle detection, interactive depth timeline graphs, and UI polish — while keeping all existing features.

## Background

- Current sleep data is aggregated per day; raw HealthKit stage intervals are discarded in `HealthKitManager.fetchSleepDataForDate`.
- `SleepAnalysisView` shows a proportional stage bar, a naive cycle estimate (`hours / 1.5`), and a static fake cycle graphic.
- `SleepDisturbanceTracker` is fully built but fed `awakePeriods: []`.
- Timeline charts exist (`TrendDetailView`, `MetricDetailView`, `AdvancedMetricDetailView`) but lack a unified interactive depth timeline with baseline bands and tooltips across all key metrics.

## Architecture

```
HealthKit raw stage samples
        │
        ▼
SleepStageInterval + DailyHealthData.sleepStages
        │
        ▼
SleepCycleDetector (stage transitions → cycles)
        │
        ▼
HypnogramView / SleepCycleView / SleepAnalysisView
        │
        ▼
DepthTimelineChart (readiness, strain, HRV, RHR, sleep)
        │
        ▼
TrendDetailView / MetricDetailView / AdvancedMetricDetailView
```

## Components

### 1. SleepStageInterval model

`ReadinessTracker/Models/SleepStageInterval.swift`

```swift
struct SleepStageInterval: Codable, Hashable {
    let stage: SleepStage
    let startDate: Date
    let endDate: Date

    var durationMinutes: Double {
        endDate.timeIntervalSince(startDate) / 60
    }
}

enum SleepStage: String, Codable, CaseIterable {
    case awake, light, deep, rem

    var color: Color { ... }
    var label: String { ... }
}
```

`DailyHealthData` gains `let sleepStages: [SleepStageInterval]` with a default `[]` and custom-decoder fallback.

### 2. HealthKitManager changes

- Stop discarding raw stage samples.
- Map `HKCategoryValueSleepAnalysis` values to `SleepStage`:
  - `.awake` → `.awake`
  - `.asleepCore`, `.asleepUnspecified` → `.light`
  - `.asleepDeep` → `.deep`
  - `.asleepREM` → `.rem`
- Sort intervals by startDate and store in `DailyHealthData.sleepStages`.

### 3. SleepCycleDetector

`ReadinessTracker/Models/SleepCycleDetector.swift`

- Input: `[SleepStageInterval]` sorted by time.
- Detects cycles as sequences starting at first `.light`/`.deep`/`.rem` after an `.awake` gap > 15 minutes, ending at the next long awake gap or final stage.
- Output: `[SleepCycle]` with `startDate`, `endDate`, `durationMinutes`, `deepMinutes`, `remMinutes`, `lightMinutes`.

### 4. HypnogramView

`ReadinessTracker/Views/HypnogramView.swift`

- Time-ordered horizontal chart: x = time, y = stage (Awake top, REM/Light/Deep below).
- Uses `RectangleMark` per interval with stage color.
- Tap-to-inspect tooltip showing stage, start/end, duration.
- Pinch-to-zoom on time axis.

### 5. SleepCycleView

`ReadinessTracker/Views/SleepCycleView.swift`

- Shows detected cycles as horizontal bars.
- Per-cycle breakdown: duration, deep, REM, light.
- Summary: total cycles, average cycle length.

### 6. DepthTimelineChart

`ReadinessTracker/Views/DepthTimelineChart.swift`

- Reusable chart for any metric series.
- Features: 7/30/90-day selector, baseline ±2σ bands, 7-day moving average, outlier highlighting, tap-to-inspect `ChartTooltip`, pinch zoom.
- Uses `TrendAnalysisEngine` for baseline, MA, z-score, trend classification.

Applied to: readiness score, strain, HRV, RHR, sleep hours in `TrendDetailView` and `MetricDetailView`.

### 7. SleepAnalysisView overhaul

- Replace proportional "Sleep Timeline" bar with `HypnogramView`.
- Replace fake cycle graphic with `SleepCycleView`.
- Feed real awake intervals into `SleepDisturbanceTracker`.
- Keep existing score ring, stage breakdown, timing grid, 7-day trends, debt.

### 8. DayDetailView integration

- Show compact hypnogram (no interaction) in sleep hero.
- Link to full `SleepAnalysisView`.

### 9. Polish

- Consistent `AppSectionHeader` usage.
- Weekly report adds sleep-cycle summary.
- AI recommendations reference sleep-cycle quality (e.g., "Only 3 complete cycles detected").

## Backward Compatibility

- `DailyHealthData` custom decoder defaults `sleepStages` to `[]`.
- Old persisted data loads without intervals; hypnogram shows "No detailed stage data".
- No new dependencies.
- iOS 16+ only.

## Success Criteria

- App builds with zero errors.
- All existing 38 tests pass.
- New tests: `SleepStageInterval` decoding, `SleepCycleDetector` cycle detection, HealthKit stage mapping.
- Hypnogram renders real stage intervals in SleepAnalysisView.
- Depth timeline charts work for readiness, strain, HRV, RHR, sleep.
- UI remains Apple Health style.

## Out of Scope

- Sleep schedule/goal reminders.
- Watch app complications.
- Cloud sync.

## Rollout Order

1. `SleepStageInterval` + `DailyHealthData` + decoder + tests.
2. `HealthKitManager` raw interval storage.
3. `SleepCycleDetector` + tests.
4. `HypnogramView` + `SleepCycleView`.
5. `DepthTimelineChart` + integration.
6. `SleepAnalysisView` overhaul + `DayDetailView` integration.
7. Polish (weekly report, AI recommendations, headers).
8. Final verification.
