import SwiftUI

/// Gym / Work / Sleep ring identity for Apple Fitness–style focused detail.
enum RingKind: String, Identifiable, CaseIterable {
    case gym
    case work
    case sleep

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gym: return "Gym"
        case .work: return "Work"
        case .sleep: return "Sleep"
        }
    }

    var color: Color {
        switch self {
        case .gym: return RTColor.strain
        case .work: return RTColor.hrv
        case .sleep: return RTColor.sleep
        }
    }

    var icon: String {
        switch self {
        case .gym: return "dumbbell.fill"
        case .work: return "brain.head.profile"
        case .sleep: return "bed.double.fill"
        }
    }

    /// Short caption for the metric sparkline (existing DailyHealthData fields).
    var metricCaption: String {
        switch self {
        case .gym: return "Workout minutes"
        case .work: return "HRV (ms)"
        case .sleep: return "Sleep hours"
        }
    }

    var accessibilityIdentifier: String {
        "ring.legend.\(rawValue)"
    }

    func score(from scores: DualReadinessScores) -> Int {
        switch self {
        case .gym: return scores.gym
        case .work: return scores.cognitive
        case .sleep: return scores.breakdown.sleepScore
        }
    }

    /// Last up-to-7 days, chronological (oldest → newest) from ascending history.
    func series(from history: [DailyHealthData]) -> [Double] {
        let window = Array(history.suffix(7))
        switch self {
        case .gym: return window.map { Double($0.workoutMinutes) }
        case .work: return window.map { $0.hrv }
        case .sleep: return window.map { $0.sleepHours }
        }
    }
}

struct TripleRingHero: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    let size: CGFloat

    /// Activity-like stroke (~1/10 diameter) and tight inter-ring gap.
    /// #15 locked the concentric diameters: size, size-2*(lw+gap), size-4*(lw+gap).
    /// Center score is overlay-only — it never drove radius. We pack rings tighter
    /// toward Fitness Summary and shrink typography so READY still fits in the hole.
    private var lineWidth: CGFloat { max(12, size / 10) }
    private let gap: CGFloat = 2

    private var holeDiameter: CGFloat {
        size - 4 * (lineWidth + gap) - lineWidth
    }

    private var scoreFontSize: CGFloat {
        // Score + READY caption + small padding inside the hole
        min(34, max(22, holeDiameter * 0.30))
    }

    var body: some View {
        let middle = size - 2 * (lineWidth + gap)
        let inner = size - 4 * (lineWidth + gap)
        ZStack {
            ActivityRing(
                progress: Double(sleepScore) / 100,
                color: RTColor.sleep,
                lineWidth: lineWidth,
                size: size
            )
            ActivityRing(
                progress: Double(workScore) / 100,
                color: RTColor.hrv,
                lineWidth: lineWidth,
                size: middle
            )
            ActivityRing(
                progress: Double(gymScore) / 100,
                color: RTColor.strain,
                lineWidth: lineWidth,
                size: inner
            )
            VStack(spacing: 1) {
                Text("\(overallScore)")
                    .font(.system(size: scoreFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(RTColor.primaryText)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Text("READY")
                    .font(.system(size: max(8, scoreFontSize * 0.28), weight: .semibold))
                    .foregroundColor(RTColor.secondaryText)
                    .tracking(1.5)
            }
            .frame(width: holeDiameter * 0.85)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Readiness score")
        .accessibilityValue("\(overallScore) out of 100. Sleep \(sleepScore), work \(workScore), gym \(gymScore)")
        .accessibilityAddTraits(.isSummaryElement)
        .accessibilityIdentifier("today.rings")
    }

    private var overallScore: Int {
        Int((Double(gymScore) + Double(workScore) + Double(sleepScore)) / 3.0)
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress ring")
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent")
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = newValue
            }
        }
    }
}

struct RingLegend: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    var onSelect: ((RingKind) -> Void)? = nil

    var body: some View {
        HStack(spacing: 20) {
            LegendItem(
                kind: .gym,
                score: gymScore,
                onSelect: onSelect
            )
            LegendItem(
                kind: .work,
                score: workScore,
                onSelect: onSelect
            )
            LegendItem(
                kind: .sleep,
                score: sleepScore,
                onSelect: onSelect
            )
        }
    }
}

struct LegendItem: View {
    let kind: RingKind
    let score: Int
    var onSelect: ((RingKind) -> Void)? = nil

    var body: some View {
        Group {
            if let onSelect {
                Button {
                    Haptic.tap()
                    onSelect(kind)
                } label: {
                    legendContent
                }
                .buttonStyle(.plain)
            } else {
                legendContent
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.label) score \(score)")
        .accessibilityAddTraits(onSelect == nil ? AccessibilityTraits() : .isButton)
        .accessibilityIdentifier(kind.accessibilityIdentifier)
    }

    private var legendContent: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: kind.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(kind.color)
                Text(kind.label)
                    .font(.caption.weight(.medium))
                    .foregroundColor(RTColor.secondaryText)
            }
            Text("\(score)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(RTColor.primaryText)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

/// Apple Fitness–style focused ring detail: score, label/color, 7-day sparkline.
struct RingDetailView: View {
    let kind: RingKind
    let score: Int
    let history: [DailyHealthData]

    @Environment(\.dismiss) private var dismiss

    private var series: [Double] { kind.series(from: history) }

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
                        Text("\(score)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(kind.color)
                            .accessibilityIdentifier("ring.detail.score")
                        Text("\(score)% today")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    .padding(.top, 8)

                    ActivityRing(
                        progress: Double(score) / 100,
                        color: kind.color,
                        lineWidth: 18,
                        size: 160
                    )
                    .accessibilityIdentifier("ring.detail.ring")

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
                                .accessibilityIdentifier("ring.detail.sparkline")

                            RingMiniBarChart(values: series, color: kind.color)
                                .frame(height: 72)
                                .accessibilityIdentifier("ring.detail.bars")
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
            .accessibilityIdentifier("ring.detail")
        }
    }
}

/// Compact 7-day mini bars for ring detail (Fitness-style companion to the sparkline).
private struct RingMiniBarChart: View {
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
                    .frame(height: max(4, CGFloat(value / maxValue) * 64))
            }
        }
        .accessibilityHidden(true)
    }
}
