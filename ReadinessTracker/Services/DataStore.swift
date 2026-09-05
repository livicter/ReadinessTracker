import Foundation
import WidgetKit

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var history: [DailyHealthData] = []
    
    private let key = "readiness_history"
    private let defaults = UserDefaults(suiteName: "group.com.readinesstracker") ?? .standard
    
    private init() {
        load()
    }
    
    func save(_ data: DailyHealthData) {
        if let index = history.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: data.date) && $0.source == data.source }) {
            history[index] = data
        } else {
            history.append(data)
        }
        history.sort { $0.date > $1.date }
        persist()
    }
    
    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DailyHealthData].self, from: data) else {
            return
        }
        history = decoded.sorted { $0.date > $1.date }
    }
    
    func dataForSource(_ source: DataSource, days: Int = 30) -> [DailyHealthData] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date())!
        return history
            .filter { $0.source == source && $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }
    
    func latest(for source: DataSource) -> DailyHealthData? {
        history.first { $0.source == source }
    }
    
    /// Quick access to user's baselines for a given source
    func baselines(for source: DataSource) -> (hrv: Double, rhr: Double, sleep: Double) {
        let sourceHistory = dataForSource(source, days: 30)
        return (
            BaselineManager.hrvBaseline(from: sourceHistory),
            BaselineManager.rhrBaseline(from: sourceHistory),
            BaselineManager.sleepBaseline(from: sourceHistory)
        )
    }
    
    func exportCSV() -> String {
        var csv = "Date,Source,Sleep Hours,Sleep Efficiency,Deep %,REM %,HRV,RHR,Active Calories,Steps,Workout Minutes,Readiness Score,Morning Feel,Alcohol,Caffeine Late,Sick,Stressed,Workout Today,Workout RPE\n"
        for data in history {
            let meta = MetadataStore.shared.metadataFor(date: data.date, timeOfDay: .morning)
            csv += "\(data.date),\(data.source.rawValue),\(data.sleepHours),\(Int(data.sleepEfficiency * 100)),\(Int(data.deepSleepPercent * 100)),\(Int(data.remSleepPercent * 100)),\(data.hrv),\(data.restingHeartRate),\(data.activeCalories),\(data.steps),\(data.workoutMinutes),\(data.readinessScore),\(meta?.subjectiveFeel ?? 0),\(meta?.alcoholDrinks ?? 0),\(meta?.caffeineAfter2pm == true ? "Y" : "N"),\(meta?.isSick == true ? "Y" : "N"),\(meta?.isStressed == true ? "Y" : "N"),\(meta?.workoutToday == true ? "Y" : "N"),\(meta?.workoutRPE ?? 0)\n"
        }
        return csv
    }
    
    func seedUIFixture() {
        history = UIFixture.history()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: key)
        }

        // Widget + watch snapshots after every data write (health sync, check-in)
        WidgetDataExporter.export(from: self)
        WatchConnectivityManager.shared.pushSnapshot()
    }
}

enum UIFixture {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-fixture")
    }

    @MainActor
    static func installIfRequested() {
        guard isRequested else { return }
        DataStore.shared.seedUIFixture()
        HealthKitManager.shared.dataSource = "Whoop"
        HealthKitManager.shared.isAuthorized = true
        HealthKitManager.shared.errorMessage = nil
    }

    static func history() -> [DailyHealthData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let previous = cal.date(byAdding: .day, value: -1, to: date)!
            let sleepStart = cal.date(bySettingHour: 23, minute: 5 + (offset % 3), second: 0, of: previous)
            let sleepEnd = cal.date(bySettingHour: 7, minute: 10 + (offset % 4), second: 0, of: date)
            return DailyHealthData(
                date: date,
                source: .appleWatch,
                sleepHours: 7.4,
                sleepEfficiency: 0.90,
                deepSleepPercent: 0.17,
                remSleepPercent: 0.21,
                sleepStartTime: sleepStart,
                sleepEndTime: sleepEnd,
                wakeEpisodes: 1,
                hrv: 58,
                hrvIsRMSSD: true,
                restingHeartRate: 54,
                activeCalories: 420,
                steps: 8200,
                workoutMinutes: 42,
                skinTemperature: 36.4,
                respiratoryRate: 15.2,
                bloodOxygen: 97,
                nutrition: NutritionSummary(waterLiters: 2.1, caffeineMg: 90, proteinGrams: 95)
            )
        }
    }
}
