import Foundation
import UserNotifications

/// Smart notification scheduling: morning readiness summary, low-recovery
/// warnings, and bedtime reminders derived from the user's sleep history.
///
/// Scheduling model: `rescheduleAll` clears all pending app notifications and
/// re-adds them from current settings + data. It runs on app launch, on every
/// background refresh, and whenever notification settings change. Morning and
/// bedtime reminders use repeating calendar triggers so they keep firing even
/// if the app is never opened again; their content is refreshed each time
/// `rescheduleAll` runs. The low-recovery warning is conditional, so it is a
/// one-shot scheduled only when today's score is well below baseline.
final class NotificationManager: NSObject {
    static let shared = NotificationManager()

    enum NotificationType: String, CaseIterable {
        case morningSummary = "morning-summary"
        case lowRecovery = "low-recovery"
        case bedtimeReminder = "bedtime-reminder"

        var identifier: String { "com.readinesstracker.notification.\(rawValue)" }
    }

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
        super.init()
    }

    /// Sets the notification center delegate (foreground presentation + quiet hours).
    /// Call once at app launch, before requesting authorization.
    func setUp() {
        center.delegate = self
    }

    // MARK: - Authorization

    /// Requests authorization if the user hasn't been asked yet.
    /// Returns whether notifications are authorized afterwards.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Rebuilds all pending notifications from current settings and data.
    func rescheduleAll() async {
        let history = await MainActor.run { DataStore.shared.history }
        await rescheduleAll(history: history)
    }

    func rescheduleAll(history: [DailyHealthData]) async {
        let settings = UserSettings.load().notifications
        guard settings.notificationsEnabled else {
            center.removeAllPendingNotificationRequests()
            return
        }
        guard await requestAuthorizationIfNeeded() else { return }

        let requests = Self.pendingRequests(settings: settings, history: history, now: Date())
        center.removeAllPendingNotificationRequests()
        for request in requests {
            try? await center.add(request)
        }
    }

    /// Pure scheduling core, separated from UNUserNotificationCenter for testability.
    /// `history` is expected newest-first (DataStore ordering).
    static func pendingRequests(
        settings: UserSettings.NotificationSettings,
        history: [DailyHealthData],
        now: Date,
        calendar: Calendar = .current
    ) -> [UNNotificationRequest] {
        var requests: [UNNotificationRequest] = []
        let sorted = history.sorted { $0.date > $1.date }
        let todayScore = sorted.first.map { ReadinessCalculator.calculate(from: $0) }

        // 1. Morning readiness summary — repeating daily at the configured time.
        if settings.morningSummaryEnabled,
           !isInQuietHours(hour: settings.morningSummaryHour, settings: settings) {
            let content = UNMutableNotificationContent()
            content.title = "Morning Readiness"
            if let score = todayScore {
                let zone = ScoreZone(score: score)
                content.body = "Readiness \(score) — \(zone.label). \(ReadinessCalculator.recommendation(for: score))"
            } else {
                content.body = "Open Readiness to see today's score."
            }
            content.sound = .default
            var components = DateComponents()
            components.hour = settings.morningSummaryHour
            components.minute = settings.morningSummaryMinute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            requests.append(UNNotificationRequest(
                identifier: NotificationType.morningSummary.identifier,
                content: content,
                trigger: trigger
            ))
        }

        // 2. Low-recovery warning — one-shot, only when today is well below baseline.
        if settings.lowRecoveryEnabled,
           let score = todayScore,
           isLowRecovery(todayScore: score, history: sorted, threshold: settings.lowRecoveryThreshold) {
            // Fire 15 minutes after the morning summary time; if that already
            // passed today, fire a minute from now instead.
            let morningToday = calendar.date(
                bySettingHour: settings.morningSummaryHour,
                minute: settings.morningSummaryMinute,
                second: 0,
                of: now
            )
            var fireDate = morningToday.flatMap { calendar.date(byAdding: .minute, value: 15, to: $0) }
            if fireDate == nil || fireDate! <= now {
                fireDate = now.addingTimeInterval(60)
            }
            guard let lowRecoveryFireDate = fireDate,
                  !isInQuietHours(hour: calendar.component(.hour, from: lowRecoveryFireDate), settings: settings) else {
                return requests
            }
            let baseline = readinessBaseline(from: sorted) ?? 0
            let content = UNMutableNotificationContent()
            content.title = "Low Recovery"
            content.body = "Readiness \(score) is \(Int(baseline) - score) points below your baseline. Prioritize rest today."
            content.sound = .default
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: lowRecoveryFireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            requests.append(UNNotificationRequest(
                identifier: NotificationType.lowRecovery.identifier,
                content: content,
                trigger: trigger
            ))
        }

        // 3. Bedtime reminder — repeating daily, lead time before typical bedtime.
        if settings.bedtimeReminderEnabled,
           let bedtime = typicalBedtimeMinutes(from: sorted) {
            let fireMinutes = (bedtime - settings.bedtimeReminderLeadMinutes + 1440) % 1440
            let fireHour = fireMinutes / 60
            if !isInQuietHours(hour: fireHour, settings: settings) {
                let sleepTarget = BaselineManager.sleepBaseline(from: sorted)
                let content = UNMutableNotificationContent()
                content.title = "Wind Down"
                content.body = "Bedtime in \(settings.bedtimeReminderLeadMinutes) min. Aim for \(String(format: "%.1f", sleepTarget))h of sleep tonight."
                content.sound = .default
                var components = DateComponents()
                components.hour = fireHour
                components.minute = fireMinutes % 60
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                requests.append(UNNotificationRequest(
                    identifier: NotificationType.bedtimeReminder.identifier,
                    content: content,
                    trigger: trigger
                ))
            }
        }

        return requests
    }

    // MARK: - Pure helpers (testable)

    /// Whether a given hour of day falls inside quiet hours. Handles wrap past midnight.
    static func isInQuietHours(hour: Int, settings: UserSettings.NotificationSettings) -> Bool {
        guard settings.quietHoursEnabled else { return false }
        let start = settings.quietHoursStartHour
        let end = settings.quietHoursEndHour
        if start == end { return false }
        if start < end {
            return hour >= start && hour < end
        }
        // Wraps midnight, e.g. 22:00-07:00
        return hour >= start || hour < end
    }

    /// Mean readiness score over recent history (14-day window), matching BaselineManager semantics.
    static func readinessBaseline(from history: [DailyHealthData], window: Int = 14) -> Double? {
        BaselineManager.baseline(for: history.map { Double(ReadinessCalculator.calculate(from: $0)) }, window: window)
    }

    /// True when today's readiness is `threshold` or more points below the baseline.
    static func isLowRecovery(todayScore: Int, history: [DailyHealthData], threshold: Int) -> Bool {
        guard let baseline = readinessBaseline(from: history) else { return false }
        return Double(todayScore) <= baseline - Double(threshold)
    }

    /// Typical bedtime in minutes from midnight (0-1439), averaged over recent
    /// sleep start times. Uses a noon-referenced mean so bedtimes either side
    /// of midnight average correctly. Returns nil with fewer than 3 samples.
    static func typicalBedtimeMinutes(from history: [DailyHealthData], window: Int = 14) -> Int? {
        let bedtimes = history.compactMap(\.sleepStartTime).suffix(window)
        guard bedtimes.count >= 3 else { return nil }
        let calendar = Calendar.current
        let minutes = bedtimes.map { date -> Int in
            let components = calendar.dateComponents([.hour, .minute], from: date)
            return (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
        // Shift reference to noon to avoid the midnight wrap skewing the mean.
        let shifted = minutes.map { ($0 - 720 + 1440) % 1440 }
        let mean = shifted.reduce(0, +) / shifted.count
        return (mean + 720) % 1440
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show banners even while the app is in the foreground, unless quiet hours are active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let settings = UserSettings.load().notifications
        let hour = Calendar.current.component(.hour, from: Date())
        if NotificationManager.isInQuietHours(hour: hour, settings: settings) {
            return []
        }
        return [.banner, .sound]
    }
}
