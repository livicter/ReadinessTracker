import SwiftUI

/// Honest #501: Settings Fitbit air-status density from latest Google Health day.
/// Honest #625: interactive density ring + Sleep/Vitals/Move fill (Fitbit + HealthKit UX graphics).
/// Honest #638: HealthKit / appleWatch parity — pink accent + `settings.health.air*` SIDs.
struct FitbitSettingsAirStatus: View {
    let data: DailyHealthData?
    var source: DataSource = .fitbit

    @State private var focusedCategory: AirDensityCategory?

    private var accent: Color {
        source == .appleWatch ? Color(hex: "FF2D55") : Color(hex: "00B0B9")
    }

    private var chips: [AirChip] {
        guard let data else { return [] }
        return AirChip.all(from: data)
    }

    private var filled: Int { chips.filter(\.filled).count }
    private var density: Double {
        guard !chips.isEmpty else { return 0 }
        return Double(filled) / Double(chips.count)
    }

    private var brandTitle: String {
        source == .appleWatch ? "Health air · HealthKit fields" : "Fitbit air · Health fields"
    }

    private var emptyHint: String {
        source == .appleWatch
            ? "Reconnect Apple Health or refresh after Watch overnight wear."
            : "Refresh after Google Health sync to populate air chips."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Air tonight")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text(data == nil ? "No day yet" : "\(filled)/\(max(chips.count, 1))")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
            }

            if chips.isEmpty {
                Text(emptyHint)
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    densityRing
                    VStack(alignment: .leading, spacing: 6) {
                        Text(brandTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                        ForEach(AirDensityCategory.allCases) { cat in
                            Button {
                                Haptic.selectionChanged()
                                focusedCategory = focusedCategory == cat ? nil : cat
                            } label: {
                                categoryRow(cat)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .accessibilityIdentifier(source == .appleWatch
                                        ? SurfaceID.settingsHealthAirRing
                                        : SurfaceID.settingsFitbitAirRing)
                .accessibilityLabel("Air density ring \(Int((density * 100).rounded())) percent")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                    ForEach(visibleChips) { chip in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(chip.filled ? RTColor.optimal : RTColor.tertiaryText.opacity(0.35))
                                .frame(width: 6, height: 6)
                            Text(chip.label)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(chip.filled ? RTColor.primaryText : RTColor.secondaryText)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(RTColor.surfaceHighlight.opacity(chip.filled ? 1 : 0.5))
                        .clipShape(Capsule())
                        .opacity(chipOpacity(chip))
                    }
                }
                .accessibilityIdentifier(source == .appleWatch
                                        ? SurfaceID.settingsHealthAirChips
                                        : SurfaceID.settingsFitbitAirChips)
            }
        }
        .padding(10)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.settingsHealthAirStatus
                                 : SurfaceID.settingsFitbitAirStatus)
        .accessibilityLabel(source == .appleWatch ? "Health air status" : "Fitbit air status")
    }

    private var visibleChips: [AirChip] {
        Array(chips.prefix(8))
    }

    private func chipOpacity(_ chip: AirChip) -> Double {
        guard let focus = focusedCategory else { return 1 }
        return focus.chipIDs.contains(chip.id) ? 1 : 0.35
    }

    private var densityRing: some View {
        let pct = Int((density * 100).rounded())
        let tone: Color = density >= 0.75 ? RTColor.optimal
            : density >= 0.45 ? RTColor.good
            : density >= 0.2 ? RTColor.caution
            : RTColor.warning
        return ZStack {
            Circle()
                .stroke(RTColor.tertiaryText.opacity(0.15), lineWidth: 7)
                .frame(width: 64, height: 64)
            Circle()
                .trim(from: 0, to: CGFloat(density))
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(pct)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                Text("air")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
    }

    private func categoryRow(_ cat: AirDensityCategory) -> some View {
        let ratio = cat.fillRatio(in: chips)
        let n = cat.filledCount(in: chips)
        let total = cat.chipIDs.count
        let focused = focusedCategory == cat
        return HStack(spacing: 6) {
            Text(cat.shortTitle)
                .font(.system(size: 9, weight: .bold).monospacedDigit())
                .foregroundStyle(focused ? Color.white : cat.color)
                .frame(width: 28, alignment: .leading)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(focused ? 0.28 : 0.12))
                    Capsule()
                        .fill(LinearGradient(
                            colors: focused
                                ? [Color.white.opacity(0.85), Color.white]
                                : [cat.color.opacity(0.55), cat.color],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(2, w * CGFloat(ratio)))
                }
            }
            .frame(height: 7)
            Text("\(n)/\(total)")
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(focused ? Color.white.opacity(0.9) : RTColor.tertiaryText)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(focused ? cat.color : Color.clear)
        )
    }
}
