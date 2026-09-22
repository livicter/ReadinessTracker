import SwiftUI
import UserNotifications

/// Settings screen for smart notifications: master switch, per-type toggles,
/// delivery times, and quiet hours.
///
/// Changes persist via UserSettings and trigger an immediate reschedule in
/// NotificationManager. Designed to be pushed from SettingsView — embed in a
/// NavigationLink, e.g. `NavigationLink("Notifications") { NotificationSettingsView() }`.
/// Honest #62: Apple Settings chrome — tinted SF Symbol wells beside each row.
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
        .navigationBarTitleDisplayMode(.large)
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
            Toggle(isOn: $settings.notificationsEnabled) {
                settingsLabel(
                    icon: "bell.fill",
                    color: Color(hex: "34C759"),
                    title: "Allow Notifications"
                )
            }
            .accessibilityIdentifier("settings.notifications.master")

            if authorizationStatus == .denied {
                Label(
                    "Notifications are turned off in system Settings.",
                    systemImage: "exclamationmark.triangle.fill"
                )
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
            Text("Morning readiness, low-recovery days, and bedtime — paused during Quiet Hours.")
        }
    }

    private var morningSummarySection: some View {
        Section {
            Toggle(isOn: $settings.morningSummaryEnabled) {
                settingsLabel(
                    icon: "sun.horizon.fill",
                    color: Color(hex: "FF9F0A"),
                    title: "Morning Summary",
                    subtitle: "Readiness score after you wake"
                )
            }
            .accessibilityIdentifier("settings.notifications.morning")
            if settings.morningSummaryEnabled {
                DatePicker(
                    "Time",
                    selection: timeBinding(hour: \.morningSummaryHour, minute: \.morningSummaryMinute),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var lowRecoverySection: some View {
        Section {
            Toggle(isOn: $settings.lowRecoveryEnabled) {
                settingsLabel(
                    icon: "heart.fill",
                    color: Color(hex: "FF375F"),
                    title: "Low Recovery Warning",
                    subtitle: "When readiness drops below baseline"
                )
            }
            .accessibilityIdentifier("settings.notifications.recovery")
            if settings.lowRecoveryEnabled {
                Stepper(
                    "Below baseline by \(settings.lowRecoveryThreshold) pts",
                    value: $settings.lowRecoveryThreshold,
                    in: 5...40,
                    step: 5
                )
            }
        }
    }

    private var bedtimeReminderSection: some View {
        Section {
            Toggle(isOn: $settings.bedtimeReminderEnabled) {
                settingsLabel(
                    icon: "moon.fill",
                    color: Color(hex: "BF5AF2"),
                    title: "Bedtime Reminder",
                    subtitle: bedtimeSubtitle
                )
            }
            .accessibilityIdentifier("settings.notifications.bedtime")
            if settings.bedtimeReminderEnabled {
                Stepper(
                    "\(settings.bedtimeReminderLeadMinutes) min before bed",
                    value: $settings.bedtimeReminderLeadMinutes,
                    in: 15...120,
                    step: 15
                )
            }
        }
    }

    private var quietHoursSection: some View {
        Section {
            Toggle(isOn: $settings.quietHoursEnabled) {
                settingsLabel(
                    icon: "moon.zzz.fill",
                    color: Color(hex: "64D2FF"),
                    title: "Quiet Hours",
                    subtitle: "Silence scheduled alerts"
                )
            }
            .accessibilityIdentifier("settings.notifications.quiet")
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
            Text("Alerts scheduled inside Quiet Hours are held until they end.")
        }
    }

    private var bedtimeSubtitle: String {
        if let bedtime = NotificationManager.typicalBedtimeMinutes(from: DataStore.shared.history) {
            return "Typical bedtime \(formattedMinutes(bedtime))"
        }
        return "Learns from a few nights of sleep"
    }

    // MARK: - Row chrome

    @ViewBuilder
    private func settingsLabel(
        icon: String,
        color: Color,
        title: String,
        subtitle: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            AppIconTile(systemName: icon, color: color, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(RTColor.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
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
