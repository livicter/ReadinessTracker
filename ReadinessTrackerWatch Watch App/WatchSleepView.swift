import SwiftUI

/// Page 3: last-night sleep summary with stage breakdown.
struct WatchSleepView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        ScrollView {
            if let snapshot = session.snapshot {
                let lightPercent = max(0, 1 - snapshot.deepSleepPercent - snapshot.remSleepPercent)
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text(String(format: "%.1f h", snapshot.sleepHours))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(WatchTheme.indigo)
                        Text("Sleep")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Stacked stage bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchTheme.purple)
                                .frame(width: geo.size.width * snapshot.deepSleepPercent)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchTheme.indigo)
                                .frame(width: geo.size.width * snapshot.remSleepPercent)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(WatchTheme.teal.opacity(0.6))
                                .frame(width: geo.size.width * lightPercent)
                        }
                    }
                    .frame(height: 10)

                    Divider()

                    WatchMetricRow(
                        icon: "gauge.with.dots.needle.67percent",
                        label: "Efficiency",
                        value: "\(Int(snapshot.sleepEfficiency * 100))%",
                        color: WatchTheme.indigo
                    )
                    WatchMetricRow(
                        icon: "moon.fill",
                        label: "Deep",
                        value: "\(Int(snapshot.deepSleepPercent * 100))%",
                        color: WatchTheme.purple
                    )
                    WatchMetricRow(
                        icon: "brain.head.profile",
                        label: "REM",
                        value: "\(Int(snapshot.remSleepPercent * 100))%",
                        color: WatchTheme.indigo
                    )
                    WatchMetricRow(
                        icon: "moon.zzz.fill",
                        label: "Light",
                        value: "\(Int(lightPercent * 100))%",
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
}

#Preview {
    WatchSleepView()
        .environmentObject(WatchSessionManager.shared)
}
