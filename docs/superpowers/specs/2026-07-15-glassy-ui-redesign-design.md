# ReadinessTracker — Glassy UI Redesign (Glassmorphism) Design

## Goal

Redesign the entire app UI to an Apple-style glassmorphism look: translucent materials, blur, rounded corners, subtle borders, and soft shadows. Apply consistently across every view while preserving all existing functionality.

## Background

- Current design uses solid `NativeCard` with `RTColor.surface` background.
- Many views use `NativeCard`; some use `RTColor.surface` directly.
- App targets iOS 16+, so SwiftUI materials (`.ultraThinMaterial`) are available.
- No new dependencies allowed.

## Architecture

```
RTColor / AppleTheme (glass tokens)
        │
        ▼
GlassCard / GlassRow / GlassBackground
        │
        ▼
All Views (Dashboard, Detail, History, Sleep, Trends, Metrics, Journal, CheckIn, Settings, Breathing, WhoopFeatures)
```

## Design System

### Glass tokens

In `ReadinessTracker/Design/Theme.swift` add:

```swift
static let glassBackground = Color.white.opacity(0.08)
static let glassBorder = Color.white.opacity(0.12)
static let glassHighlight = Color.white.opacity(0.04)
```

In `ReadinessTracker/Design/AppleNativeTheme.swift` add:

```swift
static let glassShadowOpacity: Double = 0.12
static let glassShadowRadius: CGFloat = 12
static let glassShadowY: CGFloat = 6
```

### New/updated components

1. **GlassCard** — new reusable card in `ReadinessTracker/Design/Components.swift`:

```swift
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AppleTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [RTColor.glassHighlight, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                            .stroke(RTColor.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(AppleTheme.glassShadowOpacity), radius: AppleTheme.glassShadowRadius, x: 0, y: AppleTheme.glassShadowY)
            )
    }
}
```

2. **NativeCard** — change implementation to use the same glass material (keeps existing API so callers upgrade automatically).

3. **GlassRow** — new row background for list items and buttons:

```swift
struct GlassRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                            .stroke(RTColor.glassBorder, lineWidth: 0.5)
                    )
            )
    }
}
```

4. **GlassBackground** — full-screen background with subtle gradient (replaces plain `RTColor.background.ignoresSafeArea()`).

5. **StatGridItem**, **NativePeriodSelector**, **OutlierCallout**, **ChartTooltip** — update backgrounds to glass materials.

6. **Tab bar** — use `.ultraThinMaterial` background via `ToolbarBackgroundVisibility`.

## Per-View Target

All views below get glass cards, rows, and backgrounds. Existing layout logic, data flow, and navigation stay unchanged.

| View | Glass changes |
|------|---------------|
| `DashboardView` | Glass hero, metric grid, quick trends, WHOOP section, recommendation card |
| `ReadinessDetailView` | Glass breakdown, component rows, history chart |
| `RecoveryStrainDetailView` | Glass wheel, balance, nutrition, workouts, history chart |
| `ContentView` / `HistoryView` | Glass tab bar, history rows, trend chart |
| `DayDetailView` | Glass ring, metrics, context cards |
| `SleepAnalysisView` | Glass timeline, stage cards, debt |
| `TrendDetailView` | Glass chart card, stat cards, selectors |
| `MetricDetailView` | Glass cards |
| `AdvancedMetricDetailView` | Glass hero, toggles, distribution |
| `AdvancedMetricChartView` | Glass chart card |
| `SmartInsightsView` | Glass insight cards |
| `RecoveryTrajectoryView` | Glass bars |
| `WeeklyPatternView` | Glass day-of-week bars |
| `DistributionHistogramView` | Glass histogram card |
| `MetricCorrelationView` | Glass scatter card |
| `WeeklyReportView` | Glass header, stat grid, highlights |
| `QuickTrendCard` | Glass card |
| `StrainRecoveryBalanceCard` | Glass card |
| `JournalView` / `JournalEntryView` | Glass form and entry cards |
| `CheckInView` | Glass form, buttons |
| `BreathingView` | Glass instructions, timer card |
| `SyncStatusView` | Glass pill |
| `WhoopFeatures` cards | Glass styling |

## Backward Compatibility

- No persisted model changes.
- No new dependencies.
- Existing unit tests must still pass.
- iOS 16+ only.

## Success Criteria

- App builds with zero errors.
- All 38 existing unit tests pass.
- Every view uses glassmorphism consistently.
- No direct `RTColor.surface` backgrounds remain outside the design system.

## Out of Scope

- iOS 26 "Liquid Glass" exclusive APIs.
- Light-mode-only styling.
- Animation/parallax effects beyond subtle shadows.

## Rollout Order

1. Design system: tokens, `GlassCard`, `GlassRow`, `GlassBackground`, update `NativeCard`.
2. Shared components: `StatGridItem`, `NativePeriodSelector`, `OutlierCallout`, `ChartTooltip`, tab bar.
3. Core views: Dashboard, ReadinessDetail, RecoveryStrainDetail, ContentView/History, DayDetail, SleepAnalysis.
4. Analytics views: TrendDetail, MetricDetail, AdvancedMetric*, SmartInsights, RecoveryTrajectory, WeeklyPattern, DistributionHistogram, MetricCorrelation.
5. Report/trend cards: WeeklyReportView, QuickTrendCard, StrainRecoveryBalanceCard.
6. WhoopFeatures cards.
7. Forms: JournalView, CheckInView, BreathingView, SyncStatusView.
8. Final verification.
