import SwiftUI
import Charts

/// Honest #497: interactive readiness load simulator + Fitbit air-data density.
/// Lets the user scrub sleep / HRV / strain deltas and see a projected READY score,
/// plus 1–3 concrete today tasks. Fitbit source shows which Google Health fields
/// arrived in today's "air" (live) payload.
struct ReadinessLoadSimulatorCard: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    let scores: DualReadinessScores
    let source: DataSource

    @State private var sleepDelta: Double = 0      // hours
    @State private var hrvDelta: Double = 0        // ms
    @State private var strainDelta: Double = 0     // strain points 0…21
    /// Honest #499: extra levers + checkable tasks.
    @State private var rhrDelta: Double = 0        // bpm (lower is better)
    @State private var spo2Delta: Double = 0       // percentage points
    @State private var completedTaskIDs: Set<String> = []

    private var baseline: Int { scores.general }

    /// Lightweight projection from ReadinessCalculator weights (25% sleep / 25% HRV / 15% strain).
    private var projected: Int {
        let sleepAdj = sleepDelta * 4.0          // ~4 pts per hour around typical night
        let hrvAdj = hrvDelta * 0.25             // ~0.25 pts per ms RMSSD
        let strainAdj = -strainDelta * (100.0 / 21.0) * 0.15
        let rhrAdj = -rhrDelta * 0.4             // lower RHR lifts READY
        let spo2Adj = spo2Delta * 1.5            // SpO2 points matter near edge
        return min(100, max(0, Int((Double(baseline) + sleepAdj + hrvAdj + strainAdj + rhrAdj + spo2Adj).rounded())))
    }

    private var deltaVsBaseline: Int { projected - baseline }

    private var zone: (label: String, color: Color) {
        switch projected {
        case 80...100: return ("Push", RTColor.optimal)
        case 65..<80: return ("Solid", RTColor.good)
        case 50..<65: return ("Easy", RTColor.caution)
        default: return ("Rest", RTColor.warning)
        }
    }

    private var tasks: [SimulatorTask] {
        SimulatorTask.generate(
            projected: projected,
            sleepDelta: sleepDelta,
            hrvDelta: hrvDelta,
            strainDelta: strainDelta,
            rhrDelta: rhrDelta,
            spo2Delta: spo2Delta,
            data: data,
            source: source
        )
    }

    private var fitbitAirChips: [FitbitAirChip] {
        guard source == .fitbit else { return [] }
        return FitbitAirChip.chips(from: data)
    }

    private let accent = Color(hex: "5E5CE6")

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                header
                projectionHero
                interactiveControls
                sparkProjection
                if !fitbitAirChips.isEmpty {
                    fitbitAirStrip
                }
                tasksBlock
            }
            .padding(16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.readinessLoadSimulatorCard)
        .accessibilityLabel("Readiness Load Simulator")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Load Simulator")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(source == .fitbit
                     ? "Fitbit air · scrub tonight’s levers"
                     : "Scrub sleep · HRV · strain")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer()
            Text(zone.label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(zone.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(zone.color.opacity(0.14))
                .clipShape(Capsule())
        }
    }

    private var projectionHero: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(RTColor.divider, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(projected) / 100)
                    .stroke(zone.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: projected)
                VStack(spacing: 2) {
                    Text("\(projected)")
                        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(RTColor.primaryText)
                        .contentTransition(.numericText())
                    Text("READY")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            .frame(width: 96, height: 96)
            .accessibilityIdentifier(SurfaceID.readinessLoadSimulatorGauge)

            VStack(alignment: .leading, spacing: 8) {
                labeledValue("Tonight", "\(baseline)", "baseline")
                labeledValue(
                    "Projected",
                    deltaVsBaseline >= 0 ? "+\(deltaVsBaseline)" : "\(deltaVsBaseline)",
                    "vs baseline"
                )
                Text(ReadinessCalculator.recommendation(for: projected))
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func labeledValue(_ title: String, _ value: String, _ caption: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(RTColor.primaryText)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
    }

    private var interactiveControls: some View {
        VStack(spacing: 14) {
            simulatorSlider(
                title: "Sleep",
                unit: "h",
                value: $sleepDelta,
                range: -2...2,
                step: 0.25,
                tint: RTColor.sleep
            )
            simulatorSlider(
                title: "HRV",
                unit: "ms",
                value: $hrvDelta,
                range: -20...20,
                step: 1,
                tint: RTColor.hrv
            )
            simulatorSlider(
                title: "Strain",
                unit: "pts",
                value: $strainDelta,
                range: -6...6,
                step: 0.5,
                tint: RTColor.strain
            )
            simulatorSlider(
                title: "RHR",
                unit: "bpm",
                value: $rhrDelta,
                range: -10...10,
                step: 1,
                tint: Color(hex: "FF375F")
            )
            simulatorSlider(
                title: "SpO₂",
                unit: "pp",
                value: $spo2Delta,
                range: -3...3,
                step: 0.5,
                tint: Color(hex: "64D2FF")
            )
        }
        .accessibilityIdentifier(SurfaceID.readinessLoadSimulatorControls)
    }

    private func simulatorSlider(
        title: String,
        unit: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Spacer()
                Text(String(format: "%@%.2g %@", value.wrappedValue >= 0 ? "+" : "", value.wrappedValue, unit))
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(tint)
            }
            Slider(value: value, in: range, step: step)
                .tint(tint)
        }
    }

    private var sparkProjection: some View {
        let points: [(label: String, value: Double)] = [
            ("−2h", Double(project(sleep: -2, hrv: 0, strain: 0, rhr: 0, spo2: 0))),
            ("Now", Double(baseline)),
            ("+1h", Double(project(sleep: 1, hrv: 0, strain: 0, rhr: 0, spo2: 0))),
            ("+HRV", Double(project(sleep: 0, hrv: 10, strain: 0, rhr: 0, spo2: 0))),
            ("−RHR", Double(project(sleep: 0, hrv: 0, strain: 0, rhr: -5, spo2: 0))),
            ("Scrub", Double(projected))
        ]
        return VStack(alignment: .leading, spacing: 6) {
            Text("Projection map")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            Chart(points, id: \.label) { pt in
                BarMark(
                    x: .value("Scenario", pt.label),
                    y: .value("Ready", pt.value)
                )
                .foregroundStyle(pt.label == "Scrub" ? accent : RTColor.surfaceHighlight)
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(RTColor.divider)
                    AxisValueLabel()
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            .frame(height: 110)
            .accessibilityIdentifier(SurfaceID.readinessLoadSimulatorSpark)
            .accessibilityLabel("Readiness projection map")
        }
    }

    private var fitbitAirStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fitbit air data")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(fitbitAirChips) { chip in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(chip.filled ? RTColor.optimal : RTColor.tertiaryText.opacity(0.35))
                                .frame(width: 7, height: 7)
                            Text(chip.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(chip.filled ? RTColor.primaryText : RTColor.secondaryText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RTColor.surfaceHighlight.opacity(chip.filled ? 1 : 0.5))
                        .clipShape(Capsule())
                    }
                }
            }
            .accessibilityIdentifier(SurfaceID.fitbitAirDataStrip)
            .accessibilityLabel("Fitbit air data fields")
        }
    }

    private var tasksBlock: some View {
        let done = tasks.filter { completedTaskIDs.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today’s tasks")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(done)/\(tasks.count)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskProgress)
            }
            ProgressView(value: Double(done), total: Double(max(1, tasks.count)))
                .tint(accent)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskProgressBar)
            ForEach(tasks) { task in
                let isDone = completedTaskIDs.contains(task.id)
                Button {
                    Haptic.selectionChanged()
                    if isDone { completedTaskIDs.remove(task.id) }
                    else { completedTaskIDs.insert(task.id) }
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isDone ? RTColor.optimal : accent)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)
                                .strikethrough(isDone, color: RTColor.secondaryText)
                            Text(task.detail)
                                .font(.caption)
                                .foregroundStyle(RTColor.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: task.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(accent.opacity(0.7))
                    }
                    .padding(10)
                    .background(RTColor.surfaceHighlight.opacity(isDone ? 0.35 : 0.65))
                    .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskRow)
                .accessibilityLabel("\(task.title)\(isDone ? ", done" : "")")
            }
        }
        .accessibilityIdentifier(SurfaceID.readinessSimulatorTasks)
    }

    private func project(sleep: Double, hrv: Double, strain: Double, rhr: Double, spo2: Double) -> Int {
        let sleepAdj = sleep * 4.0
        let hrvAdj = hrv * 0.25
        let strainAdj = -strain * (100.0 / 21.0) * 0.15
        let rhrAdj = -rhr * 0.4
        let spo2Adj = spo2 * 1.5
        return min(100, max(0, Int((Double(baseline) + sleepAdj + hrvAdj + strainAdj + rhrAdj + spo2Adj).rounded())))
    }
}

// MARK: - Tasks

struct SimulatorTask: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String

    static func generate(
        projected: Int,
        sleepDelta: Double,
        hrvDelta: Double,
        strainDelta: Double,
        rhrDelta: Double,
        spo2Delta: Double,
        data: DailyHealthData,
        source: DataSource
    ) -> [SimulatorTask] {
        var out: [SimulatorTask] = []
        if sleepDelta < 0.25 && data.sleepHours < 7 {
            out.append(.init(
                id: "sleep-protect",
                title: "Protect sleep window",
                detail: "Add ~\(String(format: "%.1f", max(0.5, 7 - data.sleepHours)))h tonight to lift projected READY.",
                icon: "moon.zzz.fill"
            ))
        } else if sleepDelta >= 0.5 {
            out.append(.init(
                id: "sleep-lock",
                title: "Lock the extra sleep",
                detail: "Keep the +\(String(format: "%.1f", sleepDelta))h scrub — wind-down 45m earlier.",
                icon: "bed.double.fill"
            ))
        }
        if strainDelta > 1 {
            out.append(.init(
                id: "strain-cap",
                title: "Cap today’s load",
                detail: "Scrubbed strain is up — bias to Zone 2 or cut a set.",
                icon: "flame.fill"
            ))
        } else if projected >= 80 {
            out.append(.init(
                id: "push-session",
                title: "Push the key session",
                detail: "Projected READY ≥80 — schedule the hard lift or intervals.",
                icon: "figure.strengthtraining.traditional"
            ))
        }
        if hrvDelta < -5 || data.hrv < 40 {
            out.append(.init(
                id: "hrv-break",
                title: "HRV coherence break",
                detail: "2–5 min box breathing before noon to support HRV.",
                icon: "wind"
            ))
        }
        if rhrDelta > 3 || data.restingHeartRate > 65 {
            out.append(.init(
                id: "rhr-ease",
                title: "Ease into the day",
                detail: "RHR scrub is elevated — delay hard work until after a walk.",
                icon: "heart.fill"
            ))
        }
        if spo2Delta < -1 || (data.bloodOxygen ?? 100) < 95 {
            out.append(.init(
                id: "spo2-air",
                title: "Check air / SpO₂",
                detail: "SpO₂ scrub soft — open a window, nasal breathe, recheck.",
                icon: "lungs.fill"
            ))
        }
        if source == .fitbit && out.count < 2 {
            out.append(.init(
                id: "fitbit-sync",
                title: "Confirm Fitbit sync",
                detail: "Pull-to-refresh so Google Health air fields stay current.",
                icon: "arrow.triangle.2.circlepath"
            ))
        }
        if out.isEmpty {
            out.append(.init(
                id: "hold-line",
                title: "Hold the line",
                detail: "Scrubs look balanced — keep today’s plan and recheck after lunch.",
                icon: "checkmark.circle.fill"
            ))
        }
        return Array(out.prefix(4))
    }
}

// MARK: - Fitbit air chips

struct FitbitAirChip: Identifiable {
    let id = UUID()
    let label: String
    let filled: Bool

    static func chips(from data: DailyHealthData) -> [FitbitAirChip] {
        [
            .init(label: "Sleep", filled: data.sleepHours > 0),
            .init(label: "HRV", filled: data.hrv > 0),
            .init(label: "RHR", filled: data.restingHeartRate > 0),
            .init(label: "SpO₂", filled: (data.bloodOxygen ?? 0) > 0),
            .init(label: "Resp", filled: (data.respiratoryRate ?? 0) > 0),
            .init(label: "Skin °C", filled: data.skinTemperature != nil),
            .init(label: "Steps", filled: data.steps > 0),
            .init(label: "Active kcal", filled: data.activeCalories > 0),
            .init(label: "Distance", filled: (data.distanceWalkingRunningKm ?? 0) > 0),
            .init(label: "Floors", filled: (data.flightsClimbed ?? 0) > 0),
            .init(label: "Active min", filled: (data.appleExerciseTimeMinutes ?? 0) > 0),
            .init(label: "Basal", filled: (data.basalEnergyKcal ?? 0) > 0)
        ]
    }
}
