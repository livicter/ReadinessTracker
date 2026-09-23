import SwiftUI

/// WHOOP / Google Health–style multi-day strain soft-band distribution.
/// Elevates unused `TrendAnalysisEngine.zoneDistribution` onto Recovery & Strain
/// using the same 0–21 soft bands as Watch Strain (Rest → All out).
struct StrainZoneDistributionCard: View {
    let history: [(date: Date, strain: Double)]

    /// Soft bands aligned with WatchStrainTonightBaselineCard status thresholds.
    /// Ordered high→low so first match wins inside `zoneDistribution`.
    static let softZones: [(range: ClosedRange<Double>, label: String)] = [
        (14.0...21.0, "All out"),
        (10.0...13.999, "Hard"),
        (6.0...9.999, "Moderate"),
        (3.0...5.999, "Light"),
        (0.0...2.999, "Rest")
    ]

    private var values: [Double] {
        history.map { max(0, min(21, $0.strain)) }
    }

    private var distribution: [(label: String, count: Int, percentage: Double)] {
        guard values.count >= 3 else { return [] }
        let raw = TrendAnalysisEngine.zoneDistribution(values: values, zones: Self.softZones)
        // Stable Rest→All out display order (engine sorts by %).
        let order = ["Rest", "Light", "Moderate", "Hard", "All out"]
        return order.compactMap { label in
            raw.first(where: { $0.label == label })
                ?? (label: label, count: 0, percentage: 0)
        }
    }

    private var dayCount: Int { values.count }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strain Zones")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        Text("\(dayCount) days · soft bands")
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
                    .accessibilityIdentifier(SurfaceID.strainZoneDistBar)
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        ForEach(distribution, id: \.label) { zone in
                            zoneRow(zone)
                        }
                    }
                } else {
                    Text("Need a few more strain days")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.strainZoneDistCard)
            .accessibilityLabel("Strain zone distribution")
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
        case "Rest": return SurfaceID.strainZoneDistRest
        case "Light": return SurfaceID.strainZoneDistLight
        case "Moderate": return SurfaceID.strainZoneDistModerate
        case "Hard": return SurfaceID.strainZoneDistHard
        case "All out": return SurfaceID.strainZoneDistAllOut
        default: return SurfaceID.strainZoneDistCard
        }
    }

    private func color(for label: String) -> Color {
        switch label {
        case "Rest": return RTColor.secondaryText
        case "Light": return RTColor.optimal
        case "Moderate": return RTColor.good
        case "Hard": return RTColor.caution
        case "All out": return RTColor.warning
        default: return RTColor.secondaryText
        }
    }
}
