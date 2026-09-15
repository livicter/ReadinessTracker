import SwiftUI

#if os(iOS)
/// Audit chrome mirroring Watch `WatchCheckInView` (Morning|Evening + stars + habit toggles).
struct WatchCheckInChrome: View {
    var timeOfDay: String = "Morning"
    var feel: Int = 4
    var alcohol: Bool = false
    var lateCaffeine: Bool = true
    var sick: Bool = false
    var workoutToday: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                periodChip("Morning", selected: timeOfDay == "Morning")
                periodChip("Evening", selected: timeOfDay == "Evening")
            }
            .padding(2)
            .background(Color.white.opacity(0.12), in: Capsule())

            Text("How do you feel?")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= feel ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundStyle(i <= feel ? Color.yellow : Color.white.opacity(0.35))
                }
            }

            VStack(spacing: 8) {
                chromeToggle(title: "Alcohol", on: alcohol)
                chromeToggle(title: "Late caffeine", on: lateCaffeine)
                chromeToggle(title: "Sick", on: sick)
                if timeOfDay == "Evening" {
                    chromeToggle(title: "Workout today", on: workoutToday)
                }
            }

            Text("Save")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green, in: Capsule())
                .padding(.top, 4)

            Text("Check-in · \(timeOfDay)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(16)
        .frame(width: 184, height: 280)
        .background(Color.black)
    }

    private func periodChip(_ title: String, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(selected ? .black : Color.white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selected ? Color.white : Color.clear, in: Capsule())
    }

    private func chromeToggle(title: String, on: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
            Spacer()
            Capsule()
                .fill(on ? Color.green : Color.white.opacity(0.22))
                .frame(width: 28, height: 16)
                .overlay(alignment: on ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 12, height: 12)
                        .padding(2)
                }
        }
    }
}
#endif
