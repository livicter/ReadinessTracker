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
        NavigationLink(destination: MetricDetailView(
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
                            .foregroundStyle(RTColor.primaryText)
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
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("metric.card.\(metricType.rawValue)")
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
        .accessibilityElement(children: .combine)
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
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(stage.color.contrastingTextColor)
                                }
                            }
                        )
                }
            }
        }
        .frame(height: 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sleep stages")
        .accessibilityValue(stages.map { "\($0.label) \(Int($0.percent * 100)) percent" }.joined(separator: ", "))
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
            .accessibilityHidden(true)
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
                .foregroundStyle(RTColor.primaryText)
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
        .accessibilityElement(children: .combine)
    }
}


// MARK: - Body metric (Google Health / Fitness–style)

/// Body & activity tile identity. Workout minutes use the **Activity** label (Google Fit heart-points naming is out of scope).
enum BodyMetricKind: String, Identifiable, CaseIterable {
    case steps
    case activity
    case calories
    case spo2
    case water
    case caffeine
    case protein

    var id: String { rawValue }

    var label: String {
        switch self {
        case .steps: return "Steps"
        case .activity: return "Activity"
        case .calories: return "Calories"
        case .spo2: return "SpO2"
        case .water: return "Water"
        case .caffeine: return "Caffeine"
        case .protein: return "Protein"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .activity: return "flame.fill"
        case .calories: return "bolt.fill"
        case .spo2: return "lungs.fill"
        case .water: return "drop.fill"
        case .caffeine: return "cup.and.saucer.fill"
        case .protein: return "fork.knife"
        }
    }

    var color: Color {
        switch self {
        case .steps: return RTColor.optimal
        case .activity: return RTColor.strain
        case .calories: return RTColor.caution
        case .spo2: return RTColor.hrv
        case .water: return Color(hex: "5AC8FA")
        case .caffeine: return Color(hex: "AC8E68")
        case .protein: return RTColor.good
        }
    }

    /// Daily goal used for progress-to-goal (Fitness / Google Health glance). Nil = no ring.
    var goal: Double? {
        switch self {
        case .steps: return 10_000
        case .activity: return 30
        case .calories: return 500
        case .water: return 2.5
        case .protein: return 120
        case .spo2, .caffeine: return nil
        }
    }

    var goalCaption: String? {
        switch self {
        case .steps: return "of 10,000"
        case .activity: return "of 30 min"
        case .calories: return "of 500 cal"
        case .water: return "of 2.5 L"
        case .protein: return "of 120 g"
        case .spo2, .caffeine: return nil
        }
    }

    var metricCaption: String {
        switch self {
        case .steps: return "Steps"
        case .activity: return "Activity minutes"
        case .calories: return "Active calories"
        case .spo2: return "Blood oxygen %"
        case .water: return "Water (L)"
        case .caffeine: return "Caffeine (mg)"
        case .protein: return "Protein (g)"
        }
    }

    var accessibilityIdentifier: String {
        "body.tile.\(rawValue)"
    }

    func rawValue(from data: DailyHealthData) -> Double? {
        switch self {
        case .steps: return Double(data.steps)
        case .activity: return Double(data.workoutMinutes)
        case .calories: return data.activeCalories
        case .spo2:
            guard let v = data.bloodOxygen, v > 0 else { return nil }
            return v > 1.0 ? v : v * 100
        case .water: return data.nutrition.waterLiters
        case .caffeine: return data.nutrition.caffeineMg
        case .protein: return data.nutrition.proteinGrams
        }
    }

    func displayValue(from data: DailyHealthData) -> String {
        switch self {
        case .steps:
            return "\(data.steps)"
        case .activity:
            return "\(data.workoutMinutes) min"
        case .calories:
            return "\(Int(data.activeCalories))"
        case .spo2:
            guard let v = rawValue(from: data) else { return "—" }
            return String(format: "%.0f%%", v)
        case .water:
            guard let v = data.nutrition.waterLiters else { return "—" }
            return String(format: "%.1f L", v)
        case .caffeine:
            guard let v = data.nutrition.caffeineMg else { return "—" }
            return "\(Int(v)) mg"
        case .protein:
            guard let v = data.nutrition.proteinGrams else { return "—" }
            return "\(Int(v)) g"
        }
    }

    /// Chronological last-up-to-7 from ascending history.
    func series(from history: [DailyHealthData]) -> [Double] {
        let window = Array(history.suffix(7))
        switch self {
        case .steps: return window.map { Double($0.steps) }
        case .activity: return window.map { Double($0.workoutMinutes) }
        case .calories: return window.map { $0.activeCalories }
        case .spo2:
            return window.compactMap { day -> Double? in
                guard let v = day.bloodOxygen, v > 0 else { return nil }
                return v > 1.0 ? v : v * 100
            }
        case .water: return window.compactMap { $0.nutrition.waterLiters }
        case .caffeine: return window.compactMap { $0.nutrition.caffeineMg }
        case .protein: return window.compactMap { $0.nutrition.proteinGrams }
        }
    }

    func progress(from data: DailyHealthData) -> Double? {
        guard let goal, goal > 0, let value = rawValue(from: data) else { return nil }
        return min(max(value / goal, 0), 1)
    }
}

/// Compact Fitness / Google Health tile: value, optional progress-to-goal, optional sparkline.
struct BodyMetricTile: View {
    let kind: BodyMetricKind
    let data: DailyHealthData
    let history: [DailyHealthData]
    var onTap: (() -> Void)? = nil

    private var series: [Double] { kind.series(from: history) }
    private var progress: Double? { kind.progress(from: data) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: kind.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(kind.color)
                Text(kind.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.displayValue(from: data))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(RTColor.primaryText)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let caption = kind.goalCaption, progress != nil {
                        Text(caption)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(RTColor.tertiaryText)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                if let progress {
                    // Static compact ring — avoid stacking ActivityRing onAppear animations on Today.
                    BodyCompactProgressRing(progress: progress, color: kind.color, size: 36, lineWidth: 5)
                        .accessibilityHidden(true)
                }
            }

            if series.count >= 2 {
                AnimatedSparkline(data: series, color: kind.color)
                    .frame(height: 22)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surfaceHighlight.opacity(0.55))
        )
        .contentShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        .onTapGesture {
            Haptic.press()
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(kind.label), \(kind.displayValue(from: data))")
        .accessibilityIdentifier(kind.accessibilityIdentifier)
    }
}

/// Focused Body metric detail — Fitness / Google Health glance with 7-day spark + bars.
struct BodyMetricDetailView: View {
    let kind: BodyMetricKind
    let data: DailyHealthData
    let history: [DailyHealthData]

    @Environment(\.dismiss) private var dismiss

    private var series: [Double] { kind.series(from: history) }
    private var progress: Double? { kind.progress(from: data) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: kind.icon)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(kind.color)
                            Text(kind.label)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(RTColor.primaryText)
                        }
                        Text(kind.displayValue(from: data))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(kind.color)
                            .monospacedDigit()
                            .accessibilityIdentifier("body.detail.value")
                        if let caption = kind.goalCaption {
                            Text(caption)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(RTColor.secondaryText)
                        }
                    }
                    .padding(.top, 8)

                    if let progress {
                        ActivityRing(
                            progress: progress,
                            color: kind.color,
                            lineWidth: 16,
                            size: 140
                        )
                        .accessibilityIdentifier("body.detail.ring")
                        Text("\(Int(progress * 100))% of daily goal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Last 7 days")
                            .font(.headline)
                            .foregroundStyle(RTColor.primaryText)
                        Text(kind.metricCaption)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)

                        if series.count >= 2 {
                            AnimatedSparkline(data: series, color: kind.color)
                                .frame(height: 56)
                                .padding(.vertical, 8)
                                .accessibilityIdentifier("body.detail.sparkline")

                            BodyMiniBarChart(values: series, color: kind.color)
                                .frame(height: 72)
                                .accessibilityIdentifier("body.detail.bars")
                        } else {
                            Text("Not enough history yet")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.tertiaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(RTColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(20)
            }
            .background(AppBackground())
            .navigationTitle(kind.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("body.detail")
        }
    }
}

/// Non-animated progress ring for Body tiles (keeps Today scroll light).
private struct BodyCompactProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

/// Compact 7-day mini bars for body metric detail.
private struct BodyMiniBarChart: View {
    let values: [Double]
    let color: Color

    private var maxValue: Double {
        max(values.max() ?? 1, 0.001)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(color.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, CGFloat(value / maxValue) * 72))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .accessibilityHidden(true)
    }
}
