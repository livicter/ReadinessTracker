import SwiftUI
import Charts

struct MetricDetailView: View {
    let metric: MetricType
    let currentValue: Double
    let history: [DailyHealthData]
    let source: DataSource

    @State private var selectedPeriod: TrendPeriod = .week
    @State private var selectedDataPoint: DailyHealthData?
    @State private var lastHapticID: DailyHealthData.ID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var filteredHistory: [DailyHealthData] {
        let days = selectedPeriod.rawValue
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    var values: [(date: Date, value: Double)] {
        filteredHistory.map { ($0.date, metricValue(for: $0)) }
    }

    var baseline: Double {
        let vals = values.map { $0.value }
        guard vals.count > 1 else { return currentValue }
        return vals.reduce(0, +) / Double(vals.count)
    }

    var trend: TrendDirection {
        guard values.count >= 2 else { return .flat }
        let recent = values.suffix(3).map { $0.value }.reduce(0, +) / Double(min(3, values.count))
        let threshold = baseline * 0.03
        if abs(recent - baseline) < threshold { return .flat }
        // Trend direction tracks the raw value direction; trendLabel/trendColor
        // handle the higherIsBetter inversion when labeling.
        return recent > baseline ? .up : .down
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RTLayout.sectionSpacing) {
                // Hero value
                heroSection
                    .slideIn(delay: 0)

                // Period selector
                periodSelector
                    .slideIn(delay: 0.05)

                // Main trend chart
                trendChart
                    .slideIn(delay: 0.1)

                // Depth timeline (baseline band + MA7)
                depthTimelineSection
                    .slideIn(delay: 0.12)

                // Stats grid
                statsSection
                    .slideIn(delay: 0.15)

                // Smart Insights
                if values.count >= 3 {
                    SmartInsightsView(
                        metric: metric,
                        history: values,
                        currentValue: currentValue
                    )
                    .slideIn(delay: 0.2)
                }

                // Recovery Trajectory
                if filteredHistory.count >= 5 {
                    RecoveryTrajectoryView(
                        history: values,
                        metric: metric
                    )
                    .slideIn(delay: 0.25)
                }

                // Weekly Pattern
                if values.count >= 7 {
                    WeeklyPatternView(
                        history: values,
                        metric: metric
                    )
                    .slideIn(delay: 0.3)
                }

                // Metric Correlation (HRV vs Sleep for sleep metric, etc)
                if filteredHistory.count >= 3 {
                    let correlationPair = correlationMetrics()
                    MetricCorrelationView(
                        history: filteredHistory,
                        xMetric: correlationPair.x,
                        yMetric: correlationPair.y
                    )
                    .slideIn(delay: 0.35)
                }

                // Why no old data explanation
                if source == .appleWatch {
                    healthKitInfoSection
                        .slideIn(delay: 0.4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .accessibilityIdentifier(SurfaceID.metricDetail)
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        NativeCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 32))
                        .foregroundColor(metric.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.title)
                            .font(RTFont.caption)
                            .foregroundColor(RTColor.secondaryText)

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(formattedValue(currentValue))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(RTColor.primaryText)

                            Text(metric.unit)
                                .font(RTFont.headline)
                                .foregroundColor(RTColor.secondaryText)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        TrendArrow(direction: trend, color: metric.color)
                            .font(.system(size: 20))

                        Text(trendLabel)
                            .font(RTFont.captionSmall)
                            .foregroundColor(trendColor)
                    }
                }

                // Zone indicator
                if let zone = metric.zone(for: currentValue) {
                    HStack(spacing: 8) {
                        Text(zone.label)
                            .font(RTFont.caption)
                            .foregroundColor(zone.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(zone.color.opacity(0.15))
                            .cornerRadius(8)

                        Text(zone.description)
                            .font(RTFont.captionSmall)
                            .foregroundColor(RTColor.secondaryText)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        AppSegmentedControl(options: TrendPeriod.allCases, selection: $selectedPeriod) { $0.label }
            .onChange(of: selectedPeriod) { _ in Haptic.selectionChanged() }
    }

    // MARK: - Depth Timeline
    private var depthTimelineSection: some View {
        NativeCard {
            DepthTimelineChart(
                title: "\(metric.title) Depth Timeline",
                unit: metric.unit,
                color: metric.color,
                points: values,
                period: selectedPeriod
            )
        }
    }

    // MARK: - Trend Chart
    private var trendChart: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Trend")
                        .font(RTFont.headline)
                        .foregroundColor(RTColor.primaryText)

                    Spacer()

                    if selectedDataPoint == nil {
                        Text("Drag to inspect")
                            .font(RTFont.captionSmall)
                            .foregroundColor(RTColor.tertiaryText)
                    }
                }

                if values.count >= 2 {
                    Chart {
                        ForEach(filteredHistory) { point in
                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", metricValue(for: point))
                            )
                            .foregroundStyle(metric.color)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", metricValue(for: point))
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [metric.color.opacity(0.2), metric.color.opacity(0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Value", metricValue(for: point))
                            )
                            .foregroundStyle(point.date.isToday ? metric.color : metric.color.opacity(0.5))
                            .symbolSize(point.date.isToday ? 80 : 40)
                        }

                        if let selected = selectedDataPoint {
                            RuleMark(x: .value("Selected", selected.date))
                                .foregroundStyle(RTColor.primaryText.opacity(0.35))
                                .lineStyle(StrokeStyle(lineWidth: 1))

                            PointMark(
                                x: .value("Selected", selected.date, unit: .day),
                                y: .value("Value", metricValue(for: selected))
                            )
                            .foregroundStyle(metric.color)
                            .symbolSize(120)
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: chartDomain)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedPeriod == .week ? .day : .weekOfYear)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartBackground { proxy in
                        classicAnnotationOverlay(proxy: proxy)
                    }
                    .chartOverlay { proxy in
                        classicScrubOverlay(proxy: proxy)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(SurfaceID.metricChartScrub)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(RTColor.surfaceHighlight)

                        Text("Not enough data")
                            .font(RTFont.body)
                            .foregroundColor(RTColor.secondaryText)

                        Text("Need at least 2 data points to show trends")
                            .font(RTFont.captionSmall)
                            .foregroundColor(RTColor.tertiaryText)
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.metricDetail)
    }

    private func classicAnnotationOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            if let selected = selectedDataPoint {
                let xPos = proxy.position(forX: selected.date) ?? 0
                let yPos = proxy.position(forY: metricValue(for: selected)) ?? 0
                let valueText = formattedValue(metricValue(for: selected))
                ChartTooltip(
                    date: selected.date,
                    value: valueText,
                    unit: metric.unit,
                    deviation: nil,
                    isOutlier: false
                )
                .accessibilityIdentifier(SurfaceID.metricChartSelection)
                .accessibilityLabel(
                    ChartScrubSelection.calloutText(
                        date: selected.date,
                        value: valueText,
                        unit: metric.unit
                    )
                )
                .position(
                    x: min(max(xPos, 80), geometry.size.width - 80),
                    y: max(yPos - 70, 50)
                )
            }
        }
    }

    /// Drag scrub (Apple Health / WHOOP). Parity with AdvancedMetricChartView.
    private func classicScrubOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            selectNearestClassic(at: value.location, proxy: proxy, geo: geo)
                        }
                        .onEnded { _ in
                            selectedDataPoint = nil
                            lastHapticID = nil
                        }
                )
        }
    }

    private func selectNearestClassic(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        let date: Date?
        if #available(iOS 17.0, *) {
            guard let plotFrame = proxy.plotFrame else { return }
            let x = location.x - geo[plotFrame].origin.x
            date = proxy.value(atX: x)
        } else {
            let width = geo.size.width
            guard width > 0,
                  let first = filteredHistory.first?.date,
                  let last = filteredHistory.last?.date else { return }
            date = ChartScrubSelection.date(
                atFraction: location.x / width,
                from: first,
                to: last
            )
        }
        guard let date,
              let idx = ChartScrubSelection.nearestIndex(
                in: filteredHistory.map(\.date),
                to: date
              ) else { return }
        let point = filteredHistory[idx]
        selectedDataPoint = point
        if point.id != lastHapticID {
            lastHapticID = point.id
            if !reduceMotion {
                Haptic.selectionChanged()
            }
        }
    }

    private var chartDomain: ClosedRange<Double> {
        let vals = values.map { $0.value }
        guard let min = vals.min(), let max = vals.max() else {
            return 0...100
        }
        let padding = (max - min) * 0.15
        return (min - padding)...(max + padding)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Statistics")
                    .font(RTFont.headline)
                    .foregroundColor(RTColor.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatItem(label: "Average", value: formattedValue(baseline), unit: metric.unit)
                    StatItem(label: "Best", value: formattedValue(values.map { $0.value }.max() ?? 0), unit: metric.unit)
                    StatItem(label: "Worst", value: formattedValue(values.map { $0.value }.min() ?? 0), unit: metric.unit)
                    StatItem(label: "Data Points", value: "\(values.count)", unit: "days")
                }
            }
        }
    }

    // MARK: - HealthKit Info Section
    private var healthKitInfoSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(RTColor.caution)

                    Text("Why can't I see older data?")
                        .font(RTFont.headline)
                        .foregroundColor(RTColor.primaryText)
                }

                Text("HealthKit only stores data from when you first granted permission. Apple does not retroactively backfill historical health data when you install a new app.")
                    .font(RTFont.body)
                    .foregroundColor(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "checkmark.circle.fill", text: "Data from today forward is saved automatically")
                    InfoRow(icon: "checkmark.circle.fill", text: "Your data stays in Apple Health even if you delete this app")
                    InfoRow(icon: "xmark.circle.fill", text: "Past data before app install is not accessible via HealthKit")
                }

                Divider()
                    .background(RTColor.divider)

                Text("Tip: If you previously used another health app, that data may already exist in Apple Health and will appear here once you grant access.")
                    .font(RTFont.captionSmall)
                    .foregroundColor(RTColor.tertiaryText)
                    .italic()
            }
        }
    }

    // MARK: - Helpers
    private func metricValue(for data: DailyHealthData) -> Double {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen ?? 0
        }
    }

    private func formattedValue(_ value: Double) -> String {
        switch metric {
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories, .bloodOxygen:
            return "\(Int(value))"
        }
    }

    private var trendLabel: String {
        switch trend {
        case .up: return metric.higherIsBetter ? "Improving" : "Worsening"
        case .down: return metric.higherIsBetter ? "Declining" : "Improving"
        case .flat: return "Stable"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .up: return metric.higherIsBetter ? RTColor.optimal : RTColor.warning
        case .down: return metric.higherIsBetter ? RTColor.warning : RTColor.optimal
        case .flat: return RTColor.tertiaryText
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(RTFont.captionSmall)
                .foregroundColor(RTColor.secondaryText)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(RTColor.primaryText)

                Text(unit)
                    .font(RTFont.captionSmall)
                    .foregroundColor(RTColor.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(RTColor.surfaceElevated)
        )
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(icon.contains("xmark") ? RTColor.warning : RTColor.optimal)

            Text(text)
                .font(RTFont.caption)
                .foregroundColor(RTColor.secondaryText)

            Spacer()
        }
    }
}

// MARK: - Date Extension
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}

// MARK: - Metric Detail Helpers
extension MetricDetailView {
    private func correlationMetrics() -> (x: MetricType, y: MetricType) {
        switch metric {
        case .sleep:
            return (.sleep, .hrv)
        case .hrv:
            return (.hrv, .sleep)
        case .restingHR:
            return (.restingHR, .hrv)
        case .activeCalories:
            return (.activeCalories, .sleep)
        case .bloodOxygen:
            return (.bloodOxygen, .hrv)
        }
    }
}
