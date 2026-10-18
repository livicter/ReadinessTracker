import SwiftUI

/// Honest #501: Settings Fitbit air-status density from latest Google Health day.
struct FitbitSettingsAirStatus: View {
    let data: DailyHealthData?

    private let accent = Color(hex: "00B0B9")

    private var chips: [AirChip] {
        guard let data else { return [] }
        return AirChip.all(from: data)
    }

    private var filled: Int { chips.filter(\.filled).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
}
