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
    /// Honest #508: which projected ring chip is focused.
    @State private var focusedRing: SimRingKind = .ready
    /// Honest #516: which lever contribution chip is focused.
    @State private var focusedLever: SimLeverKind? = nil
    /// Honest #518: banner after seeding levers from today air vs 7d mean.
    @State private var airSeededSummary: String? = nil

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

    /// Honest #508: projected Gym / Work / Sleep chips that track lever scrubs.
    private var projectedGym: Int {
        let strainAdj = -strainDelta * (100.0 / 21.0) * 0.2
        let rhrAdj = -rhrDelta * 0.5
        return min(100, max(0, Int((Double(scores.gym) + strainAdj + rhrAdj).rounded())))
    }
    private var projectedWork: Int {
        let hrvAdj = hrvDelta * 0.3
        let sleepAdj = sleepDelta * 2.0
        return min(100, max(0, Int((Double(scores.cognitive) + hrvAdj + sleepAdj).rounded())))
    }
    private var projectedSleep: Int {
        let sleepAdj = sleepDelta * 5.0
        let spo2Adj = spo2Delta * 1.0
        return min(100, max(0, Int((Double(scores.breakdown.sleepScore) + sleepAdj + spo2Adj).rounded())))
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
                simulatorPresets
                seedAirBlock
                projectionHero
                leverDeltaChips
                projectedRingChips
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

    /// Honest #511: gauge tints + shows focused ring (READY/Gym/Work/Sleep).
    private var focusedRingValue: Int {
        switch focusedRing {
        case .ready: return projected
        case .gym: return projectedGym
        case .work: return projectedWork
        case .sleep: return projectedSleep
        }
    }

    private var projectionHero: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(RTColor.divider, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(focusedRingValue) / 100)
                    .stroke(focusedRing.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.25), value: focusedRingValue)
                    .animation(.easeInOut(duration: 0.25), value: focusedRing)
                VStack(spacing: 2) {
                    Text("\(focusedRingValue)")
                        .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(RTColor.primaryText)
                        .contentTransition(.numericText())
                    Text(focusedRing.title.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(focusedRing.color)
                }
                // Keep legacy gauge SurfaceID while #511 tint id rides on the stack
                Color.clear.frame(width: 1, height: 1)
                    .accessibilityIdentifier(SurfaceID.readinessLoadSimulatorGauge)
            }
            .frame(width: 96, height: 96)
            .accessibilityIdentifier(SurfaceID.readinessSimulatorRingTint)
            .accessibilityLabel("Projected \(focusedRing.title) \(focusedRingValue)")

            VStack(alignment: .leading, spacing: 8) {
                labeledValue("Tonight", "\(baseline)", "baseline")
                labeledValue(
                    "Projected",
                    deltaVsBaseline >= 0 ? "+\(deltaVsBaseline)" : "\(deltaVsBaseline)",
                    "vs baseline"
                )
                Text(focusedRing == .ready
                     ? ReadinessCalculator.recommendation(for: projected)
                     : focusedRing.caption(gym: projectedGym, work: projectedWork, sleep: projectedSleep, ready: projected))
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

    /// Honest #516: per-lever READY contribution chips (interactive).
    private var leverDeltaChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lever deltas")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text(deltaVsBaseline >= 0 ? "Σ +\(deltaVsBaseline)" : "Σ \(deltaVsBaseline)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(deltaVsBaseline >= 0 ? RTColor.optimal : Color(hex: "FF375F"))
            }
            HStack(spacing: 8) {
                ForEach(SimLeverKind.allCases) { lever in
                    leverDeltaChip(lever)
                }
            }
            if let focusedLever {
                Text(focusedLever.hint)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier(SurfaceID.readinessSimulatorLeverDeltas)
        .accessibilityLabel("Lever deltas")
    }

    private func leverDeltaChip(_ lever: SimLeverKind) -> some View {
        let value = lever.contribution(sleep: sleepDelta, hrv: hrvDelta, strain: strainDelta, rhr: rhrDelta, spo2: spo2Delta)
        let active = focusedLever == lever
        let label = value >= 0 ? String(format: "+%.1f", value) : String(format: "%.1f", value)
        return Button {
            Haptic.selectionChanged()
            focusedLever = focusedLever == lever ? nil : lever
        } label: {
            VStack(spacing: 3) {
                Image(systemName: lever.icon)
                    .font(.caption2.weight(.bold))
                Text(lever.title)
                    .font(.caption2.weight(.bold))
                Text(label)
                    .font(.caption.weight(.bold).monospacedDigit())
            }
            .foregroundStyle(active ? Color.white : lever.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? lever.color : lever.color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lever.title) \(label)")
    }

    /// Honest #504: scenario presets + reset for richer simulation.
    private var simulatorPresets: some View {
        HStack(spacing: 8) {
            ForEach(SimulatorPreset.allCases) { preset in
                Button {
                    Haptic.selectionChanged()
                    apply(preset)
                } label: {
                    Text(preset.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(preset == .reset ? RTColor.secondaryText : Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(preset == .reset ? RTColor.surfaceHighlight : accent.opacity(0.85))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityIdentifier(SurfaceID.readinessSimulatorPresets)
    }

    private func apply(_ preset: SimulatorPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            sleepDelta = preset.sleep
            hrvDelta = preset.hrv
            strainDelta = preset.strain
            rhrDelta = preset.rhr
            spo2Delta = preset.spo2
            if preset == .reset {
                completedTaskIDs.removeAll()
                airSeededSummary = nil
            }
        }
    }

    /// Honest #518: denser Fitbit/Health air → simulator integration.
    private var seedAirBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Haptic.selectionChanged()
                seedFromAir()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wind")
                        .font(.caption.weight(.bold))
                    Text(source == .fitbit ? "Seed from Fitbit air" : "Seed from Health air")
                        .font(.caption.weight(.bold))
                    Spacer()
                    Text("7d Δ")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [accent, Color(hex: "64D2FF")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(SurfaceID.readinessSimulatorSeedAir)
            .accessibilityLabel("Seed simulator from air data")

            if let airSeededSummary {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(RTColor.optimal)
                    Text(airSeededSummary)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                        .lineLimit(2)
                }
                .accessibilityLabel(airSeededSummary)
            }
        }
    }

    private func seedFromAir() {
        let window = Array(history.suffix(7))
        func mean(_ values: [Double]) -> Double {
            guard !values.isEmpty else { return 0 }
            return values.reduce(0, +) / Double(values.count)
        }
        let avgSleep = mean(window.map(\.sleepHours))
        let avgHrv = mean(window.map(\.hrv))
        let avgRhr = mean(window.map(\.restingHeartRate))
        let spo2Vals = window.compactMap { $0.bloodOxygen }.filter { $0 > 0 }
        let avgSpo2 = mean(spo2Vals)
        let avgWO = mean(window.map { Double($0.workoutMinutes) })
        let spo2Now = data.bloodOxygen ?? avgSpo2

        func clamp(_ v: Double, _ r: ClosedRange<Double>) -> Double {
            min(r.upperBound, max(r.lowerBound, v))
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            sleepDelta = clamp(data.sleepHours - avgSleep, -2...2)
            hrvDelta = clamp(data.hrv - avgHrv, -20...20)
            strainDelta = clamp((Double(data.workoutMinutes) - avgWO) / 20.0, -6...6)
            rhrDelta = clamp(data.restingHeartRate - avgRhr, -10...10)
            spo2Delta = clamp(spo2Now - (avgSpo2 == 0 ? spo2Now : avgSpo2), -3...3)
            focusedLever = nil
            let bits = [
                String(format: "Sleep %+.1fh", sleepDelta),
                String(format: "HRV %+.0f", hrvDelta),
                String(format: "RHR %+.0f", rhrDelta)
            ]
            airSeededSummary = "Seeded from air · " + bits.joined(separator: " · ")
        }
    }

    private var projectedRingChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(SimRingKind.allCases) { kind in
                    let value: Int = {
                        switch kind {
                        case .ready: return projected
                        case .gym: return projectedGym
                        case .work: return projectedWork
                        case .sleep: return projectedSleep
                        }
                    }()
                    Button {
                        Haptic.selectionChanged()
                        focusedRing = kind
                    } label: {
                        VStack(spacing: 4) {
                            Text(kind.title)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(focusedRing == kind ? Color.white : RTColor.secondaryText)
                            Text("\(value)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(focusedRing == kind ? Color.white : kind.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(focusedRing == kind ? kind.color : kind.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(kind.title) \(value)")
                }
            }
            Text(focusedRing.caption(gym: projectedGym, work: projectedWork, sleep: projectedSleep, ready: projected))
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
        }
        .accessibilityIdentifier(SurfaceID.readinessSimulatorRings)
        .accessibilityLabel("Projected ring chips")
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

    /// Honest #512: projection map bars tint to focused ring.
    private var sparkProjection: some View {
        let scrubValue = Double(focusedRingValue)
        let points: [(label: String, value: Double)] = [
            ("−2h", Double(project(sleep: -2, hrv: 0, strain: 0, rhr: 0, spo2: 0))),
            ("Now", Double(baseline)),
            ("+1h", Double(project(sleep: 1, hrv: 0, strain: 0, rhr: 0, spo2: 0))),
            ("+HRV", Double(project(sleep: 0, hrv: 10, strain: 0, rhr: 0, spo2: 0))),
            ("−RHR", Double(project(sleep: 0, hrv: 0, strain: 0, rhr: -5, spo2: 0))),
            ("Scrub", scrubValue)
        ]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Projection map · \(focusedRing.title)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Circle()
                    .fill(focusedRing.color)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
            .accessibilityIdentifier(SurfaceID.readinessSimulatorSparkTint)
            .accessibilityLabel("Projection map tint \(focusedRing.title)")
            Chart(points, id: \.label) { pt in
                BarMark(
                    x: .value("Scenario", pt.label),
                    y: .value(focusedRing.title, pt.value)
                )
                .foregroundStyle(pt.label == "Scrub" ? focusedRing.color : focusedRing.color.opacity(0.28))
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
            .animation(.easeInOut(duration: 0.25), value: focusedRing)
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
        let lift = tasks.filter { completedTaskIDs.contains($0.id) }.map(\.readyDelta).reduce(0, +)
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
            // Honest #515: cumulative READY impact from checked tasks
            HStack(spacing: 8) {
                Text("READY lift")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text(lift == 0 ? "Tap tasks" : "+\(lift)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(lift > 0 ? RTColor.optimal : accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((lift > 0 ? RTColor.optimal : accent).opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskImpact)
                    .accessibilityLabel("READY lift +\(lift)")
            }
            .accessibilityElement(children: .contain)
            ProgressView(value: Double(done), total: Double(max(1, tasks.count)))
                .tint(accent)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskProgressBar)
            ForEach(tasks) { task in
                taskImpactRow(task)
            }
        }
        .accessibilityIdentifier(SurfaceID.readinessSimulatorTasks)
    }

    private func taskImpactRow(_ task: SimulatorTask) -> some View {
        let isDone = completedTaskIDs.contains(task.id)
        return Button {
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
                VStack(spacing: 4) {
                    Text("+\(task.readyDelta)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(isDone ? Color.white : accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(isDone ? RTColor.optimal : accent.opacity(0.12))
                        .clipShape(Capsule())
                    Image(systemName: task.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.7))
                }
            }
            .padding(10)
            .background(RTColor.surfaceHighlight.opacity(isDone ? 0.35 : 0.65))
            .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskRow)
        .accessibilityLabel("\(task.title), +\(task.readyDelta) READY\(isDone ? ", done" : "")")
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


// MARK: - Lever kinds (Honest #516)

enum SimLeverKind: String, CaseIterable, Identifiable {
    case sleep, hrv, strain, rhr, spo2
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sleep: return "Sleep"
        case .hrv: return "HRV"
        case .strain: return "Strain"
        case .rhr: return "RHR"
        case .spo2: return "SpO₂"
        }
    }
    var icon: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .hrv: return "waveform.path.ecg"
        case .strain: return "flame.fill"
        case .rhr: return "heart.fill"
        case .spo2: return "lungs.fill"
        }
    }
    var color: Color {
        switch self {
        case .sleep: return Color(hex: "5E5CE6")
        case .hrv: return Color(hex: "30D158")
        case .strain: return Color(hex: "FF9F0A")
        case .rhr: return Color(hex: "FF375F")
        case .spo2: return Color(hex: "64D2FF")
        }
    }
    var hint: String {
        switch self {
        case .sleep: return "Sleep scrub · ~4 READY per hour."
        case .hrv: return "HRV scrub · ~0.25 READY per ms."
        case .strain: return "Strain scrub · load tax on READY."
        case .rhr: return "RHR scrub · elevated resting rate softens READY."
        case .spo2: return "SpO₂ scrub · saturation support for READY."
        }
    }
    func contribution(sleep: Double, hrv: Double, strain: Double, rhr: Double, spo2: Double) -> Double {
        switch self {
        case .sleep: return sleep * 4.0
        case .hrv: return hrv * 0.25
        case .strain: return -strain * (100.0 / 21.0) * 0.15
        case .rhr: return -rhr * 0.4
        case .spo2: return spo2 * 1.5
        }
    }
}

// MARK: - Presets (Honest #504)


// MARK: - Projected ring focus (Honest #508)

enum SimRingKind: String, CaseIterable, Identifiable {
    case ready, gym, work, sleep
    var id: String { rawValue }
    var title: String {
        switch self {
        case .ready: return "READY"
        case .gym: return "Gym"
        case .work: return "Work"
        case .sleep: return "Sleep"
        }
    }
    var color: Color {
        switch self {
        case .ready: return Color(hex: "5E5CE6")
        case .gym: return Color(red: 255/255, green: 59/255, blue: 48/255)
        case .work: return Color(red: 52/255, green: 199/255, blue: 89/255)
        case .sleep: return Color(red: 88/255, green: 86/255, blue: 214/255)
        }
    }
    func caption(gym: Int, work: Int, sleep: Int, ready: Int) -> String {
        switch self {
        case .ready: return "Projected READY \(ready) · rings update as you scrub levers"
        case .gym: return "Gym \(gym) · strain & RHR scrubs weigh here"
        case .work: return "Work \(work) · HRV & sleep scrubs weigh here"
        case .sleep: return "Sleep \(sleep) · sleep hours & SpO₂ scrubs weigh here"
        }
    }
}

enum SimulatorPreset: String, CaseIterable, Identifiable {
    case rest, easy, push, reset
    var id: String { rawValue }
    var title: String {
        switch self {
        case .rest: return "Rest"
        case .easy: return "Easy"
        case .push: return "Push"
        case .reset: return "Reset"
        }
    }
    var sleep: Double {
        switch self { case .rest: return 1.0; case .easy: return 0.5; case .push: return -0.5; case .reset: return 0 }
    }
    var hrv: Double {
        switch self { case .rest: return 8; case .easy: return 3; case .push: return -8; case .reset: return 0 }
    }
    var strain: Double {
        switch self { case .rest: return -3; case .easy: return -1; case .push: return 4; case .reset: return 0 }
    }
    var rhr: Double {
        switch self { case .rest: return -4; case .easy: return -1; case .push: return 4; case .reset: return 0 }
    }
    var spo2: Double {
        switch self { case .rest: return 1; case .easy: return 0.5; case .push: return -1; case .reset: return 0 }
    }
}

// MARK: - Tasks

struct SimulatorTask: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    /// Honest #515: estimated READY lift when checked.
    let readyDelta: Int

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
                icon: "moon.zzz.fill",
                    readyDelta: 4
            ))
        } else if sleepDelta >= 0.5 {
            out.append(.init(
                id: "sleep-lock",
                title: "Lock the extra sleep",
                detail: "Keep the +\(String(format: "%.1f", sleepDelta))h scrub — wind-down 45m earlier.",
                icon: "bed.double.fill",
                    readyDelta: 2
            ))
        }
        if strainDelta > 1 {
            out.append(.init(
                id: "strain-cap",
                title: "Cap today’s load",
                detail: "Scrubbed strain is up — bias to Zone 2 or cut a set.",
                icon: "flame.fill",
                    readyDelta: 3
            ))
        } else if projected >= 80 {
            out.append(.init(
                id: "push-session",
                title: "Push the key session",
                detail: "Projected READY ≥80 — schedule the hard lift or intervals.",
                icon: "figure.strengthtraining.traditional",
                    readyDelta: 2
            ))
        }
        if hrvDelta < -5 || data.hrv < 40 {
            out.append(.init(
                id: "hrv-break",
                title: "HRV coherence break",
                detail: "2–5 min box breathing before noon to support HRV.",
                icon: "wind",
                    readyDelta: 3
            ))
        }
        if rhrDelta > 3 || data.restingHeartRate > 65 {
            out.append(.init(
                id: "rhr-ease",
                title: "Ease into the day",
                detail: "RHR scrub is elevated — delay hard work until after a walk.",
                icon: "heart.fill",
                    readyDelta: 2
            ))
        }
        if spo2Delta < -1 || (data.bloodOxygen ?? 100) < 95 {
            out.append(.init(
                id: "spo2-air",
                title: "Check air / SpO₂",
                detail: "SpO₂ scrub soft — open a window, nasal breathe, recheck.",
                icon: "lungs.fill",
                    readyDelta: 2
            ))
        }
        if source == .fitbit {
            if data.hrv <= 0 {
                out.append(.init(
                    id: "fitbit-hrv-air",
                    title: "Fill HRV air gap",
                    detail: "Google Health has no HRV yet — wear overnight and sync Fitbit.",
                    icon: "waveform.path.ecg",
                        readyDelta: 3
                ))
            }
            if data.sleepHours <= 0 {
                out.append(.init(
                    id: "fitbit-sleep-air",
                    title: "Fill sleep air gap",
                    detail: "No sleep hours in tonight’s Fitbit air — open Fitbit app, then refresh.",
                    icon: "moon.zzz.fill",
                        readyDelta: 4
                ))
            }
            if out.count < 2 {
                out.append(.init(
                    id: "fitbit-sync",
                    title: "Confirm Fitbit sync",
                    detail: "Pull-to-refresh so Google Health air fields stay current.",
                    icon: "arrow.triangle.2.circlepath",
                        readyDelta: 1
                ))
            }
        }
        if out.isEmpty {
            out.append(.init(
                id: "hold-line",
                title: "Hold the line",
                detail: "Scrubs look balanced — keep today’s plan and recheck after lunch.",
                icon: "checkmark.circle.fill",
                    readyDelta: 1
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
