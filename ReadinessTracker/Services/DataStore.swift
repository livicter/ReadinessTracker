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
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: key)
        }
        
        // Update widget data
        updateWidgetData()
    }
    
    private func updateWidgetData() {
        guard let latest = history.first else { return }
        let source = latest.source
        let history30 = dataForSource(source, days: 30)
        let breakdown = ReadinessCalculator.calculateBreakdown(from: latest, history: history30)
        let metadata = MetadataStore.shared.metadataFor(date: Date(), timeOfDay: .morning)
        let dualScores = ReadinessCalculator.calculateDualScores(from: latest, history: history30, metadata: metadata)
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.readinesstracker")
        sharedDefaults?.set(dualScores.general, forKey: "readinessScore")
        sharedDefaults?.set(dualScores.gym, forKey: "gymScore")
        sharedDefaults?.set(dualScores.cognitive, forKey: "workScore")
        sharedDefaults?.set(breakdown.sleepScore, forKey: "sleepScore")
        sharedDefaults?.set(latest.hrv, forKey: "hrv")
        sharedDefaults?.set(latest.restingHeartRate, forKey: "rhr")
        sharedDefaults?.set(latest.sleepHours, forKey: "sleepHours")
        sharedDefaults?.set(Date(), forKey: "lastUpdate")
        
        WidgetCenter.shared.reloadTimelines(ofKind: "ReadinessTrackerWidget")
    }
}
