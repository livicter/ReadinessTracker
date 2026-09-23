import SwiftUI

/// WHOOP-style recovery soft bands (Green / Yellow / Red).
enum RecoveryZone: String, CaseIterable, Identifiable {
    case green = "Green"
    case yellow = "Yellow"
    case red = "Red"

    var id: String { rawValue }

    /// Inclusive score ranges on the 0–100 recovery wheel scale.
    var scoreRange: ClosedRange<Double> {
        switch self {
        case .green: return 67...100
        case .yellow: return 34...66.999
        case .red: return 0...33.999
        }
    }

    var color: Color {
        switch self {
        case .green: return RTColor.optimal
        case .yellow: return RTColor.caution
        case .red: return RTColor.warning
        }
    }

    static func zone(for score: Double) -> RecoveryZone {
        let s = max(0, min(100, score))
        if s >= 67 { return .green }
        if s >= 34 { return .yellow }
        return .red
    }
}

/// WHOOP signature multi-day recovery days-in-zone distribution.
/// Elevates `TrendAnalysisEngine.zoneDistribution` on Recovery wheel scores —
/// distinct from Strain Zones (#239).
struct RecoveryZoneDistributionCard: View {
    let history: [(date: Date, recovery: Double)]

    /// Ordered high→low so first match wins inside `zoneDistribution`.
    static let softZones: [(range: ClosedRange<Double>, label: String)] = [
        (RecoveryZone.green.scoreRange, RecoveryZone.green.rawValue),
        (RecoveryZone.yellow.scoreRange, RecoveryZone.yellow.rawValue),
        (RecoveryZone.red.scoreRange, RecoveryZone.red.rawValue)
    ]

    private var values: [Double] {
        history.map { max(0, min(100, $0.recovery)) }
    }

    private var distribution: [(label: String, count: Int, percentage: Double)] {
        guard values.count >= 3 else { return [] }
        let raw = TrendAnalysisEngine.zoneDistribution(values: values, zones: Self.softZones)
        return RecoveryZone.allCases.map { zone in
            raw.first(where: { $0.label == zone.rawValue })
                ?? (label: zone.rawValue, count: 0, percentage: 0)
        }
    }

    private var dayCount: Int { values.count }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recovery Zones")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        Text("\(dayCount) days · Green / Yellow / Red")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    Spacer()
                    if let top = distribution.max(by: { $0.count < $1.count }), top.count > 0 {
                        Text(top.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(color(for: top.label))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(color(for: top.label).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if distribution.contains(where: { $0.count > 0 }) {
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(distribution, id: \.label) { zone in
                                if zone.count > 0 {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(color(for: zone.label))
                                        .frame(width: max(4, geo.size.width * CGFloat(zone.percentage)))
                                }
                            }
                        }
                    }
                    .frame(height: 12)
                    .accessibilityIdentifier(SurfaceID.recoveryZoneDistBar)
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        ForEach(distribution, id: \.label) { zone in
                            zoneRow(zone)
                        }
                    }
                } else {
                    Text("Need a few more recovery days")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.recoveryZoneDistCard)
            .accessibilityLabel("Recovery zone distribution")
        }
    }

    private func zoneRow(_ zone: (label: String, count: Int, percentage: Double)) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color(for: zone.label).opacity(0.14))
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .fill(color(for: zone.label))
                        .frame(width: 10, height: 10)
                )
                .accessibilityHidden(true)

            Text(zone.label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RTColor.primaryText)

            Spacer(minLength: 8)

            Text("\(zone.count)d")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTColor.primaryText)
                .monospacedDigit()

            Text("\(Int((zone.percentage * 100).rounded()))%")
                .font(.caption.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(surfaceID(for: zone.label))
        .accessibilityLabel("\(zone.label) \(zone.count) days, \(Int((zone.percentage * 100).rounded())) percent")
    }

    private func surfaceID(for label: String) -> String {
        switch label {
        case "Green": return SurfaceID.recoveryZoneDistGreen
        case "Yellow": return SurfaceID.recoveryZoneDistYellow
        case "Red": return SurfaceID.recoveryZoneDistRed
        default: return SurfaceID.recoveryZoneDistCard
        }
    }

    private func color(for label: String) -> Color {
        RecoveryZone(rawValue: label)?.color ?? RTColor.secondaryText
    }
}
