import SwiftUI

/// Page 3: last-night sleep summary with Hours|Efficiency callout + stage legend.
struct WatchSleepView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        ScrollView {
            if let snapshot = session.snapshot {
                let lightPercent = max(0, 1 - snapshot.deepSleepPercent - snapshot.remSleepPercent)
                VStack(spacing: 10) {
                    // WHOOP-like dual callout from existing snapshot fields (no sleepNeed on wrist).
                    HStack(spacing: 12) {
                        dualCallout(
                            label: "Hours",
                            value: String(format: "%.1f", snapshot.sleepHours),
                            unit: "h",
                            color: WatchTheme.indigo
                        )
                        dualCallout(
                            label: "Eff",
                            value: "\(Int((snapshot.sleepEfficiency * 100).rounded()))",
                            unit: "%",
                            color: WatchTheme.teal
                        )
                    }
                    .padding(.top, 6)

                    if snapshot.sleepScore > 0 {
                        Text("Sleep \(snapshot.sleepScore)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WatchTheme.scoreColor(snapshot.sleepScore))
                    }

                    // Stacked stage bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchTheme.purple)
                                .frame(width: max(0, geo.size.width * snapshot.deepSleepPercent))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchTheme.indigo)
                                .frame(width: max(0, geo.size.width * snapshot.remSleepPercent))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchTheme.teal.opacity(0.6))
                                .frame(width: max(0, geo.size.width * lightPercent))
                        }
                    }
                    .frame(height: 10)

                    // Clearer stage legend (capsule + label + %)
                    HStack(spacing: 8) {
                        stageLegend(
                            color: WatchTheme.purple,
                            title: "Deep",
                            percent: Int((snapshot.deepSleepPercent * 100).rounded())
                        )
                        stageLegend(
                            color: WatchTheme.indigo,
                            title: "REM",
                            percent: Int((snapshot.remSleepPercent * 100).rounded())
                        )
                        stageLegend(
                            color: WatchTheme.teal,
                            title: "Core",
                            percent: Int((lightPercent * 100).rounded())
                        )
                    }

                    // Glance freshness from existing WatchSnapshot.date (Honest #52).
                    WatchGlanceUpdatedCue(date: snapshot.date)

                    Text("Sleep")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    WatchMetricRow(
                        icon: "gauge.with.dots.needle.67percent",
                        label: "Efficiency",
                        value: "\(Int((snapshot.sleepEfficiency * 100).rounded()))%",
                        color: WatchTheme.indigo
                    )
                    WatchMetricRow(
                        icon: "moon.fill",
                        label: "Deep",
                        value: "\(Int((snapshot.deepSleepPercent * 100).rounded()))%",
                        color: WatchTheme.purple
                    )
                    WatchMetricRow(
                        icon: "brain.head.profile",
                        label: "REM",
                        value: "\(Int((snapshot.remSleepPercent * 100).rounded()))%",
                        color: WatchTheme.indigo
                    )
                    WatchMetricRow(
                        icon: "moon.zzz.fill",
                        label: "Core",
                        value: "\(Int((lightPercent * 100).rounded()))%",
                        color: WatchTheme.teal
                    )
                }
                .padding(.horizontal)
            } else {
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 60)
            }
        }
    }

    private func dualCallout(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .monospacedDigit()
                Text(unit)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
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
                    .foregroundStyle(.secondary)
                Text("\(percent)%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    WatchSleepView()
        .environmentObject(WatchSessionManager.shared)
}
