import SwiftUI

/// Page 2: day strain gauge plus activity summary.
struct WatchStrainView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        ScrollView {
            if let snapshot = session.snapshot {
                VStack(spacing: 10) {
                    ZStack {
                        ScoreRing(value: snapshot.strain / 21.0,
                                  color: WatchTheme.strainColor(snapshot.strain))
                        VStack(spacing: 0) {
                            Text(String(format: "%.1f", snapshot.strain))
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(WatchTheme.strainColor(snapshot.strain))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text(WatchTheme.strainLabel(snapshot.strain).uppercased())
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .padding(.top, 4)

                    Text("Strain")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    WatchMetricRow(
                        icon: "flame.fill",
                        label: "Active",
                        value: "\(Int(snapshot.activeCalories)) cal",
                        color: WatchTheme.orange
                    )
                    WatchMetricRow(
                        icon: "figure.walk",
                        label: "Steps",
                        value: "\(snapshot.steps)",
                        color: WatchTheme.teal
                    )
                    WatchMetricRow(
                        icon: "dumbbell.fill",
                        label: "Workout",
                        value: "\(snapshot.workoutMinutes) min",
                        color: WatchTheme.purple
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
    WatchStrainView()
        .environmentObject(WatchSessionManager.shared)
}
