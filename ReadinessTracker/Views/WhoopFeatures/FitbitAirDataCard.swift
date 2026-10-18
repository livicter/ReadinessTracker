import SwiftUI
import Charts

/// Honest #498: Fitbit / Google Health air-data density card.
/// Live field chips with values, density ring, and 7-day steps spark.
/// Visible for every source; Fitbit branding + Google Health caption when selected.
struct FitbitAirDataCard: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    let source: DataSource

    @State private var selectedChipID: String?

    private let accent = Color(hex: "00B0B9")  // Fitbit teal

    private var chips: [AirChip] {
        AirChip.all(from: data)
    }

    private var filledCount: Int { chips.filter(\.filled).count }
    private var density: Double {
        guard !chips.isEmpty else { return 0 }
        return Double(filledCount) / Double(chips.count)
    }

    private var sparkPoints: [(date: Date, value: Double)] {
        history.suffix(7).map { (date: $0.date, value: Double($0.steps)) }
    }

    private var selectedChip: AirChip? {
        chips.first { $0.id == selectedChipID }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                header
                HStack(alignment: .center, spacing: 16) {
                    densityRing
                    chipGrid
                }
                if let selectedChip {
                    selectedDetail(selectedChip)
                }
                if sparkPoints.contains(where: { $0.value > 0 }) {
                    sparkBlock
                }
            }
            .padding(16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.fitbitAirDataCard)
        .accessibilityLabel(source == .fitbit ? "Fitbit air data" : "Health air data")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(source == .fitbit ? "Fitbit Air" : "Health Air")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(source == .fitbit
                     ? "Google Health fields live tonight"
                     : "Tonight’s field density · switch to Fitbit for GH sync")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer()
            Text("\(filledCount)/\(chips.count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accent.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityIdentifier(SurfaceID.fitbitAirDataDensity)
        }
    }

    private var densityRing: some View {
        ZStack {
            Circle()
                .stroke(RTColor.divider, lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(density))
                .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: density)
            VStack(spacing: 2) {
                Text("\(Int((density * 100).rounded()))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
                Text("AIR")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .frame(width: 84, height: 84)
        .accessibilityLabel("Air density \(Int((density * 100).rounded())) percent")
    }

    private var chipGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
            ForEach(chips) { chip in
                Button {
                    Haptic.selectionChanged()
                    selectedChipID = selectedChipID == chip.id ? nil : chip.id
                } label: {
                    VStack(spacing: 4) {
                        Text(chip.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(chip.filled ? RTColor.primaryText : RTColor.secondaryText)
                            .lineLimit(1)
                        Text(chip.valueText)
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(chip.filled ? accent : RTColor.tertiaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedChipID == chip.id
                                  ? accent.opacity(0.18)
                                  : (chip.filled ? accent.opacity(0.08) : RTColor.surfaceHighlight))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedChipID == chip.id ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(chip.label) \(chip.valueText)")
            }
        }
        .accessibilityIdentifier(SurfaceID.fitbitAirDataChips)
    }

    private func selectedDetail(_ chip: AirChip) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: chip.icon)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(chip.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(chip.detail)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer()
        }
        .padding(10)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var sparkBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Steps · 7d")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            Chart(sparkPoints, id: \.date) { pt in
                AreaMark(
                    x: .value("Day", pt.date),
                    y: .value("Steps", pt.value)
                )
                .foregroundStyle(accent.opacity(0.25))
                LineMark(
                    x: .value("Day", pt.date),
                    y: .value("Steps", pt.value)
                )
                .foregroundStyle(accent)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 56)
            .accessibilityIdentifier(SurfaceID.fitbitAirDataSpark)
        }
    }
}

// MARK: - Chips

struct AirChip: Identifiable {
    let id: String
    let label: String
    let valueText: String
    let detail: String
    let icon: String
    let filled: Bool

    static func all(from data: DailyHealthData) -> [AirChip] {
        let spo2 = data.bloodOxygen
        let resp = data.respiratoryRate
        let skin = data.skinTemperature
        let dist = data.distanceWalkingRunningKm
        let floors = data.flightsClimbed
        let activeMin = data.appleExerciseTimeMinutes
        let basal = data.basalEnergyKcal
        return [
            .init(id: "sleep", label: "Sleep",
                  valueText: data.sleepHours > 0 ? String(format: "%.1fh", data.sleepHours) : "—",
                  detail: "Night sleep hours from Google Health / HealthKit.",
                  icon: "moon.zzz.fill", filled: data.sleepHours > 0),
            .init(id: "hrv", label: "HRV",
                  valueText: data.hrv > 0 ? "\(Int(data.hrv)) ms" : "—",
                  detail: "RMSSD heart-rate variability.",
                  icon: "waveform.path.ecg", filled: data.hrv > 0),
            .init(id: "rhr", label: "RHR",
                  valueText: data.restingHeartRate > 0 ? "\(data.restingHeartRate)" : "—",
                  detail: "Resting heart rate (bpm).",
                  icon: "heart.fill", filled: data.restingHeartRate > 0),
            .init(id: "spo2", label: "SpO₂",
                  valueText: (spo2 ?? 0) > 0 ? String(format: "%.0f%%", spo2!) : "—",
                  detail: "Blood oxygen average.",
                  icon: "lungs.fill", filled: (spo2 ?? 0) > 0),
            .init(id: "resp", label: "Resp",
                  valueText: (resp ?? 0) > 0 ? String(format: "%.1f", resp!) : "—",
                  detail: "Respiratory rate (breaths/min).",
                  icon: "wind", filled: (resp ?? 0) > 0),
            .init(id: "skin", label: "Skin",
                  valueText: skin != nil ? String(format: "%+.1f°", skin!) : "—",
                  detail: "Skin temperature deviation (°C).",
                  icon: "thermometer.medium", filled: skin != nil),
            .init(id: "steps", label: "Steps",
                  valueText: data.steps > 0 ? "\(data.steps)" : "—",
                  detail: "Step count today.",
                  icon: "figure.walk", filled: data.steps > 0),
            .init(id: "kcal", label: "Active",
                  valueText: data.activeCalories > 0 ? "\(Int(data.activeCalories))" : "—",
                  detail: "Active energy (kcal).",
                  icon: "flame.fill", filled: data.activeCalories > 0),
            .init(id: "dist", label: "Dist",
                  valueText: (dist ?? 0) > 0 ? String(format: "%.1f km", dist!) : "—",
                  detail: "Walking + running distance.",
                  icon: "map", filled: (dist ?? 0) > 0),
            .init(id: "floors", label: "Floors",
                  valueText: (floors ?? 0) > 0 ? "\(Int(floors!))" : "—",
                  detail: "Floors / flights climbed.",
                  icon: "figure.stairs", filled: (floors ?? 0) > 0),
            .init(id: "amin", label: "Active′",
                  valueText: (activeMin ?? 0) > 0 ? "\(Int(activeMin!))m" : "—",
                  detail: "Active minutes (exercise).",
                  icon: "timer", filled: (activeMin ?? 0) > 0),
            .init(id: "basal", label: "Basal",
                  valueText: (basal ?? 0) > 0 ? "\(Int(basal!))" : "—",
                  detail: "Basal energy (kcal).",
                  icon: "leaf.fill", filled: (basal ?? 0) > 0),
        ]
    }
}
