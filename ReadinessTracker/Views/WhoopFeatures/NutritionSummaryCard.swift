import SwiftUI

/// WHOOP / Google Health–style nutrition glance: water, caffeine, protein
/// with Apple circular tint wells and soft targets aligned to coaching cues.
struct NutritionSummaryCard: View {
    let nutrition: NutritionSummary

    /// Soft daily targets (not medical advice) — matches coaching thresholds.
    private let waterTargetLiters = 2.5
    private let caffeineLimitMg = 200.0
    private let proteinTargetGrams = 100.0

    private var status: (label: String, color: Color) {
        var issues: [String] = []
        if let w = nutrition.waterLiters, w < 1.5 { issues.append("Low water") }
        if let c = nutrition.caffeineMg, c >= 250 { issues.append("High caffeine") }
        if let p = nutrition.proteinGrams, p < 100 { issues.append("Low protein") }
        if issues.isEmpty {
            return ("On track", RTColor.optimal)
        }
        if issues.count == 1 {
            return (issues[0], RTColor.caution)
        }
        return ("Needs attention", RTColor.warning)
    }

    var body: some View {
        if nutrition.isEmpty {
            EmptyView()
        } else {
            NativeCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nutrition")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)
                            Text("Today · water · caffeine · protein")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.secondaryText)
                        }
                        Spacer()
                        Text(status.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(status.color.opacity(0.12))
                            .clipShape(Capsule())
                            .accessibilityLabel(status.label)
                    }

                    HStack(spacing: 10) {
                        if let water = nutrition.waterLiters {
                            metricTile(
                                icon: "drop.fill",
                                label: "Water",
                                valueText: String(format: "%.1f", water),
                                unit: "L",
                                color: Color.cyan,
                                progress: min(1, water / waterTargetLiters),
                                caption: "goal \(String(format: "%.1f", waterTargetLiters))L",
                                surfaceID: SurfaceID.strainNutritionWater
                            )
                        }
                        if let caffeine = nutrition.caffeineMg {
                            let over = caffeine > caffeineLimitMg
                            metricTile(
                                icon: "cup.and.saucer.fill",
                                label: "Caffeine",
                                valueText: "\(Int(caffeine))",
                                unit: "mg",
                                color: over ? RTColor.caution : RTColor.good,
                                progress: min(1, caffeine / caffeineLimitMg),
                                caption: "limit \(Int(caffeineLimitMg))mg",
                                surfaceID: SurfaceID.strainNutritionCaffeine
                            )
                        }
                        if let protein = nutrition.proteinGrams {
                            metricTile(
                                icon: "fork.knife",
                                label: "Protein",
                                valueText: "\(Int(protein))",
                                unit: "g",
                                color: protein < proteinTargetGrams ? RTColor.caution : RTColor.optimal,
                                progress: min(1, protein / proteinTargetGrams),
                                caption: "goal \(Int(proteinTargetGrams))g",
                                surfaceID: SurfaceID.strainNutritionProtein
                            )
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.strainNutrition)
                .accessibilityLabel("Nutrition \(status.label)")
            }
        }
    }

    private func metricTile(
        icon: String,
        label: String,
        valueText: String,
        unit: String,
        color: Color,
        progress: Double,
        caption: String,
        surfaceID: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 26, height: 26)
                    .background(color.opacity(0.14))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(valueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RTColor.primaryText)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.tertiaryText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RTColor.divider.opacity(0.6))
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geo.size.width * CGFloat(progress)))
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)

            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(surfaceID)
        .accessibilityLabel("\(label) \(valueText) \(unit), \(caption)")
    }
}
