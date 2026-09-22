import SwiftUI

/// Apple Health–style sleep stage breakdown: stacked bar without in-bar icons,
/// labels under the bar, quiet total subline — no score capsule (score lives on
/// Sleep Analysis summary).
struct SleepStageBreakdown: View {
    let sleepHours: Double
    let deepPercent: Double
    let remPercent: Double
    let awakePercent: Double
    var efficiency: Double = 0.9

    private var corePercent: Double {
        max(0, 1.0 - deepPercent - remPercent - awakePercent)
    }

    /// Apple Health order: Awake → REM → Core → Deep.
    private var stages: [(label: String, percent: Double, color: Color)] {
        [
            ("Awake", awakePercent, RTColor.caution),
            ("REM", remPercent, Color(hex: "BF5AF2")),
            ("Core", corePercent, Color(hex: "5E5CE6")),
            ("Deep", deepPercent, RTColor.optimal)
        ]
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sleep Stages")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)

                    Text("\(formatHours(sleepHours)) total")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                }

                // Continuous stacked bar — no icons inside segments.
                GeometryReader { geo in
                    let totalPercent = stages.reduce(0) { $0 + max(0, $1.percent) }
                    let width = geo.size.width
                    let gap: CGFloat = 2
                    let gaps = CGFloat(max(0, stages.filter { $0.percent > 0.001 }.count - 1)) * gap
                    let usable = max(0, width - gaps)

                    HStack(spacing: gap) {
                        ForEach(stages.indices, id: \.self) { i in
                            let stage = stages[i]
                            let pct = totalPercent > 0 ? max(0, stage.percent) / totalPercent : 0
                            if pct > 0.001 {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(stage.color)
                                    .frame(width: max(3, usable * CGFloat(pct)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(height: 14)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityBarLabel)

                // Labels under the bar (Apple Health): tint well + name + hours.
                HStack(alignment: .top, spacing: 0) {
                    ForEach(stages.indices, id: \.self) { i in
                        let stage = stages[i]
                        stageUnderLabel(stage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func stageUnderLabel(_ stage: (label: String, percent: Double, color: Color)) -> some View {
        let hours = sleepHours * max(0, stage.percent)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(stage.color.opacity(0.18))
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(stage.color)
                        .frame(width: 8, height: 8)
                }
                Text(stage.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text(formatHours(hours))
                .font(.caption2)
                .foregroundStyle(RTColor.secondaryText)
                .monospacedDigit()
            Text("\(Int((stage.percent * 100).rounded()))%")
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stage.label), \(formatHours(hours)), \(Int((stage.percent * 100).rounded())) percent")
    }

    private var accessibilityBarLabel: String {
        stages
            .map { "\($0.label) \(Int(($0.percent * 100).rounded())) percent" }
            .joined(separator: ", ")
    }

    private func formatHours(_ hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
