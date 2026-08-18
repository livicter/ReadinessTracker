import SwiftUI

/// Horizontal bars per detected sleep cycle with stage composition
/// and a summary of total cycles + average length.
struct SleepCycleView: View {
    let cycles: [SleepCycle]

    private var averageMinutes: Double {
        guard !cycles.isEmpty else { return 0 }
        return cycles.reduce(0) { $0 + $1.durationMinutes } / Double(cycles.count)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Sleep Cycles")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(cycles.count) \(cycles.count == 1 ? "cycle" : "cycles") · avg \(Int(averageMinutes)) min")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                if cycles.isEmpty {
                    Text("No cycles detected. Detailed stage data needed.")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(cycles.enumerated()), id: \.element.id) { index, cycle in
                            cycleRow(index: index + 1, cycle: cycle)
                        }
                    }

                    legend
                }
            }
        }
    }

    private func cycleRow(index: Int, cycle: SleepCycle) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Cycle \(index)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(cycle.startDate, format: .dateTime.hour().minute())")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("\(Int(cycle.durationMinutes)) min")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)
            }

            GeometryReader { geo in
                let awakeMinutes = max(cycle.durationMinutes - cycle.lightMinutes - cycle.deepMinutes - cycle.remMinutes, 0)
                let stages: [(minutes: Double, color: Color)] = [
                    (cycle.lightMinutes, SleepStage.light.color),
                    (cycle.deepMinutes, SleepStage.deep.color),
                    (cycle.remMinutes, SleepStage.rem.color),
                    (awakeMinutes, RTColor.warning),
                ]
                let total = max(stages.reduce(0) { $0 + $1.minutes }, 1)
                let available = geo.size.width - CGFloat(stages.count - 1)
                HStack(spacing: 1) {
                    ForEach(Array(stages.enumerated()), id: \.offset) { _, stage in
                        segment(width: available * CGFloat(stage.minutes / total), color: stage.color)
                    }
                }
            }
            .frame(height: 14)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private func segment(width: CGFloat, color: Color) -> some View {
        Rectangle().fill(color).frame(width: max(width, 0))
    }

    private var legend: some View {
        HStack(spacing: 16) {
            ForEach([SleepStage.light, .deep, .rem], id: \.self) { stage in
                HStack(spacing: 6) {
                    Circle().fill(stage.color).frame(width: 8, height: 8)
                    Text(stage.label)
                        .font(.caption2)
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
        }
    }
}
