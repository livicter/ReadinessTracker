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
    /// Honest #520: saved A snapshot of levers for A/B compare.
    @State private var snapA: (sleep: Double, hrv: Double, strain: Double, rhr: Double, spo2: Double, ready: Int)? = nil
    /// Honest #530: saved B snapshot (frozen) for A−B delta.
    @State private var snapB: (sleep: Double, hrv: Double, strain: Double, rhr: Double, spo2: Double, ready: Int)? = nil
    /// Honest #541: sort Today’s tasks by READY impact (high→low).
    @State private var sortTasksByImpact = false
    /// Honest #543: show only air-gap tasks vs all.
    @State private var showAirGapTasksOnly = false

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

    /// Honest #528: checked-task READY lift folded into projection hero.
    private var taskReadyLift: Int {
        tasks.filter { completedTaskIDs.contains($0.id) }.map(\.readyDelta).reduce(0, +)
    }
    private var projectedCoupled: Int {
        min(100, max(0, projected + taskReadyLift))
    }
    private var deltaCoupledVsBaseline: Int { projectedCoupled - baseline }

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
                abSnapshotBlock
                projectionHero
                leverDeltaChips
                leverSensitivityBars
                projectedRingChips
                interactiveControls
                sparkProjection
                readyPathSpark
                readyZoneStrip
                seedLiveDeltaRail
                taskCompletionRadial
                readyCompositionStack
                readyTaskWaterfall
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
        case .ready: return projectedCoupled
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
                    deltaCoupledVsBaseline >= 0 ? "+\(deltaCoupledVsBaseline)" : "\(deltaCoupledVsBaseline)",
                    "vs baseline"
                )
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .font(.caption2.weight(.bold))
                    Text(taskReadyLift > 0 ? "Tasks +\(taskReadyLift)" : "Tasks → gauge")
                        .font(.caption2.weight(.bold).monospacedDigit())
                    Text("coupled")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                .foregroundStyle(taskReadyLift > 0 ? RTColor.optimal : accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((taskReadyLift > 0 ? RTColor.optimal : accent).opacity(0.12))
                .clipShape(Capsule())
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskCoupled)
                .accessibilityLabel(taskReadyLift > 0
                                    ? "Tasks plus \(taskReadyLift) in gauge"
                                    : "Tasks coupled into gauge")
                .animation(.easeInOut(duration: 0.2), value: taskReadyLift)
                Text(focusedRing == .ready
                     ? ReadinessCalculator.recommendation(for: projectedCoupled)
                     : focusedRing.caption(gym: projectedGym, work: projectedWork, sleep: projectedSleep, ready: projectedCoupled))
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

    /// Honest #567: lever sensitivity bars — per-lever READY contribution Chart (Google Health graphics).
    private var leverSensitivityBars: some View {
        let rows: [(SimLeverKind, Double)] = SimLeverKind.allCases.map { lever in
            (lever, lever.contribution(sleep: sleepDelta, hrv: hrvDelta, strain: strainDelta, rhr: rhrDelta, spo2: spo2Delta))
        }
        let sum = rows.map(\.1).reduce(0, +)
        let sumLabel = sum >= 0 ? String(format: "Σ +%.1f", sum) : String(format: "Σ %.1f", sum)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Lever sensitivity")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text(sumLabel)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(sum >= 0 ? RTColor.optimal : Color(hex: "FF375F"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((sum >= 0 ? RTColor.optimal : Color(hex: "FF375F")).opacity(0.12))
                    .clipShape(Capsule())
            }
            Chart {
                ForEach(rows, id: \.0.id) { lever, value in
                    BarMark(
                        x: .value("Lever", lever.title),
                        y: .value("READY", value)
                    )
                    .foregroundStyle(value >= 0 ? lever.color : lever.color.opacity(0.55))
                    .cornerRadius(4)
                }
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(RTColor.tertiaryText.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
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
                        .font(.caption2)
                }
            }
            .frame(height: 110)
            .animation(.easeInOut(duration: 0.25), value: sleepDelta)
            .animation(.easeInOut(duration: 0.25), value: hrvDelta)
            .animation(.easeInOut(duration: 0.25), value: strainDelta)
            .animation(.easeInOut(duration: 0.25), value: rhrDelta)
            .animation(.easeInOut(duration: 0.25), value: spo2Delta)
            Text("READY points per scrub · tap chips above to focus a lever")
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.readinessSimulatorLeverSensitivity)
        .accessibilityLabel("Lever sensitivity \(sumLabel)")
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
                snapA = nil
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

            // Honest #547: seed levers from air density tomorrow forecast
            Button {
                Haptic.selectionChanged()
                seedFromDensityForecast()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                    Text("Seed from density forecast")
                        .font(.caption.weight(.bold))
                    Spacer()
                    Text("tmrw")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accent.opacity(0.15))
                        .clipShape(Capsule())
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(SurfaceID.readinessSimulatorSeedForecast)
            .accessibilityLabel("Seed simulator from density forecast")

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


    /// Honest #547: nudge levers from linear air-density tomorrow forecast.
    private func seedFromDensityForecast() {
        let days = Array(history.suffix(7))
        guard days.count >= 3 else {
            airSeededSummary = "Need ≥3 days of air history for forecast"
            return
        }
        func dens(_ day: DailyHealthData) -> Double {
            let c = AirChip.all(from: day)
            guard !c.isEmpty else { return 0 }
            return Double(c.filter(\.filled).count) / Double(c.count)
        }
        let ys = days.map(dens)
        let n = Double(ys.count)
        let xs = (0..<ys.count).map { Double($0) }
        let meanX = xs.reduce(0, +) / n
        let meanY = ys.reduce(0, +) / n
        var num = 0.0, den = 0.0
        for i in ys.indices {
            num += (xs[i] - meanX) * (ys[i] - meanY)
            den += (xs[i] - meanX) * (xs[i] - meanX)
        }
        let slope = den == 0 ? 0 : num / den
        let intercept = meanY - slope * meanX
        let today = ys.last ?? meanY
        let tomorrow = min(1, max(0, intercept + slope * n))
        let deltaPP = (tomorrow - today) * 100

        func clamp(_ v: Double, _ r: ClosedRange<Double>) -> Double {
            min(r.upperBound, max(r.lowerBound, v))
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            // Rising density → lean into recovery; falling → protect (more sleep, less strain).
            if deltaPP >= 0 {
                sleepDelta = clamp(0.3 + deltaPP / 40.0, -2...2)
                hrvDelta = clamp(4 + deltaPP / 2.0, -20...20)
                strainDelta = clamp(-0.5 - deltaPP / 20.0, -6...6)
                rhrDelta = clamp(-1 - deltaPP / 15.0, -10...10)
                spo2Delta = clamp(0.3 + deltaPP / 50.0, -3...3)
            } else {
                sleepDelta = clamp(0.6 - deltaPP / 30.0, -2...2)
                hrvDelta = clamp(2 - deltaPP / 4.0, -20...20)
                strainDelta = clamp(-1.5 + deltaPP / 15.0, -6...6)
                rhrDelta = clamp(-2 + deltaPP / 20.0, -10...10)
                spo2Delta = clamp(0.5 - deltaPP / 40.0, -3...3)
            }
            focusedLever = nil
            airSeededSummary = String(
                format: "Seeded from forecast · tmrw %d%% (%+.0fpp)",
                Int((tomorrow * 100).rounded()),
                deltaPP
            )
        }
    }

    /// Honest #520: richer simulation — save A, compare live B READY delta.
    private var abSnapshotBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button {
                    Haptic.selectionChanged()
                    snapA = (sleepDelta, hrvDelta, strainDelta, rhrDelta, spo2Delta, projected)
                } label: {
                    Text(snapA == nil ? "Save A" : "Update A")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    Haptic.selectionChanged()
                    guard let a = snapA else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sleepDelta = a.sleep
                        hrvDelta = a.hrv
                        strainDelta = a.strain
                        rhrDelta = a.rhr
                        spo2Delta = a.spo2
                    }
                } label: {
                    Text("Recall A")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(snapA == nil ? RTColor.tertiaryText : accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(accent.opacity(snapA == nil ? 0.08 : 0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(snapA == nil)

                Button {
                    Haptic.selectionChanged()
                    snapA = nil
                    snapB = nil
                } label: {
                    Text("Clear")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RTColor.surfaceHighlight)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            // Honest #530: freeze live as Snap B
            HStack(spacing: 8) {
                Button {
                    Haptic.selectionChanged()
                    snapB = (sleepDelta, hrvDelta, strainDelta, rhrDelta, spo2Delta, projectedCoupled)
                } label: {
                    Text(snapB == nil ? "Save B" : "Update B")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RTColor.optimal.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    Haptic.selectionChanged()
                    guard let b = snapB else { return }
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sleepDelta = b.sleep
                        hrvDelta = b.hrv
                        strainDelta = b.strain
                        rhrDelta = b.rhr
                        spo2Delta = b.spo2
                    }
                } label: {
                    Text("Recall B")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(snapB == nil ? RTColor.tertiaryText : RTColor.optimal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(RTColor.optimal.opacity(snapB == nil ? 0.08 : 0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(snapB == nil)
            }
            .accessibilityIdentifier(SurfaceID.readinessSimulatorSnapB)
            .accessibilityLabel("Simulator save snapshot B")

            if let a = snapA {
                let bReady = snapB?.ready ?? projectedCoupled
                let d = bReady - a.ready
                let bLabel = snapB == nil ? "Live" : "B"
                HStack(spacing: 8) {
                    Text("A \(a.ready)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(RTColor.secondaryText)
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                    Text("\(bLabel) \(bReady)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                    Spacer()
                    Text(d == 0 ? "±0" : String(format: "%+d READY", d))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(d >= 0 ? RTColor.optimal : RTColor.warning)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((d >= 0 ? RTColor.optimal : RTColor.warning).opacity(0.14))
                        .clipShape(Capsule())
                }
                // Honest #533: per-lever A−B (or A−Live) deltas
                abLeverDiffRow(a: a, b: snapB)
            } else {
                Text("Save A + B, scrub levers, compare Δ")
                    .font(.caption)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.readinessSimulatorABSnapshot)
        .accessibilityLabel("Simulator A B snapshot compare")
    }


    /// Honest #533: interactive A−B lever delta chips (tap focuses lever).
    @ViewBuilder
    private func abLeverDiffRow(
        a: (sleep: Double, hrv: Double, strain: Double, rhr: Double, spo2: Double, ready: Int),
        b: (sleep: Double, hrv: Double, strain: Double, rhr: Double, spo2: Double, ready: Int)?
    ) -> some View {
        let live = (sleep: sleepDelta, hrv: hrvDelta, strain: strainDelta, rhr: rhrDelta, spo2: spo2Delta, ready: projectedCoupled)
        let rhs = b ?? live
        let pairs: [(SimLeverKind, Double)] = [
            (.sleep, rhs.sleep - a.sleep),
            (.hrv, rhs.hrv - a.hrv),
            (.strain, rhs.strain - a.strain),
            (.rhr, rhs.rhr - a.rhr),
            (.spo2, rhs.spo2 - a.spo2)
        ]
        VStack(alignment: .leading, spacing: 6) {
            Text(b == nil ? "A → Live levers" : "A → B levers")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RTColor.tertiaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pairs, id: \.0.id) { kind, delta in
                        Button {
                            Haptic.selectionChanged()
                            focusedLever = kind
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: kind.icon)
                                    .font(.caption2.weight(.bold))
                                Text(kind.title)
                                    .font(.caption2.weight(.semibold))
                                Text(abLeverDeltaText(kind, delta))
                                    .font(.caption2.weight(.bold).monospacedDigit())
                            }
                            .foregroundStyle(focusedLever == kind ? Color.white : kind.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(focusedLever == kind ? kind.color : kind.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(kind.title) delta \(abLeverDeltaText(kind, delta))")
                    }
                }
            }
        }
        .accessibilityIdentifier(SurfaceID.readinessSimulatorABLeverDiff)
        .accessibilityLabel("Simulator A B lever deltas")
    }

    private func abLeverDeltaText(_ kind: SimLeverKind, _ delta: Double) -> String {
        switch kind {
        case .sleep: return String(format: "%+.1fh", delta)
        case .hrv: return String(format: "%+.0f", delta)
        case .strain: return String(format: "%+.1f", delta)
        case .rhr: return String(format: "%+.0f", delta)
        case .spo2: return String(format: "%+.1f", delta)
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


    /// Honest #561: READY path spark — baseline → projected → coupled → ceiling (richer sim graphics).
    private var readyPathSpark: some View {
        let totalLift = tasks.map(\.readyDelta).reduce(0, +)
        let ceiling = min(100, projected + totalLift)
        let points: [(label: String, value: Int)] = [
            ("Base", baseline),
            ("Scrub", projected),
            ("Tasks", projectedCoupled),
            ("Ceil", ceiling)
        ]
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Text("READY path")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text("\(baseline)→\(ceiling)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.optimal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RTColor.optimal.opacity(0.12))
                    .clipShape(Capsule())
            }
            Chart {
                ForEach(Array(points.enumerated()), id: \.offset) { _, pt in
                    LineMark(
                        x: .value("Step", pt.label),
                        y: .value("READY", pt.value)
                    )
                    .foregroundStyle(accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Step", pt.label),
                        y: .value("READY", pt.value)
                    )
                    .foregroundStyle(pt.label == "Ceil" ? RTColor.optimal : accent)
                    .symbolSize(64)
                }
                RuleMark(y: .value("Base", baseline))
                    .foregroundStyle(RTColor.tertiaryText.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
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
                        .font(.caption2)
                }
            }
            .frame(height: 96)
            .animation(.easeInOut(duration: 0.25), value: projectedCoupled)
            .animation(.easeInOut(duration: 0.25), value: ceiling)
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
                .accessibilityIdentifier(SurfaceID.readinessSimulatorPathSpark)
        .accessibilityLabel("READY path \(baseline) to \(ceiling)")
    }

    /// Honest #569: READY zone strip — Poor/Fair/Good/Optimal band + live marker (Google Health graphics).
    private var readyZoneStrip: some View {
        let score = projectedCoupled
        let zones: [(label: String, lo: Int, hi: Int, color: Color)] = [
            ("Poor", 0, 49, Color(hex: "FF375F")),
            ("Fair", 50, 69, RTColor.warning),
            ("Good", 70, 84, RTColor.good),
            ("Optimal", 85, 100, RTColor.optimal)
        ]
        let active = zones.first { score >= $0.lo && score <= $0.hi } ?? zones[0]
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Text("READY zones")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text("\(active.label) · \(score)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(active.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(active.color.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    HStack(spacing: 2) {
                        ForEach(Array(zones.enumerated()), id: \.offset) { _, z in
                            let frac = CGFloat(z.hi - z.lo + 1) / 101.0
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(z.color.opacity(0.55))
                                .frame(width: max(8, w * frac - 2))
                        }
                    }
                    // marker
                    let x = CGFloat(score) / 100.0 * w
                    Capsule()
                        .fill(RTColor.primaryText)
                        .frame(width: 3, height: 22)
                        .offset(x: max(0, min(w - 3, x - 1.5)))
                    Circle()
                        .fill(active.color)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .frame(width: 12, height: 12)
                        .offset(x: max(0, min(w - 12, x - 6)), y: 0)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 22)
            HStack {
                ForEach(Array(zones.enumerated()), id: \.offset) { _, z in
                    Text(z.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(z.label == active.label ? z.color : RTColor.tertiaryText)
                    if z.label != "Optimal" { Spacer(minLength: 0) }
                }
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
                .accessibilityIdentifier(SurfaceID.readinessSimulatorReadyZones)
        .accessibilityLabel("READY zones \(active.label) \(score)")
        .animation(.easeInOut(duration: 0.25), value: projectedCoupled)
    }

    /// Honest #571: seed vs live delta rail — tonight baseline vs scrubbed READY (Fitbit Air / Google Health graphics).
    private var seedLiveDeltaRail: some View {
        let seed = baseline
        let live = projectedCoupled
        let delta = live - seed
        let tone: Color = delta >= 0 ? RTColor.optimal : Color(hex: "FF375F")
        let deltaLabel = delta >= 0 ? "+\(delta)" : "\(delta)"
        // Optional air density context (Fitbit / Google Health parity)
        let airChips = FitbitAirChip.chips(from: data)
        let airDens: Int? = {
            guard !airChips.isEmpty else { return nil }
            let f = airChips.filter(\.filled).count
            return Int((Double(f) / Double(airChips.count) * 100).rounded())
        }()
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Seed vs live")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text(deltaLabel)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seed")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.tertiaryText)
                    Text("\(seed)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(RTColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accent)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Live")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.tertiaryText)
                    Text("\(live)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.14)).frame(height: 12)
                    // seed tick
                    Capsule()
                        .fill(RTColor.secondaryText.opacity(0.7))
                        .frame(width: 2, height: 16)
                        .offset(x: max(0, min(w - 2, w * CGFloat(seed) / 100.0 - 1)))
                    // live fill
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.5), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, w * CGFloat(live) / 100.0), height: 12)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)
            if let airDens {
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(hex: "00B0B9"))
                    Text("Air density \(airDens)% · Fitbit / Google Health")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
                .accessibilityIdentifier(SurfaceID.readinessSimulatorSeedDelta)
        .accessibilityLabel("Seed \(seed) versus live \(live), delta \(deltaLabel)")
        .animation(.easeInOut(duration: 0.25), value: projectedCoupled)
    }

    /// Honest #573: task completion radial — donut of checked vs remaining READY lift (Google Health graphics).
    private var taskCompletionRadial: some View {
        let ordered = tasks
        let totalLift = max(1, ordered.map(\.readyDelta).reduce(0, +))
        let doneLift = ordered.filter { completedTaskIDs.contains($0.id) }.map(\.readyDelta).reduce(0, +)
        let remainLift = max(0, totalLift - doneLift)
        let frac = Double(doneLift) / Double(totalLift)
        let doneN = ordered.filter { completedTaskIDs.contains($0.id) }.count
        let totalN = max(1, ordered.count)
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(accent.opacity(0.18), lineWidth: 10)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: CGFloat(frac))
                    .stroke(
                        AngularGradient(colors: [accent, RTColor.optimal], center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                    .animation(.easeInOut(duration: 0.25), value: doneLift)
                VStack(spacing: 0) {
                    Text("\(Int((frac * 100).rounded()))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                    Text("lift")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "circle.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                    Text("Task radial")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                    Spacer()
                    Text("\(doneN)/\(totalN)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(RTColor.optimal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RTColor.optimal.opacity(0.12))
                        .clipShape(Capsule())
                }
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Circle().fill(RTColor.optimal).frame(width: 7, height: 7)
                        Text("Done +\(doneLift)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(accent.opacity(0.35)).frame(width: 7, height: 7)
                        Text("Left +\(remainLift)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                Text("READY lift folded into projection")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskRadial)
        .accessibilityLabel("Task radial \(doneN) of \(totalN), lift \(Int((frac * 100).rounded())) percent")
    }


    /// Honest #563: READY composition stack — baseline + lever Δ + task lift + headroom (richer sim graphics).
    private var readyCompositionStack: some View {
        let leverLift = projected - baseline
        let taskLift = projectedCoupled - projected
        let headroom = max(0, 100 - projectedCoupled)
        let segments: [(label: String, value: Int, color: Color)] = [
            ("Base", max(0, baseline), accent),
            ("Levers", max(0, leverLift), RTColor.good),
            ("Tasks", max(0, taskLift), RTColor.optimal),
            ("Room", headroom, RTColor.tertiaryText.opacity(0.55))
        ]
        let total = max(1, segments.map(\.value).reduce(0, +))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.3x1.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Text("READY stack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text("\(projectedCoupled)/100")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.optimal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RTColor.optimal.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                        if seg.value > 0 {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(seg.color)
                                .frame(width: max(4, geo.size.width * CGFloat(seg.value) / CGFloat(total)))
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 14)
            .background(RTColor.tertiaryText.opacity(0.12), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            HStack(spacing: 10) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                    HStack(spacing: 4) {
                        Circle().fill(seg.color).frame(width: 7, height: 7)
                        Text("\(seg.label) \(seg.value)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.readinessSimulatorReadyStack)
        .accessibilityLabel("READY stack \(projectedCoupled) of 100")
        .animation(.easeInOut(duration: 0.25), value: projectedCoupled)
    }

    /// Honest #565: READY task waterfall — cumulative lift per task toward ceiling (Google Health graphics).
    @ViewBuilder
    private var readyTaskWaterfall: some View {
        let ordered = tasks.sorted { $0.readyDelta > $1.readyDelta }
        if ordered.isEmpty {
            EmptyView()
        } else {
            taskWaterfallBody(ordered: ordered)
        }
    }

    private func taskWaterfallBody(ordered: [SimulatorTask]) -> some View {
        struct Step: Identifiable {
            let id: Int
            let label: String
            let ready: Int
            let done: Bool
        }
        var steps: [Step] = [Step(id: 0, label: "Now", ready: projected, done: true)]
        var cum = 0
        for (i, task) in ordered.enumerated() {
            cum += task.readyDelta
            steps.append(Step(
                id: i + 1,
                label: String(task.title.prefix(6)),
                ready: min(100, projected + cum),
                done: completedTaskIDs.contains(task.id)
            ))
        }
        let ceiling = steps.last?.ready ?? projected
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Task waterfall")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
                Spacer()
                Text("\(projected)→\(ceiling)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.optimal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(RTColor.optimal.opacity(0.12))
                    .clipShape(Capsule())
            }
            Chart {
                ForEach(steps) { step in
                    AreaMark(
                        x: .value("Step", step.label),
                        y: .value("READY", step.ready)
                    )
                    .foregroundStyle(accent.opacity(0.18))
                    .interpolationMethod(.stepEnd)
                    LineMark(
                        x: .value("Step", step.label),
                        y: .value("READY", step.ready)
                    )
                    .foregroundStyle(accent)
                    .interpolationMethod(.stepEnd)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    PointMark(
                        x: .value("Step", step.label),
                        y: .value("READY", step.ready)
                    )
                    .foregroundStyle(step.done ? RTColor.optimal : accent)
                    .symbolSize(step.id == 0 ? 48 : 36)
                }
                RuleMark(y: .value("Now", projected))
                    .foregroundStyle(RTColor.tertiaryText.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
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
                        .font(.caption2)
                }
            }
            .frame(height: 100)
            .animation(.easeInOut(duration: 0.25), value: completedTaskIDs)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(RTColor.optimal).frame(width: 7, height: 7)
                    Text("Checked")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                HStack(spacing: 4) {
                    Circle().fill(accent).frame(width: 7, height: 7)
                    Text("Queued")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskWaterfall)
        .accessibilityLabel("Task waterfall READY \(projected) to \(ceiling)")
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
        let base = showAirGapTasksOnly
            ? tasks.filter { $0.id.hasPrefix("air-") || $0.id.contains("air") }
            : tasks
        let ordered = sortTasksByImpact
            ? base.sorted { $0.readyDelta > $1.readyDelta }
            : base
        let done = ordered.filter { completedTaskIDs.contains($0.id) }.count
        let lift = ordered.filter { completedTaskIDs.contains($0.id) }.map(\.readyDelta).reduce(0, +)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today’s tasks")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                // Honest #543: air-gap-only filter (Fitbit/Health integration)
                Button {
                    Haptic.selectionChanged()
                    showAirGapTasksOnly.toggle()
                } label: {
                    Text(showAirGapTasksOnly ? "Air" : "All")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(showAirGapTasksOnly ? Color.white : accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(showAirGapTasksOnly ? accent : accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksAirFilter)
                .accessibilityLabel(showAirGapTasksOnly
                                    ? "Showing air gap tasks only, tap for all"
                                    : "Show all tasks, tap for air gaps only")
                // Honest #541: sort by READY impact
                Button {
                    Haptic.selectionChanged()
                    sortTasksByImpact.toggle()
                } label: {
                    Text(sortTasksByImpact ? "Impact ↓" : "Sort")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(sortTasksByImpact ? Color.white : accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sortTasksByImpact ? accent : accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksSort)
                .accessibilityLabel(sortTasksByImpact
                                    ? "Task sort by impact on, tap for default order"
                                    : "Sort tasks by READY impact")
                // Honest #539: one-tap check / clear all tasks
                Button {
                    Haptic.selectionChanged()
                    if done == ordered.count && !ordered.isEmpty {
                        completedTaskIDs.removeAll()
                    } else {
                        completedTaskIDs = Set(ordered.map(\.id))
                    }
                } label: {
                    Text(done == ordered.count && !ordered.isEmpty ? "Clear" : "Check all")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksCheckAll)
                .accessibilityLabel(done == ordered.count && !ordered.isEmpty
                                    ? "Clear all simulator tasks"
                                    : "Check all simulator tasks")
                // Honest #545: check top-3 READY-impact tasks (richer sim)
                Button {
                    Haptic.selectionChanged()
                    let top = Array(ordered.sorted { $0.readyDelta > $1.readyDelta }.prefix(3))
                    if !top.isEmpty && top.allSatisfy({ completedTaskIDs.contains($0.id) }) {
                        for t in top { completedTaskIDs.remove(t.id) }
                    } else {
                        for t in top { completedTaskIDs.insert(t.id) }
                    }
                } label: {
                    Text("Top 3")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksTop3)
                .accessibilityLabel("Check top three READY impact tasks")
                // Honest #551: check next highest READY-impact unchecked task
                if ordered.contains(where: { !completedTaskIDs.contains($0.id) }) {
                    Button {
                        Haptic.selectionChanged()
                        let unchecked = ordered.filter { !completedTaskIDs.contains($0.id) }
                        if let next = unchecked.sorted(by: { $0.readyDelta > $1.readyDelta }).first {
                            completedTaskIDs.insert(next.id)
                        }
                    } label: {
                        Text("Check next")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksCheckNext)
                    .accessibilityLabel("Check next READY-impact task")
                }
                // Honest #553: undo last — uncheck highest READY-impact checked task
                if ordered.contains(where: { completedTaskIDs.contains($0.id) }) {
                    Button {
                        Haptic.selectionChanged()
                        let checked = ordered.filter { completedTaskIDs.contains($0.id) }
                        if let last = checked.sorted(by: { $0.readyDelta > $1.readyDelta }).first {
                            completedTaskIDs.remove(last.id)
                        }
                    } label: {
                        Text("Undo last")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksUndoLast)
                    .accessibilityLabel("Undo last checked READY-impact task")
                }
                Text("\(done)/\(ordered.count)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskProgress)
            }
            // Honest #523: air-gap task cue
            let airGapCount = tasks.filter { $0.id.hasPrefix("air-") || $0.id.contains("air") }.count
            if airGapCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "wind")
                        .font(.caption2.weight(.bold))
                    Text("\(airGapCount) air gap task\(airGapCount == 1 ? "" : "s")")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text(source == .fitbit ? "Fitbit" : "Health")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accent.opacity(0.14))
                        .clipShape(Capsule())
                }
                .foregroundStyle(accent)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorAirGapTasks)
                .accessibilityLabel("\(airGapCount) air gap tasks")
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
            // Honest #555: remaining READY-lift gauge (richer sim graphics)
            let totalLift = ordered.map(\.readyDelta).reduce(0, +)
            let remain = max(0, totalLift - lift)
            let frac = totalLift > 0 ? Double(lift) / Double(totalLift) : 0
            Button {
                Haptic.selectionChanged()
                let unchecked = ordered.filter { !completedTaskIDs.contains($0.id) }
                if let next = unchecked.sorted(by: { $0.readyDelta > $1.readyDelta }).first {
                    completedTaskIDs.insert(next.id)
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Lift progress")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                        Spacer(minLength: 0)
                        Text("+\(lift)/+\(totalLift)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(accent)
                        Text(remain == 0 ? "done" : "remain +\(remain)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(remain == 0 ? RTColor.optimal : RTColor.secondaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((remain == 0 ? RTColor.optimal : accent).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.16))
                                .frame(height: 10)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [accent, RTColor.optimal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: max(10, geo.size.width * CGFloat(frac)), height: 10)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 14)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksRemainLift)
            .accessibilityLabel("READY lift progress +\(lift) of +\(totalLift), remain +\(remain)")
            // Honest #557: next READY-impact task preview chip
            if let next = ordered.filter({ !completedTaskIDs.contains($0.id) })
                .sorted(by: { $0.readyDelta > $1.readyDelta }).first {
                Button {
                    Haptic.selectionChanged()
                    completedTaskIDs.insert(next.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.title3)
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next · +\(next.readyDelta) READY")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(accent)
                            Text(next.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Text("Check")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(accent)
                            .clipShape(Capsule())
                    }
                    .padding(10)
                    .background(accent.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(accent.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksNextPreview)
                .accessibilityLabel("Next task \(next.title), +\(next.readyDelta) READY")
            }
            // Honest #559: projected READY ceiling if all remaining tasks checked
            let ceilingReady = min(100, projected + totalLift)
            let nowReady = projectedCoupled
            let ceilFrac = ceilingReady > 0 ? Double(nowReady) / Double(ceilingReady) : 0
            Button {
                Haptic.selectionChanged()
                // Check all remaining (ceiling path)
                for t in ordered where !completedTaskIDs.contains(t.id) {
                    completedTaskIDs.insert(t.id)
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.to.line.circle.fill")
                            .font(.title3)
                            .foregroundStyle(accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ceiling · READY \(ceilingReady)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(accent)
                            Text(remain == 0
                                 ? "All tasks folded · at ceiling"
                                 : "Now \(nowReady) · +\(remain) left to ceiling")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Text(remain == 0 ? "Done" : "Fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(remain == 0 ? RTColor.optimal : accent)
                            .clipShape(Capsule())
                    }
                    // Dual-rail: now (filled) vs ceiling (track)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.14))
                                .frame(height: 12)
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [RTColor.optimal, accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: max(8, geo.size.width * CGFloat(min(1, ceilFrac))), height: 12)
                            // ceiling tick
                            Capsule()
                                .fill(RTColor.primaryText.opacity(0.55))
                                .frame(width: 2, height: 16)
                                .offset(x: max(0, geo.size.width - 2))
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 16)
                }
                .padding(10)
                .background(accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(SurfaceID.readinessSimulatorTasksCeiling)
            .accessibilityLabel("READY ceiling \(ceilingReady), now \(nowReady), remain +\(remain)")

            // Honest #549: cumulative READY lift spark (bars tint when checked)
            if !ordered.isEmpty {
                Chart {
                    ForEach(Array(ordered.enumerated()), id: \.element.id) { _, task in
                        BarMark(
                            x: .value("Task", String(task.title.prefix(8))),
                            y: .value("Lift", task.readyDelta)
                        )
                        .foregroundStyle(completedTaskIDs.contains(task.id) ? RTColor.optimal : accent.opacity(0.28))
                        .cornerRadius(3)
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(RTColor.tertiaryText)
                            .font(.caption2)
                    }
                }
                .frame(height: 56)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskLiftSpark)
                .accessibilityLabel("READY lift spark, +\(lift) checked")
            }
            ProgressView(value: Double(done), total: Double(max(1, tasks.count)))
                .tint(accent)
                .accessibilityIdentifier(SurfaceID.readinessSimulatorTaskProgressBar)
            ForEach(ordered) { task in
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
        // Honest #523: denser Fitbit/Health air-gap tasks (always consider gaps).
        let airGaps = airGapTasks(data: data, source: source)
        for gap in airGaps where out.count < 5 {
            if !out.contains(where: { $0.id == gap.id }) {
                out.append(gap)
            }
        }
        if source == .fitbit && out.count < 2 {
            out.append(.init(
                id: "fitbit-sync",
                title: "Confirm Fitbit sync",
                detail: "Pull-to-refresh so Google Health air fields stay current.",
                icon: "arrow.triangle.2.circlepath",
                readyDelta: 1
            ))
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
        return Array(out.prefix(5))
    }

    /// Honest #523: tasks that fill missing Fitbit/Health air fields.
    static func airGapTasks(data: DailyHealthData, source: DataSource) -> [SimulatorTask] {
        var gaps: [SimulatorTask] = []
        let via = source == .fitbit ? "Fitbit / Google Health" : "HealthKit"
        if data.hrv <= 0 {
            gaps.append(.init(
                id: "air-hrv",
                title: "Fill HRV air gap",
                detail: "No HRV in tonight’s \(via) air — wear overnight, then sync.",
                icon: "waveform.path.ecg",
                readyDelta: 3
            ))
        }
        if data.sleepHours <= 0 {
            gaps.append(.init(
                id: "air-sleep",
                title: "Fill sleep air gap",
                detail: "Sleep hours missing from \(via) — open the source app and refresh.",
                icon: "moon.zzz.fill",
                readyDelta: 4
            ))
        }
        if data.restingHeartRate <= 0 {
            gaps.append(.init(
                id: "air-rhr",
                title: "Fill RHR air gap",
                detail: "Resting HR empty in \(via) air — quiet wake window helps.",
                icon: "heart.fill",
                readyDelta: 2
            ))
        }
        if (data.bloodOxygen ?? 0) <= 0 {
            gaps.append(.init(
                id: "air-spo2",
                title: "Fill SpO₂ air gap",
                detail: "SpO₂ missing from \(via) — enable overnight oximetry if available.",
                icon: "lungs.fill",
                readyDelta: 2
            ))
        }
        return gaps
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
