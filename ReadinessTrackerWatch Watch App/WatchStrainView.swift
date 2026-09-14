import SwiftUI

/// Page 2: WHOOP dual-arc Recovery (inner) / Strain (outer) plus activity summary.
struct WatchStrainView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        ScrollView {
            if let snapshot = session.snapshot {
                VStack(spacing: 10) {
                    CompactStrainRecoveryWheel(
                        strainScore: snapshot.strain,
                        recoveryScore: Double(snapshot.recovery),
                        size: 110,
                        day: "TODAY",
                        minimumOuterWidth: 8,
                        minimumInnerWidth: 6,
                        trackColor: Color.white.opacity(0.18),
                        valueColor: .white,
                        captionColor: Color.white.opacity(0.55)
                    )
                    .padding(.top, 4)

                    HStack(spacing: 14) {
                        watchLegend(
                            color: WatchTheme.lightGreen,
                            title: "Recovery",
                            value: "\(snapshot.recovery)",
                            unit: "%"
                        )
                        watchLegend(
                            color: WatchTheme.orange,
                            title: "Strain",
                            value: String(format: "%.1f", snapshot.strain),
                            unit: "/21"
                        )
                    }

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

    private func watchLegend(color: Color, title: String, value: String, unit: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(color)
                .frame(width: 3, height: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(value)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(color)
                        .monospacedDigit()
                    Text(unit)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

#Preview {
    WatchStrainView()
        .environmentObject(WatchSessionManager.shared)
}
