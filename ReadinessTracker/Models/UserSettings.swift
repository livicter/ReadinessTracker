import Foundation

/// User-configurable app settings persisted to UserDefaults
struct UserSettings: Codable {
    /// Hour (0-23) that marks the start of a new "day" for sleep tracking.
    /// Default is 3 (3:00 AM) to accommodate late sleepers.
    /// Sleep that starts before this hour is counted toward the previous day.
    var dayStartHour: Int = 3
    
    /// Whether to use the custom day start hour (if false, uses midnight)
    var useCustomDayStart: Bool = true
    
    /// User age, used to estimate max heart rate if maxHeartRate is not set.
    var age: Int? = nil
    
    /// User-defined max heart rate. Falls back to 220 - age if nil.
    var maxHeartRate: Int? = nil
    
    /// Whether to apply a small recovery penalty when menstrual flow is reported.
    var trackMenstrualCycle: Bool = false
    
    static let `default` = UserSettings()
    
    private static let key = "com.readinesstracker.usersettings"
    
    static func load() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

// MARK: - Day Boundary Helpers

extension UserSettings {
    /// Returns the effective day start hour (0-23)
    var effectiveDayStartHour: Int {
        useCustomDayStart ? dayStartHour : 0
    }
    
    /// Given a date, returns the "logical day" start boundary.
    /// If the time is before dayStartHour, the logical day started on the previous calendar day.
    func logicalDayStart(for date: Date, calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        let startHour = effectiveDayStartHour
        
        // Get start of the calendar day
        let calendarDayStart = calendar.startOfDay(for: date)
        
        if hour >= startHour {
            // Current logical day started today at dayStartHour
            return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: calendarDayStart) ?? calendarDayStart
        } else {
            // Current logical day started yesterday at dayStartHour
            let yesterday = calendar.date(byAdding: .day, value: -1, to: calendarDayStart) ?? calendarDayStart
            return calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: yesterday) ?? yesterday
        }
    }
    
    /// Given a date, returns the end of its logical day (start of next logical day)
    func logicalDayEnd(for date: Date, calendar: Calendar = .current) -> Date {
        let dayStart = logicalDayStart(for: date, calendar: calendar)
        return calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
    }
    
    /// Checks if two dates fall within the same logical day
    func isSameLogicalDay(_ date1: Date, _ date2: Date, calendar: Calendar = .current) -> Bool {
        logicalDayStart(for: date1, calendar: calendar) == logicalDayStart(for: date2, calendar: calendar)
    }
    
    /// Returns the display date for a logical day (the calendar day that the logical day mostly occupies)
    func displayDate(for date: Date, calendar: Calendar = .current) -> Date {
        let hour = calendar.component(.hour, from: date)
        let startHour = effectiveDayStartHour
        let calendarDayStart = calendar.startOfDay(for: date)
        
        if hour >= startHour {
            return calendarDayStart
        } else {
            // Before day start — this logical day started yesterday, but we display it as yesterday's date
            return calendar.date(byAdding: .day, value: -1, to: calendarDayStart) ?? calendarDayStart
        }
    }
}

// MARK: - Heart Rate

extension UserSettings {
    var estimatedMaxHeartRate: Int {
        maxHeartRate ?? (age.map { 220 - $0 } ?? 190)
    }
}
