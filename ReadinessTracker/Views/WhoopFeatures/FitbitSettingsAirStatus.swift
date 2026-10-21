import SwiftUI

/// Honest #501: Settings Fitbit air-status density from latest Google Health day.
/// Honest #625: interactive density ring + Sleep/Vitals/Move fill (Fitbit + HealthKit UX graphics).
struct FitbitSettingsAirStatus: View {
    let data: DailyHealthData?

    private let accent = Color(hex: "00B0B9")

    private var chips: [AirChip] {
        guard let data else { return [] }
        return AirChip.all(from: data)
    }

    private var filled: Int { chips.filter(\.filled).count }
    private var density: Double {
        guard !chips.isEmpty else { return 0 }
        return Double(filled) / Double(chips.count)
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
                Text("Refresh after Google Health sync to populate air chips.")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    densityRing
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fitbit air · Health fields")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                        ForEach(AirDensityCategory.allCases) { cat in
                            categoryRow(cat)
                        }
                    }
                }
                .accessibilityIdentifier(SurfaceID.settingsFitbitAirRing)
                .accessibilityLabel("Air density ring \(Int((density * 100).rounded())) percent")

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], spacing: 6) {
                    ForEach(chips.prefix(8)) { chip in
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
                    }
                }
                .accessibilityIdentifier(SurfaceID.settingsFitbitAirChips)
            }
        }
        .padding(10)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier(SurfaceID.settingsFitbitAirStatus)
        .accessibilityLabel("Fitbit air status")
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
        return HStack(spacing: 6) {
            Text(cat.shortTitle)
                .font(.system(size: 9, weight: .bold).monospacedDigit())
                .foregroundStyle(cat.color)
                .frame(width: 28, alignment: .leading)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [cat.color.opacity(0.55), cat.color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(2, w * CGFloat(ratio)))
                }
            }
            .frame(height: 7)
            Text("\(n)/\(total)")
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(RTColor.tertiaryText)
                .frame(width: 28, alignment: .trailing)
        }
    }
}
