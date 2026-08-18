import SwiftUI

// MARK: - Metric Card (updated for Apple native style)
struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    let sparklineData: [Double]
    let metricType: MetricType
    let currentValue: Double
    let history: [DailyHealthData]
    let source: DataSource

    private var trendBadgeValue: String {
        guard sparklineData.count >= 2 else { return "0%" }
        let latest = sparklineData.last ?? currentValue
        let prev = sparklineData.dropLast().last ?? latest
        guard prev > 0 else { return "0%" }
        let change = (latest - prev) / prev * 100
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", change))%"
    }

    var body: some View {
        NavigationLink(destination: AdvancedMetricDetailView(
            metric: metricType,
            currentValue: currentValue,
            history: history,
            source: source
        )) {
            NativeCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header: icon + title + trend
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(color)
                            Text(title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RTColor.secondaryText)
                        }
                        Spacer()
                        CompactTrendIndicator(direction: trend, percentChange: nil)
                    }

                    // Value
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(value)
                            .font(AppleTheme.cardValue)
                            .foregroundStyle(.white)
                        Text(unit)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    // Sparkline
                    if sparklineData.count >= 2 {
                        AnimatedSparkline(data: sparklineData, color: color)
                            .frame(height: 32)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                Haptic.press()
            }
        )
    }
}

// MARK: - GlassCard (deprecated - kept for backward compat, redirects to NativeCard)
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        NativeCard {
            content
        }
    }
}

// MARK: - Trend Arrow (updated for native style)
struct TrendArrow: View {
    let direction: TrendDirection
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: direction.systemImage)
                .font(.caption.weight(.semibold))
            Text(direction.label)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(color)
    }
}

// MARK: - Section Header (updated for native style)
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        AppSectionHeader(title: title, action: action)
    }
}

// MARK: - Trend Period Selector (updated for native style)
struct TrendPeriodSelector: View {
    @Binding var period: TrendPeriod

    var body: some View {
        AppSegmentedControl(options: TrendPeriod.allCases, selection: $period) { $0.label }
            .onChange(of: period) { _ in Haptic.selectionChanged() }
    }
}

// MARK: - Sleep Stage Bar
struct SleepStageBar: View {
    let stages: [(label: String, percent: Double, color: Color)]
    
    var body: some View {
        GeometryReader { geo in
            let total = stages.reduce(0) { $0 + max(0, $1.percent) }
            let width = geo.size.width
            
            HStack(spacing: 3) {
                ForEach(Array(stages.enumerated()), id: \.offset) { _, stage in
                    let pct = total > 0 ? stage.percent / total : 0
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(stage.color)
                        .frame(width: max(4, width * CGFloat(pct)))
                        .overlay(
                            // Show label if segment is wide enough
                            Group {
                                if pct > 0.15 {
                                    Text("\(Int(stage.percent * 100))%")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
            }
        }
        .frame(height: 32)
    }
}
// MARK: - Navigation Destinations

struct MetricDestination: Hashable {
    let metric: MetricType
    let currentValue: Double
    let history: [DailyHealthData]
    let source: DataSource
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(metric)
        hasher.combine(currentValue)
        hasher.combine(source)
    }
    
    static func == (lhs: MetricDestination, rhs: MetricDestination) -> Bool {
        lhs.metric == rhs.metric &&
        lhs.currentValue == rhs.currentValue &&
        lhs.source == rhs.source
    }
}

struct SleepDestination: Hashable {
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data.id)
    }
    
    static func == (lhs: SleepDestination, rhs: SleepDestination) -> Bool {
        lhs.data.id == rhs.data.id
    }
}

struct JournalDestination: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine("journal")
    }
    
    static func == (lhs: JournalDestination, rhs: JournalDestination) -> Bool {
        true
    }
}

struct ReadinessDestination: Hashable {
    let scores: DualReadinessScores
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data.id)
        hasher.combine(scores.general)
    }
    
    static func == (lhs: ReadinessDestination, rhs: ReadinessDestination) -> Bool {
        lhs.data.id == rhs.data.id
    }
}

struct RecoveryStrainDestination: Hashable {
    let data: DailyHealthData
    let history: [DailyHealthData]
    let scores: DualReadinessScores
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data.id)
    }
    
    static func == (lhs: RecoveryStrainDestination, rhs: RecoveryStrainDestination) -> Bool {
        lhs.data.id == rhs.data.id
    }
}

struct TrendDestination: Hashable {
    let history: [DailyHealthData]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(history.count)
        hasher.combine(history.first?.id.uuidString ?? "")
    }
    
    static func == (lhs: TrendDestination, rhs: TrendDestination) -> Bool {
        lhs.history.count == rhs.history.count
    }
}


// MARK: - App Background (Apple Health style full-screen gradient)
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [RTColor.appBackgroundTop, RTColor.appBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - App Icon Tile (Apple Health style)
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

// MARK: - App List Row (Apple Health style)
struct AppListRow: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    var showChevron: Bool = true

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
