import SwiftUI
import Charts

/// Full-screen trend detail — tapped from Dashboard trend section.
/// Shows all metrics overlaid with full controls and statistics.
struct TrendDetailView: View {
    let history: [DailyHealthData]
    
    @State private var selectedPeriod: TrendPeriod = .week
    @State private var selectedMetrics: Set<MetricToggle> = [.readiness, .sleep, .hrv]
    /// Readiness scores precomputed once per history change — avoids O(n²) recalculation per chart point.
    @State private var readinessScores: [UUID: Int] = [:]
    
    @Environment(\.dismiss) private var dismiss
    
    enum MetricToggle: String, CaseIterable, Identifiable {
        case readiness = "Readiness"
        case sleep = "Sleep"
        case hrv = "HRV"
        case rhr = "Resting HR"
        case calories = "Calories"
        
        var id: String { rawValue }
        
        var color: Color {
            switch self {
            case .readiness: return RTColor.optimal
            case .sleep: return RTColor.sleep
            case .hrv: return RTColor.hrv
            case .rhr: return RTColor.strain
            case .calories: return RTColor.caution
            }
        }
        
        var icon: String {
            switch self {
            case .readiness: return "gauge.with.dots.needle.67percent"
            case .sleep: return "bed.double.fill"
            case .hrv: return "waveform.path.ecg"
            case .rhr: return "heart.fill"
            case .calories: return "flame.fill"
            }
        }
    }
    
    var filteredHistory: [DailyHealthData] {
        let days = selectedPeriod.rawValue
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return history
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }
    
    private func readinessScore(for day: DailyHealthData) -> Int {
        ReadinessCalculator.calculateBreakdown(from: day, history: history).totalScore
    }
    
    private func precomputeReadinessScores() {
        readinessScores = Dictionary(uniqueKeysWithValues: history.map { ($0.id, readinessScore(for: $0)) })
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                // Period selector
                periodSelector
                    .slideIn(delay: 0)
                
                // Metric toggles
                metricToggles
                    .slideIn(delay: 0.05)
                
                // Main multi-metric chart
                mainChart
                    .slideIn(delay: 0.1)

                // Depth timeline for primary metric
                depthTimelineSection
                    .slideIn(delay: 0.12)
                
                // Individual metric cards
                metricCards
                    .slideIn(delay: 0.15)
                
                // Correlation matrix
                if filteredHistory.count >= 5 {
                    correlationSection
                        .slideIn(delay: 0.2)
                }
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .onAppear { precomputeReadinessScores() }
        .onChange(of: history) { _ in precomputeReadinessScores() }
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        NativePeriodSelector(selectedPeriod: $selectedPeriod)
    }
    
    // MARK: - Metric Toggles
    private var metricToggles: some View {
        FlowLayout(spacing: 8) {
            ForEach(MetricToggle.allCases) { metric in
                Button {
                    Haptic.selectionChanged()
                    if selectedMetrics.contains(metric) {
                        if selectedMetrics.count > 1 {
                            selectedMetrics.remove(metric)
                        }
                    } else {
                        selectedMetrics.insert(metric)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 12))
                        Text(metric.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(selectedMetrics.contains(metric) ? .white : RTColor.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedMetrics.contains(metric) ? metric.color : RTColor.surface)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Main Chart
    private var mainChart: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Multi-Metric Trend")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                if filteredHistory.count >= 2 {
                    Chart(filteredHistory) { day in
                        if selectedMetrics.contains(.readiness) {
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Readiness", readinessScores[day.id] ?? 0)
                            )
                            .foregroundStyle(MetricToggle.readiness.color)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        
                        if selectedMetrics.contains(.sleep) {
                            let sleepNormalized = min(100, day.sleepHours * 12.5)
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Sleep", sleepNormalized)
                            )
                            .foregroundStyle(MetricToggle.sleep.color.opacity(0.7))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        }
                        
                        if selectedMetrics.contains(.hrv) {
                            let hrvNormalized = min(100, Double(day.hrv) * 2)
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("HRV", hrvNormalized)
                            )
                            .foregroundStyle(MetricToggle.hrv.color.opacity(0.7))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [2, 2]))
                        }
                        
                        if selectedMetrics.contains(.rhr) {
                            let rhrNormalized = max(0, 100 - Double(day.restingHeartRate - 40) * 2)
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("RHR", rhrNormalized)
                            )
                            .foregroundStyle(MetricToggle.rhr.color.opacity(0.7))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
                        }
                        
                        if selectedMetrics.contains(.calories) {
                            let calNormalized = min(100, day.activeCalories / 15)
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Calories", calNormalized)
                            )
                            .foregroundStyle(MetricToggle.calories.color.opacity(0.7))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [1, 3]))
                        }
                    }
                    .frame(height: 260)
                    .chartYScale(domain: 0...100)
                    
                    // Legend
                    HStack(spacing: 12) {
                        ForEach(Array(selectedMetrics.sorted { $0.rawValue < $1.rawValue }), id: \.self) { metric in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(metric.color)
                                    .frame(width: 8, height: 8)
                                Text(metric.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(RTColor.secondaryText)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(RTColor.surfaceHighlight)

                        Text("Not Enough Data")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)

                        Text("Need at least 2 days of data in this period to show trends")
                            .font(.caption)
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Depth Timeline
    private var primaryDepthMetric: MetricToggle {
        // Prefer readiness when selected; otherwise first selected toggle.
        if selectedMetrics.contains(.readiness) { return .readiness }
        return MetricToggle.allCases.first { selectedMetrics.contains($0) } ?? .readiness
    }

    private var depthTimelinePoints: [(date: Date, value: Double)] {
        switch primaryDepthMetric {
        case .readiness:
            return filteredHistory.map { ($0.date, Double(readinessScores[$0.id] ?? 0)) }
        case .sleep:
            return filteredHistory.map { ($0.date, $0.sleepHours) }
        case .hrv:
            return filteredHistory.map { ($0.date, Double($0.hrv)) }
        case .rhr:
            return filteredHistory.map { ($0.date, Double($0.restingHeartRate)) }
        case .calories:
            return filteredHistory.map { ($0.date, $0.activeCalories) }
        }
    }

    private var depthTimelineUnit: String {
        switch primaryDepthMetric {
        case .readiness: return "%"
        case .sleep: return "h"
        case .hrv: return "ms"
        case .rhr: return "bpm"
        case .calories: return "kcal"
        }
    }

    private var depthTimelineSection: some View {
        NativeCard {
            DepthTimelineChart(
                title: "\(primaryDepthMetric.rawValue) Depth Timeline",
                unit: depthTimelineUnit,
                color: primaryDepthMetric.color,
                points: depthTimelinePoints,
                period: selectedPeriod
            )
        }
    }

    // MARK: - Metric Cards
    private var metricCards: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            AppSectionHeader(title: "Metric Stats")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                if selectedMetrics.contains(.readiness) {
                    let scores = filteredHistory.map { readinessScores[$0.id] ?? 0 }
                    TrendStatCard(
                        icon: "gauge.with.dots.needle.67percent",
                        label: "Readiness",
                        color: RTColor.optimal,
                        current: Double(scores.last ?? 0),
                        avg: scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count),
                        best: Double(scores.max() ?? 0),
                        unit: ""
                    )
                }
                
                if selectedMetrics.contains(.sleep) {
                    TrendStatCard(
                        icon: "bed.double.fill",
                        label: "Sleep",
                        color: RTColor.sleep,
                        current: filteredHistory.last?.sleepHours ?? 0,
                        avg: filteredHistory.isEmpty ? 0 : filteredHistory.map { $0.sleepHours }.reduce(0, +) / Double(filteredHistory.count),
                        best: filteredHistory.map { $0.sleepHours }.max() ?? 0,
                        unit: "h"
                    )
                }
                
                if selectedMetrics.contains(.hrv) {
                    TrendStatCard(
                        icon: "waveform.path.ecg",
                        label: "HRV",
                        color: RTColor.hrv,
                        current: Double(filteredHistory.last?.hrv ?? 0),
                        avg: filteredHistory.isEmpty ? 0 : Double(filteredHistory.map { $0.hrv }.reduce(0, +)) / Double(filteredHistory.count),
                        best: Double(filteredHistory.map { $0.hrv }.max() ?? 0),
                        unit: "ms"
                    )
                }
                
                if selectedMetrics.contains(.rhr) {
                    TrendStatCard(
                        icon: "heart.fill",
                        label: "Resting HR",
                        color: RTColor.strain,
                        current: Double(filteredHistory.last?.restingHeartRate ?? 0),
                        avg: filteredHistory.isEmpty ? 0 : Double(filteredHistory.map { $0.restingHeartRate }.reduce(0, +)) / Double(filteredHistory.count),
                        best: Double(filteredHistory.map { $0.restingHeartRate }.min() ?? 0),
                        unit: "bpm"
                    )
                }
                
                if selectedMetrics.contains(.calories) {
                    TrendStatCard(
                        icon: "flame.fill",
                        label: "Active Cals",
                        color: RTColor.caution,
                        current: Double(filteredHistory.last?.activeCalories ?? 0),
                        avg: filteredHistory.isEmpty ? 0 : filteredHistory.map { $0.activeCalories }.reduce(0, +) / Double(filteredHistory.count),
                        best: filteredHistory.map { $0.activeCalories }.max() ?? 0,
                        unit: "cal"
                    )
                }
            }
        }
    }
    
    // MARK: - Correlation Section
    private var correlationSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep vs Recovery")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                Chart(filteredHistory) { day in
                    PointMark(
                        x: .value("Sleep", day.sleepHours),
                        y: .value("Readiness", readinessScores[day.id] ?? 0)
                    )
                    .foregroundStyle(RTColor.optimal.opacity(0.7))
                    .symbolSize(60)
                    
                    // Trend line approximation
                    let avgReadiness = filteredHistory.map { readinessScores[$0.id] ?? 0 }.reduce(0, +) / filteredHistory.count
                    RuleMark(y: .value("Avg", avgReadiness))
                        .foregroundStyle(RTColor.primaryText.opacity(0.12))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .frame(height: 200)
                
                HStack {
                    Text("Sleep (hours)")
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Trend Stat Card
private struct TrendStatCard: View {
    let icon: String
    let label: String
    let color: Color
    let current: Double
    let avg: Double
    let best: Double
    let unit: String
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(color)
                    Text(label)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(formatted(current))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(RTColor.primaryText)
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Avg")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Text(formatted(avg))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                        Text(formatted(best))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color)
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func formatted(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Trend Period Label
extension TrendPeriod {
    var detailLabel: String {
        switch self {
        case .week: return "7D"
        case .month: return "30D"
        case .quarter: return "90D"
        case .year: return "1Y"
        }
    }
}