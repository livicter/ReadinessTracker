import SwiftUI

#if os(iOS)
/// Audit chrome mirroring Watch `WatchSleepView` (Hours|Eff callout + stage bar + legend).
struct WatchSleepChrome: View {
    var sleepHours: Double = 7.4
    var sleepEfficiency: Double = 0.91
    var sleepScore: Int = 80
    var deepSleepPercent: Double = 0.18
    var remSleepPercent: Double = 0.24
    /// Glance freshness from `WatchSnapshot.date` (Honest #53 audit sync); hide if nil.
    var snapshotDate: Date? = Date().addingTimeInterval(-5 * 60)

    private var lightPercent: Double {
        max(0, 1 - deepSleepPercent - remSleepPercent)
    }

    private let indigo = Color(red: 94/255, green: 92/255, blue: 230/255)
    private let purple = Color(red: 191/255, green: 90/255, blue: 242/255)
    private let teal = Color(red: 100/255, green: 210/255, blue: 255/255)
    private let green = Color(red: 0/255, green: 208/255, blue: 132/255)

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                dualCallout(label: "Hours", value: String(format: "%.1f", sleepHours), unit: "h", color: indigo)
                dualCallout(
                    label: "Eff",
                    value: "\(Int((sleepEfficiency * 100).rounded()))",
                    unit: "%",
                    color: teal
                )
            }

            if sleepScore > 0 {
                Text("Sleep \(sleepScore)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(green)
            }

            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(purple)
                        .frame(width: max(0, geo.size.width * deepSleepPercent))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(indigo)
                        .frame(width: max(0, geo.size.width * remSleepPercent))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(teal.opacity(0.6))
                        .frame(width: max(0, geo.size.width * lightPercent))
                }
            }
            .frame(height: 10)

            HStack(spacing: 8) {
                stageLegend(color: purple, title: "Deep", percent: Int((deepSleepPercent * 100).rounded()))
                stageLegend(color: indigo, title: "REM", percent: Int((remSleepPercent * 100).rounded()))
                stageLegend(color: teal, title: "Light", percent: Int((lightPercent * 100).rounded()))
            }

            if let snapshotDate {
                HStack(spacing: 0) {
                    Text("Updated ")
                    Text(snapshotDate, style: .relative)
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .accessibilityElement(children: .combine)
            }

            Text("Sleep")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(16)
        .frame(width: 184, height: 268)
        .background(Color.black)
    }

    private func dualCallout(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.55))
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func stageLegend(color: Color, title: String, percent: Int) -> some View {
        HStack(spacing: 4) {
            Capsule()
                .fill(color)
                .frame(width: 3, height: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Text("\(percent)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
