# ReadinessTracker — Apple Health Native UI Redesign Design

## Goal

Redesign the entire app to look like Apple Health / Apple Fitness while keeping every existing feature, data flow, and navigation path intact.

## Background

- Current UI uses a glassmorphism design (`NativeCard` with `.ultraThinMaterial`).
- The app has many views: Dashboard, ReadinessDetail, RecoveryStrainDetail, History, DayDetail, SleepAnalysis, TrendDetail, MetricDetail, AdvancedMetric*, WeeklyReport, QuickTrend, Balance, WhoopFeatures, Journal, CheckIn, Breathing, SyncStatus.
- App targets iOS 16+, no new dependencies allowed.

## Architecture

```
RTColor / AppleTheme (Apple Health tokens)
        │
        ▼
NativeCard / AppIconTile / AppListRow / AppSectionHeader / AppSegmentedControl / AppStatPill / AppButton
        │
        ▼
All Views
```

## Design System

### Tokens

In `Theme.swift`:
- Keep existing `RTColor` palette.
- Add `appBackgroundTop` / `appBackgroundBottom` for the screen gradient.
- Add `cardShadowOpacity`, `cardShadowRadius`, `cardShadowY`.

In `AppleNativeTheme.swift`:
- `cornerRadiusLarge: 16`, `cornerRadiusMedium: 12`, `cornerRadiusSmall: 10`.
- `sectionSpacing: 24`, `cardPadding: 16`, `horizontalMargin: 20`.
- `heroValue`, `cardValue`, `sectionHeader` fonts stay.

### Components

1. **AppBackground** — full-screen near-black gradient:
```swift
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color.black, RTColor.background],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
```

2. **NativeCard** — solid card with soft shadow and subtle top highlight:
```swift
struct NativeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AppleTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                    .fill(RTColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.03), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .shadow(color: .black.opacity(AppleTheme.cardShadowOpacity), radius: AppleTheme.cardShadowRadius, x: 0, y: AppleTheme.cardShadowY)
            )
    }
}
```

3. **AppIconTile** — colored rounded-square icon container:
```swift
struct AppIconTile: View {
    let systemName: String
    let color: Color
    var size: CGFloat = 32

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
```

4. **AppListRow** — icon tile + label + value + optional chevron:
```swift
struct AppListRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let showChevron: Bool

    var body: some View {
        HStack(spacing: 12) {
            AppIconTile(systemName: icon, color: color)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surface)
        )
    }
}
```

5. **AppSectionHeader** — bold title + optional action:
```swift
struct AppSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppleTheme.sectionHeader)
                .foregroundStyle(.white)
            Spacer()
            if let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(RTColor.secondaryText)
                }
            }
        }
    }
}
```

6. **AppSegmentedControl** — solid pill selector:
```swift
struct AppSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection == option ? .white : RTColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(RTColor.surfaceHighlight)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusSmall, style: .continuous))
    }
}
```

7. **AppStatPill** — large value + label + trend:
```swift
struct AppStatPill: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    let trend: TrendDirection?

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(AppleTheme.cardValue)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
            if let trend {
                CompactTrendIndicator(direction: trend, percentChange: nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
    }
}
```

8. **AppButton** — filled accent button:
```swift
struct AppButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        }
    }
}
```

## Per-View Target

Every view keeps its existing data flow and navigation. Only presentation changes.

| View | Apple Health changes |
|------|----------------------|
| `DashboardView` | Large title, hero card with ring + score, 2×2 metric grid with icon tiles, section headers, glass tab bar stays |
| `ReadinessDetailView` | Hero card, breakdown bars, component rows using AppListRow |
| `RecoveryStrainDetailView` | Hero wheel card, balance card, nutrition/workout rows using AppListRow |
| `ContentView` / `HistoryView` | Grouped list with date + score rows, AppBackground |
| `DayDetailView` | Score ring card, metric grid, context cards |
| `SleepAnalysisView` | Timeline card, stage cards, debt card |
| `TrendDetailView` | Chart card, stat grid, segmented control |
| `MetricDetailView` | Chart card, stat cards, segmented control |
| `AdvancedMetricDetailView` | Hero card, toggles, distribution card |
| `SmartInsightsView` | Insight rows using AppListRow |
| `RecoveryTrajectoryView` | Bar chart card |
| `WeeklyPatternView` | Day-of-week card |
| `DistributionHistogramView` | Histogram card |
| `MetricCorrelationView` | Scatter card |
| `WeeklyReportView` | Header card, stat grid, highlights |
| `QuickTrendCard` | Metric card with icon tile and trend |
| `StrainRecoveryBalanceCard` | Balance card with score and status |
| `JournalView` | Form rows, entry cards |
| `CheckInView` | Form with AppListRow-style rows, AppButton |
| `BreathingView` | Instruction card, timer card |
| `SyncStatusView` | Status pill using AppListRow style |
| `WhoopFeatures` cards | Convert rows/cards to AppListRow/NativeCard |

## Backward Compatibility

- No persisted model changes.
- No new dependencies.
- All existing unit tests must pass.
- iOS 16+ only.

## Success Criteria

- App builds with zero errors.
- All 38 tests pass.
- Every view uses Apple Health patterns consistently.
- No glassmorphism materials remain (`ultraThinMaterial`, `glassBorder`, `glassHighlight`).

## Out of Scope

- iOS 26 Liquid Glass APIs.
- Light-mode-specific styling.
- New features.

## Rollout Order

1. Design system tokens and components.
2. Core views: Dashboard, ReadinessDetail, RecoveryStrainDetail, ContentView/History, DayDetail, SleepAnalysis.
3. Analytics views: TrendDetail, MetricDetail, AdvancedMetric*, SmartInsights, RecoveryTrajectory, WeeklyPattern, DistributionHistogram, MetricCorrelation.
4. Report/trend cards: WeeklyReportView, QuickTrendCard, StrainRecoveryBalanceCard.
5. WhoopFeatures cards.
6. Forms: JournalView, CheckInView, BreathingView, SyncStatusView.
7. Final verification.
