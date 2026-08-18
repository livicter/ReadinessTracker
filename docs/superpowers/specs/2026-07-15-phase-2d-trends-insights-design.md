# ReadinessTracker Phase 2D — Trends + Insights + Weekly Report Design

## Goal

Close WHOOP/Google Health parity gaps by surfacing the analytics that already exist in the codebase and adding a small set of focused, testable insights:

1. A shareable **weekly report view**.
2. A **strain/recovery balance** score + status.
3. **Strain/workout-aware AI recommendations**.
4. **7/30/90-day quick-trend cards** on the Dashboard.

## Background

- `DataStore.history` already persists `DailyHealthData` locally.
- `TrendAnalysisEngine` already computes moving averages, trend classification, weekly patterns, and correlations.
- `WeeklyReportGenerator` exists but has **no view**; only `formattedReport(_:)` is exposed.
- `AIRecommendationEngine` is rule-based but does not yet use strain/workout load.
- Dashboard metric cards already have sparklines and a Trends section.

## Architecture

```
DataStore.history
    │
    ├── TrendAnalysisEngine ──> QuickTrendCard (7/30/90 avg + sparkline + trend strength)
    │
    ├── StrainCalculator.dailyStrain ──┐
    │                                  ├── StrainRecoveryBalance ──> Dashboard balance card + RecoveryStrainDetailView
    └── ReadinessCalculator ───────────┘
    │
    ├── WeeklyReportGenerator ──> WeeklyReportView
    │
    └── AIRecommendationEngine + new strain/recovery/workout rules ──> Dashboard insights
```

## Components

### 1. StrainRecoveryBalance

New value type in `ReadinessTracker/Models/StrainRecoveryBalance.swift`.

```swift
struct StrainRecoveryBalance {
    let score: Int        // 0-100
    let status: String    // "Balanced", "Moderate Load", "Overreaching Risk", "Rest Needed"

    static func compute(recovery: Int, strain: Double) -> StrainRecoveryBalance
}
```

Formula:
- Normalize strain to 0-100: `(strain / 21.0) * 100.0`.
- Balance = `recovery - normalizedStrain`, shifted to 0-100: `score = clamp(raw + 50, 0, 100)`.
- Status thresholds: ≥ 75 Balanced, ≥ 50 Moderate Load, ≥ 25 Overreaching Risk, else Rest Needed.

### 2. WeeklyReportView

Create `ReadinessTracker/Views/WeeklyReportView.swift`.

- Consumes a `WeeklyReport` from `WeeklyReportGenerator`.
- Displays week range, summary stat grid, highlights, recommendations, and a share/action button.
- Reuses `NativeCard`, `RTColor`, `GlassCardV2`, and existing stat-pill patterns.
- Wired from `DashboardView` (existing grid button) and `HistoryView` (new top row).

### 3. AIRecommendationEngine strain/workout rules

Extend `ReadinessTracker/Services/AIRecommendations.swift` with rules such as:

- High strain (> 14) + low recovery (< 50) → critical rest day.
- 3+ consecutive workout days with avg RPE ≥ 7 → taper recommendation.
- Recovery > 80 and strain < 7 → progressive-overload window.
- Hard workout today (RPE ≥ 8) and next-day HRV < baseline × 0.9 → recovery warning.

Rules use `StrainCalculator.calculate`, existing `BaselineManager` baselines, and `MetadataStore` RPE/workout flags.

### 4. QuickTrendCard

Create `ReadinessTracker/Views/QuickTrendCard.swift` or add directly in `DashboardView`.

- For 7/30/90-day windows from `DataStore.dataForSource(source, days:)`.
- Metrics: sleep hours, HRV, RHR, active calories.
- Shows window average, percent change vs previous window, sparkline, and `TrendStrength` badge from `TrendAnalysisEngine.classifyTrend`.
- Placed in Dashboard above or below the existing Trends section.

## File Map

| File | Change |
|------|--------|
| `ReadinessTracker/Models/StrainRecoveryBalance.swift` | New balance value type + tests. |
| `ReadinessTracker/Models/ReadinessCalculator.swift` | Optionally expose balance on `DualReadinessScores`. |
| `ReadinessTracker/Views/DashboardView.swift` | Add balance card and quick-trend row. |
| `ReadinessTracker/Views/RecoveryStrainDetailView.swift` | Show balance score/status and 7-day balance mini-chart. |
| `ReadinessTracker/Views/HistoryView.swift` | Add button to open `WeeklyReportView`. |
| `ReadinessTracker/Views/WeeklyReportView.swift` | New view for `WeeklyReport`. |
| `ReadinessTracker/Services/AIRecommendations.swift` | New strain/recovery/workout rules. |
| `ReadinessTracker/Services/WeeklyReportGenerator.swift` | Optional: include avg strain in report. |
| `ReadinessTrackerTests/StrainRecoveryBalanceTests.swift` | New tests. |
| `ReadinessTrackerTests/AIRecommendationsTests.swift` | New tests for new rules. |
| `ReadinessTrackerTests/QuickTrendTests.swift` | Optional aggregation tests. |

## Data Flow

1. **Balance**: Dashboard computes `strain` and `recovery`, passes to `StrainRecoveryBalance.compute`, renders score/status.
2. **Quick Trends**: Dashboard loads 7/30/90-day slices, computes averages and trend strength, renders `QuickTrendCard`s.
3. **Weekly Report**: `HistoryView` generates report for selected source and pushes `WeeklyReportView`.
4. **AI Recommendations**: `AIRecommendationEngine` loads history + metadata, evaluates new rules, surfaces recommendations in dashboard/detail cards.

## Backward Compatibility

- No persisted-model changes.
- New files only.
- Existing `AIRecommendationEngine` output remains a `[TrainingRecommendation]` array.

## Success Criteria

- App builds with zero errors.
- All existing tests pass.
- New unit tests cover balance formula and new AI rules.
- Weekly report view renders from Dashboard and History.
- Balance card appears on Dashboard and RecoveryStrainDetailView.
- Quick-trend cards show 7/30/90-day averages.

## Out of Scope

- Report history / archive.
- User-tunable balance thresholds.
- Full replacement of existing Trends section.
- Health Connect / cloud sync.

## Rollout Order

1. `StrainRecoveryBalance` model + tests.
2. Dashboard balance card + `RecoveryStrainDetailView` enhancement.
3. `WeeklyReportView` + `HistoryView` wiring.
4. AI recommendation rules + tests.
5. `QuickTrendCard` row + tests.
6. Final verification.
