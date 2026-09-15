import SwiftUI

/// Page 1: Fitness-style Gym/Work/Sleep rings, HRV|RHR vitals callout, morning check-in shortcut.
struct WatchDashboardView: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        ScrollView {
            if let snapshot = session.snapshot {
                VStack(spacing: 10) {
                    CompactTripleRingsView(
                        gymScore: snapshot.gymScore,
                        workScore: snapshot.workScore,
                        sleepScore: snapshot.sleepScore,
                        size: 110,
                        minimumLineWidth: 5,
                        gap: 2,
                        valueColor: .white,
                        captionColor: Color.secondary
                    )
                    .padding(.top, 4)

                    // Elevated vitals: HRV|RHR dual callout from existing snapshot fields.
                    HStack(spacing: 12) {
                        dualCallout(
                            label: "HRV",
                            value: "\(Int(snapshot.hrv))",
                            unit: "ms",
                            color: WatchTheme.green
                        )
                        dualCallout(
                            label: "RHR",
                            value: "\(Int(snapshot.restingHeartRate))",
                            unit: "bpm",
                            color: WatchTheme.red
                        )
                    }

                    // Readiness + recovery cue when space allows (existing fields only).
                    HStack(spacing: 6) {
                        Text(WatchTheme.readinessLabel(snapshot.readiness))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WatchTheme.scoreColor(snapshot.readiness))
                        Text("·")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text("Recovery \(snapshot.recovery)%")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(WatchTheme.scoreColor(snapshot.recovery))
                            .monospacedDigit()
                    }

                    Text("Readiness")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !snapshot.checkedInMorning {
                        NavigationLink {
                            WatchCheckInView()
                        } label: {
                            Label("Check-in", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(WatchTheme.orange)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
            } else {
                emptyState
            }
        }
        .containerBackground(.black, for: .navigation)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open Readiness on your iPhone to sync")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                session.requestSnapshot()
            }
            .font(.caption)
        }
        .padding()
        .padding(.top, 24)
    }
}

#Preview {
    WatchDashboardView()
        .environmentObject(WatchSessionManager.shared)
}
