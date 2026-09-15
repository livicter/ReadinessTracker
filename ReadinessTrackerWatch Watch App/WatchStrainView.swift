import SwiftUI

/// Page 2: WHOOP dual-arc Recovery (inner) / Strain (outer) plus elevated Recovery|Strain callout.
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
                        day: dayCue(for: snapshot.date),
                        minimumOuterWidth: 8,
                        minimumInnerWidth: 6,
                        trackColor: Color.white.opacity(0.18),
                        valueColor: .white,
                        captionColor: Color.white.opacity(0.55)
                    )
                    .padding(.top, 4)

                    // Elevated secondary glance: Recovery % | Strain /21 from WatchSnapshot only.
                    HStack(spacing: 12) {
                        dualCallout(
                            label: "Recovery",
                            value: "\(snapshot.recovery)",
                            unit: "%",
                            color: WatchTheme.lightGreen
                        )
                        dualCallout(
                            label: "Strain",
                            value: String(format: "%.1f", snapshot.strain),
                            unit: "/21",
                            color: WatchTheme.orange
                        )
                    }

                    // Day + Updated cues from snapshot.date (existing field only; Honest #52).
                    Text(dayLabel(for: snapshot.date))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    WatchGlanceUpdatedCue(date: snapshot.date)

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

    private func dayCue(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "TODAY"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE"
        return f.string(from: date).uppercased()
    }

    private func dayLabel(for date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }
}

#Preview {
    WatchStrainView()
        .environmentObject(WatchSessionManager.shared)
}
