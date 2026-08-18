import SwiftUI
import UserNotifications

/// Settings screen for smart notifications: master switch, per-type toggles,
/// delivery times, and quiet hours.
///
/// Changes persist via UserSettings and trigger an immediate reschedule in
/// NotificationManager. Designed to be pushed from SettingsView — embed in a
/// NavigationLink, e.g. `NavigationLink("Notifications") { NotificationSettingsView() }`.
struct NotificationSettingsView: View {
    @State private var settings = UserSettings.load().notifications
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Form {
            masterSection
            if settings.notificationsEnabled {
                morningSummarySection
                lowRecoverySection
                bedtimeReminderSection
                quietHoursSection
            }
        }
        .navigationTitle("Notifications")
        .task {
            authorizationStatus = await NotificationManager.shared.authorizationStatus()
        }
        .onChange(of: settings) { _ in
            persist()
            Task { await NotificationManager.shared.rescheduleAll() }
        }
        .onChange(of: settings.notificationsEnabled) { enabled in
            guard enabled else { return }
            Task {
                await NotificationManager.shared.requestAuthorizationIfNeeded()
                authorizationStatus = await NotificationManager.shared.authorizationStatus()
            }
        }
    }

    // MARK: - Sections

    private var masterSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $settings.notificationsEnabled)

            if authorizationStatus == .denied {
                Label("Notifications are turned off in system Settings.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(RTColor.caution)
                Button("Open System Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
            }
        } footer: {
            Text("Smart alerts for your morning readiness, low recovery days, and bedtime.")
        }
    }

    private var morningSummarySection: some View {
        Section {
            Toggle("Morning Summary", isOn: $settings.morningSummaryEnabled)
            if settings.morningSummaryEnabled {
                DatePicker(
                    "Delivery Time",
                    selection: timeBinding(hour: \.morningSummaryHour, minute: \.morningSummaryMinute),
                    displayedComponents: .hourAndMinute
                )
            }
        } footer: {
            Text("Daily readiness score and zone after you wake up.")
        }
    }

    private var lowRecoverySection: some View {
        Section {
            Toggle("Low Recovery Warning", isOn: $settings.lowRecoveryEnabled)
            if settings.lowRecoveryEnabled {
                Stepper(
                    "Below baseline by \(settings.lowRecoveryThreshold) pts",
                    value: $settings.lowRecoveryThreshold,
                    in: 5...40,
                    step: 5
                )
            }
        } footer: {
            Text("Alerts you when today's readiness drops well below your 14-day baseline.")
        }
    }

    private var bedtimeReminderSection: some View {
        Section {
            Toggle("Bedtime Reminder", isOn: $settings.bedtimeReminderEnabled)
            if settings.bedtimeReminderEnabled {
                Stepper(
                    "\(settings.bedtimeReminderLeadMinutes) min before bed",
                    value: $settings.bedtimeReminderLeadMinutes,
                    in: 15...120,
                    step: 15
                )
            }
        } footer: {
            if let bedtime = NotificationManager.typicalBedtimeMinutes(from: DataStore.shared.history) {
                Text("Based on your typical bedtime of \(formattedMinutes(bedtime)).")
            } else {
                Text("Needs a few nights of sleep data to learn your typical bedtime.")
            }
        }
    }

    private var quietHoursSection: some View {
        Section {
            Toggle("Quiet Hours", isOn: $settings.quietHoursEnabled)
            if settings.quietHoursEnabled {
                Picker("From", selection: $settings.quietHoursStartHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formattedMinutes(hour * 60)).tag(hour)
                    }
                }
                Picker("Until", selection: $settings.quietHoursEndHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(formattedMinutes(hour * 60)).tag(hour)
                    }
                }
            }
        } footer: {
            Text("Notifications scheduled inside quiet hours are silenced.")
        }
    }

    // MARK: - Helpers

    private func persist() {
        var userSettings = UserSettings.load()
        userSettings.notifications = settings
        userSettings.save()
    }

    /// Bridges the stored hour/minute ints to a Date for DatePicker.
    private func timeBinding(
        hour: WritableKeyPath<UserSettings.NotificationSettings, Int>,
        minute: WritableKeyPath<UserSettings.NotificationSettings, Int>
    ) -> Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = settings[keyPath: hour]
                components.minute = settings[keyPath: minute]
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                settings[keyPath: hour] = components.hour ?? 0
                settings[keyPath: minute] = components.minute ?? 0
            }
        )
    }

    /// Formats minutes-from-midnight as a local time string, e.g. "10:30 PM".
    private func formattedMinutes(_ minutes: Int) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
