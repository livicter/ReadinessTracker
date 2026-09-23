import SwiftUI
import Charts

/// Elevates buried `menstrualFlow` into a Tonight | Baseline dual on Today Body
/// (beyond the Cycle tile chip). CycleDetailView sheet from Honest #101 stays as-is.
struct CycleTonightBaselineCard: View {
    let hasFlowTonight: Bool
    let history: [(date: Date, flow: Bool)]

    private let cycleColor = Color(hex: "FF2D55")

    private var window: [(date: Date, flow: Bool)] {
        Array(history.sorted { $0.date < $1.date }.suffix(7))
    }

    private var flowDaysBaseline: Int {
        window.filter(\.flow).count
    }

    private var baselineRate: Double {
        guard !window.isEmpty else { return hasFlowTonight ? 1 : 0 }
        return Double(flowDaysBaseline) / Double(window.count)
    }

    private var status: (label: String, color: Color) {
        if hasFlowTonight { return ("Active flow", cycleColor) }
        if flowDaysBaseline >= 3 { return ("Recent flow", RTColor.caution) }
        if flowDaysBaseline >= 1 { return ("Winding down", RTColor.good) }
        return ("Between periods", RTColor.optimal)
    }

    private var sparklineValues: [Double] {
        window.map { $0.flow ? 1.0 : 0.0 }
    }

    private var chartPoints: [(date: Date, value: Double)] {
        window.map { (date: $0.date, value: $0.flow ? 1.0 : 0.0) }
    }

    private var readinessCaption: String {
        hasFlowTonight
            ? "−3 readiness & recovery while tracking"
            : "No score adjustment tonight"
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cycle")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)

                        Text("Flow status · \(status.label)")
                            .font(.subheadline)
                            .foregroundStyle(status.color)
                    }

                    Spacer()

                    Text(hasFlowTonight ? "Flow" : "Clear")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(status.color.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(hasFlowTonight ? "Flow reported tonight" : "No flow tonight")
                }

                HStack(spacing: 12) {
                    dualColumn(
                        label: "Tonight",
                        valueText: hasFlowTonight ? "Flow" : "None",
                        unit: "",
                        color: status.color,
                        caption: readinessCaption,
                        icon: "circle.lefthalf.filled"
                    )

                    Rectangle()
                        .fill(RTColor.divider)
                        .frame(width: 1)
                        .padding(.vertical, 4)

                    dualColumn(
                        label: "Baseline",
                        valueText: "\(flowDaysBaseline)",
                        unit: "/\(max(window.count, 7))",
                        color: RTColor.secondaryText,
                        caption: "days with flow (7-day)",
                        icon: "calendar"
                    )
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.cycleBaselineCallout)

                if sparklineValues.count >= 2 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("7-Day Flow")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(RTColor.secondaryText)
                            Spacer()
                            Text("\(flowDaysBaseline) of \(window.count)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(cycleColor)
                                .monospacedDigit()
                        }
                        AnimatedSparkline(data: sparklineValues, color: cycleColor)
                            .frame(height: 28)
                            .accessibilityIdentifier(SurfaceID.cycleSpark)
                    }
                }

                if chartPoints.count >= 3 {
                    Chart {
                        ForEach(Array(chartPoints.enumerated()), id: \.offset) { _, point in
                            BarMark(
                                x: .value("Day", point.date, unit: .day),
                                y: .value("Flow", point.value)
                            )
                            .foregroundStyle(point.value > 0.5 ? cycleColor : cycleColor.opacity(0.18))
                            .cornerRadius(3)
                        }
                    }
                    .chartYScale(domain: 0...1.2)
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 56)
                    .accessibilityLabel("Cycle flow last seven days")
                }
            }
            .padding(16)
        }
        .accessibilityIdentifier(SurfaceID.cycleCard)
    }

    private func dualColumn(
        label: String,
        valueText: String,
        unit: String,
        color: Color,
        caption: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 22, height: 22)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(valueText)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(RTColor.primaryText)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                        .monospacedDigit()
                }
            }
            Text(caption)
                .font(.caption2)
                .foregroundStyle(RTColor.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
