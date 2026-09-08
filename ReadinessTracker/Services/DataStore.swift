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

    /// UserDefaults key shared with `JournalView` / `AIRecommendations`.
    static let journalEntriesKey = "journal_entries"

    @MainActor
    static func installIfRequested() {
        guard isRequested else { return }
        DataStore.shared.seedUIFixture()
        seedJournalEntries()
        HealthKitManager.shared.dataSource = "Whoop"
        HealthKitManager.shared.isAuthorized = true
        HealthKitManager.shared.errorMessage = nil
    }

    /// Seeds ≥7 journal entries so JournalView shows Behavior Impact (not the “Log 7 days” empty strip).
    /// Real users with fewer than 7 entries still see that strip — fixture-only.
    static func seedJournalEntries() {
        let entries = journalEntries()
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: journalEntriesKey)
        }
    }

    /// Habit ↔ readiness rows for the impact chart under `-ui-fixture`.
    /// Varied behaviors + scores so alcohol/stress sit below overall avg and recovery habits above.
    static func journalEntries() -> [JournalEntry] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // (daysAgo, behaviors, notes, readinessScore)
        let specs: [(Int, [JournalEntryView.Behavior], String, Int)] = [
            (7, [.alcohol], "Fixture: drinks after dinner", 48),
            (6, [.caffeineLate, .screenTime], "Fixture: late coffee + phone", 55),
            (5, [.meditation], "Fixture: evening sit", 82),
            (4, [.alcohol, .stress], "Fixture: stress + drinks", 42),
            (3, [.sauna], "Fixture: post-workout heat", 78),
            (2, [.iceBath, .meditation], "Fixture: cold + calm", 88),
            (1, [.screenTime], "Fixture: late scrolling", 60),
            (0, [.massage], "Fixture: recovery day", 80),
        ]
        return specs.map { daysAgo, behaviors, notes, score in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: today)!
            return JournalEntry(date: date, behaviors: behaviors, notes: notes, readinessScore: score)
        }
    }

    static func history() -> [DailyHealthData] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let previous = cal.date(byAdding: .day, value: -1, to: date)!
            let sleepStart = cal.date(bySettingHour: 23, minute: 5 + (offset % 3), second: 0, of: previous)!
            let sleepEnd = cal.date(bySettingHour: 7, minute: 10 + (offset % 4), second: 0, of: date)!
            let stages = coherentSleepStages(sleepStart: sleepStart, sleepEnd: sleepEnd)
            // Single source of truth: disturbance count matches awake periods in stages
            // (Today "N disturbance(s)" and DayDetail/SleepAnalysis hypnogram stay coherent).
            let wakeEpisodes = SleepCycleDetector.awakePeriods(from: stages).count
            return DailyHealthData(
                date: date,
                source: .appleWatch,
                sleepHours: 7.4,
                sleepEfficiency: 0.90,
                deepSleepPercent: 0.17,
                remSleepPercent: 0.21,
                sleepStartTime: sleepStart,
                sleepEndTime: sleepEnd,
                wakeEpisodes: wakeEpisodes,
                sleepStages: stages,
                // Vary older nights so Sleep HRV 7-night spark / chart show real shape; today stays 58.
                hrv: offset == 0 ? 58 : 48 + Double((offset * 7) % 21),
                hrvIsRMSSD: true,
                restingHeartRate: 54,
                // Vary older days so Body tiles show real sparklines; today stays glance-stable.
                activeCalories: offset == 0 ? 420 : 280 + Double((offset * 53) % 280),
                steps: offset == 0 ? 8200 : 5500 + ((offset * 917) % 4500),
                workoutMinutes: offset == 0 ? 42 : 15 + ((offset * 11) % 45),
                skinTemperature: 36.4,
                respiratoryRate: 15.2,
                bloodOxygen: 97,
                nutrition: NutritionSummary(waterLiters: 2.1, caffeineMg: 90, proteinGrams: 95)
            )
        }
    }

    /// Fixture hypnogram night: contiguous stages from bed to wake with exactly one mid-sleep awake.
    /// Keeps Today disturbance count aligned with `SleepCycleDetector.awakePeriods` / HypnogramView.
    static func coherentSleepStages(sleepStart: Date, sleepEnd: Date) -> [SleepStageInterval] {
        let total = sleepEnd.timeIntervalSince(sleepStart)
        guard total >= 60 * 60 else { return [] }

        func at(_ fraction: Double) -> Date {
            sleepStart.addingTimeInterval(total * fraction)
        }

        // Proportions approximate a normal night; awake is short (~8 min on an 8h night)
        // and sits mid-sleep so HealthKit-style wake counting and awakePeriods both equal 1.
        return [
            SleepStageInterval(stage: .light, startDate: at(0.00), endDate: at(0.12)),
            SleepStageInterval(stage: .deep,  startDate: at(0.12), endDate: at(0.28)),
            SleepStageInterval(stage: .light, startDate: at(0.28), endDate: at(0.40)),
            SleepStageInterval(stage: .rem,   startDate: at(0.40), endDate: at(0.48)),
            SleepStageInterval(stage: .awake, startDate: at(0.48), endDate: at(0.50)),
            SleepStageInterval(stage: .light, startDate: at(0.50), endDate: at(0.62)),
            SleepStageInterval(stage: .deep,  startDate: at(0.62), endDate: at(0.72)),
            SleepStageInterval(stage: .rem,   startDate: at(0.72), endDate: at(0.88)),
            SleepStageInterval(stage: .light, startDate: at(0.88), endDate: at(1.00))
        ]
    }
}
