import SwiftUI

/// Morning check-in made on the wrist; sent to the iPhone over WatchConnectivity.
struct WatchCheckInView: View {
    @EnvironmentObject private var session: WatchSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var feel = 3
    @State private var alcohol = false
    @State private var lateCaffeine = false
    @State private var sick = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("How do you feel?")
                    .font(.headline)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= feel ? "star.fill" : "star")
                            .foregroundStyle(i <= feel ? .yellow : .gray)
                            .onTapGesture { feel = i }
                    }
                }
                // Digital Crown adjusts the rating
                .focusable()
                .digitalCrownRotation(
                    Binding(
                        get: { Double(feel) },
                        set: { feel = min(5, max(1, Int($0.rounded()))) }
                    ),
                    from: 1, through: 5, by: 1
                )

                Toggle("Alcohol", isOn: $alcohol)
                    .font(.caption)
                Toggle("Late caffeine", isOn: $lateCaffeine)
                    .font(.caption)
                Toggle("Sick", isOn: $sick)
                    .font(.caption)

                Button {
                    session.sendCheckIn(
                        timeOfDay: "Morning",
                        subjectiveFeel: feel,
                        alcoholConsumed: alcohol,
                        caffeineAfter2pm: lateCaffeine,
                        isSick: sick,
                        workoutToday: false
                    ) { ok in
                        if ok { dismiss() }
                    }
                } label: {
                    Text(session.isPhoneReachable ? "Save" : "iPhone unreachable")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!session.isPhoneReachable)
                .padding(.top, 4)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Check-in")
    }
}

#Preview {
    WatchCheckInView()
        .environmentObject(WatchSessionManager.shared)
}
