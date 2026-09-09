import SwiftUI

/// Page 1: Fitness-style Gym/Work/Sleep rings, key vitals, morning check-in shortcut.
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

                    Text("Readiness")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    WatchMetricRow(
                        icon: "waveform.path.ecg",
                        label: "HRV",
                        value: "\(Int(snapshot.hrv)) ms",
                        color: WatchTheme.green
                    )
                    WatchMetricRow(
                        icon: "heart.fill",
                        label: "RHR",
                        value: "\(Int(snapshot.restingHeartRate)) bpm",
                        color: WatchTheme.red
                    )
                    WatchMetricRow(
                        icon: "lungs.fill",
                        label: "Recovery",
                        value: "\(snapshot.recovery)%",
                        color: WatchTheme.scoreColor(snapshot.recovery)
                    )

                    if !snapshot.checkedInMorning {
                        NavigationLink {
                            WatchCheckInView()
                        } label: {
                            Label("Check-in", systemImage: "sunrise.fill")
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
