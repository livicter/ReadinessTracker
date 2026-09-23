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

        // Widget + watch snapshots after every health data write (Honest #43)
        WidgetExportAfterWrite.run(dataStore: self)
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
        MetadataStore.shared.seedUIFixtureCheckIns()
        // Google Health / Apple Health Cycle glance: show Cycle tile under -ui-fixture.
        var settings = UserSettings.load()
        settings.trackMenstrualCycle = true
        settings.save()
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
            (7, [.alcohol], "Drinks after dinner", 48),
            (6, [.caffeineLate, .screenTime], "Late coffee and phone", 55),
            (5, [.meditation], "Evening meditation", 82),
            (4, [.alcohol, .stress], "Stressful day with drinks", 42),
            (3, [.sauna], "Post-workout sauna", 78),
            (2, [.iceBath, .meditation], "Cold plunge and calm", 88),
            (1, [.screenTime], "Late night scrolling", 60),
            (0, [.massage], "Easy recovery day", 80),
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
            // Vary older-night bed/wake so Consistency dots/bars + spark show shape; today stays glance-stable.
            // Keep bed on previous evening (22:30–23:59) and wake on date morning (06:30–07:59).
            let sleepStart: Date
            let sleepEnd: Date
            if offset == 0 {
                sleepStart = cal.date(bySettingHour: 23, minute: 5, second: 0, of: previous)!
                sleepEnd = cal.date(bySettingHour: 7, minute: 10, second: 0, of: date)!
            } else {
                let bedTotal = 22 * 60 + 30 + ((offset * 17) % 90)   // 22:30 … 23:59
                let wakeTotal = 6 * 60 + 30 + ((offset * 11) % 90)   // 06:30 … 07:59
                sleepStart = cal.date(bySettingHour: bedTotal / 60, minute: bedTotal % 60, second: 0, of: previous)!
                sleepEnd = cal.date(bySettingHour: wakeTotal / 60, minute: wakeTotal % 60, second: 0, of: date)!
            }
            // Vary older nights so Wake Episodes 7-night spark has shape; today 1 wake (Calm).
            let wakeTarget = offset == 0 ? 1 : (offset % 4) // 1,2,3,0,1,...
            let stages = coherentSleepStages(sleepStart: sleepStart, sleepEnd: sleepEnd, wakeCount: wakeTarget)
            // Single source of truth: disturbance count matches awake periods in stages
            // (Today "N disturbance(s)" and DayDetail/SleepAnalysis hypnogram stay coherent).
            let wakeEpisodes = SleepCycleDetector.awakePeriods(from: stages).count
            let sleepHoursValue: Double = offset == 0 ? 7.4 : 6.2 + Double((offset * 13) % 25) * 0.1
            let sleepEfficiencyValue: Double = offset == 0 ? 0.91 : (0.78 + Double((offset * 5) % 17) * 0.01)
            // Stage-awake ÷ bed→wake window so Awake Hours spark follows wakeCount; today ~one short wake.
            var stageAwakeSeconds: TimeInterval = 0
            for interval in stages where interval.stage == .awake {
                stageAwakeSeconds += interval.endDate.timeIntervalSince(interval.startDate)
            }
            let bedWindowSeconds = sleepEnd.timeIntervalSince(sleepStart)
            let awakePercentValue: Double
            if bedWindowSeconds > 60 {
                awakePercentValue = min(0.35, max(0.01, stageAwakeSeconds / bedWindowSeconds))
            } else {
                awakePercentValue = 0.05
            }
            let deepSleepPercentValue: Double = offset == 0 ? 0.17 : (0.12 + Double((offset * 3) % 10) * 0.01)
            let remSleepPercentValue: Double = offset == 0 ? 0.21 : (0.16 + Double((offset * 5) % 12) * 0.01)
            // Vary older nights so Core Sleep 7-night spark has shape; today ~55% (Solid).
            let lightSleepPercentValue: Double = offset == 0 ? 0.55 : (0.42 + Double((offset * 4) % 16) * 0.01)
            let sleepOnsetMinutesValue: Double = offset == 0 ? 12 : (8 + Double((offset * 7) % 28))
            let hrvValue: Double = offset == 0 ? 58 : 48 + Double((offset * 7) % 21)
            // Peak HR (Honest #132): today 185; older days 155…184; rest-ish nil every 4th.
            let maxHRValue: Double? = {
                if offset == 0 { return 185 }
                if offset % 4 == 0 { return nil }
                return 155 + Double((offset * 7) % 30)
            }()
            // VO2 Max ml/kg/min (Honest #133). Sparse metric — most days have a reading.
            let vo2MaxValue: Double? = {
                if offset == 0 { return 48.5 }
                if offset % 5 == 0 { return nil }
                return 42.0 + Double((offset * 11) % 90) / 10.0 // 42.0…50.9
            }()
            // Walking HR average bpm (Honest #134). Simulator has no samples — seed for UI.
            let walkingHeartRateAverageValue: Double? = {
                if offset == 0 { return 98 }
                if offset % 4 == 0 { return nil }
                return 88 + Double((offset * 5) % 22) // 88…109
            }()
            // Environmental audio dBA (Honest #136). Simulator rarely has samples — seed for UI.
            let environmentalAudioExposureDBAValue: Double? = {
                if offset == 0 { return 62.0 }
                if offset % 4 == 0 { return nil }
                return 52.0 + Double((offset * 7) % 28) // 52…79
            }()
            // Headphone audio dBA (Honest #137). Simulator rarely has samples — seed for UI.
            let headphoneAudioExposureDBAValue: Double? = {
                if offset == 0 { return 68.0 }
                if offset % 5 == 0 { return nil }
                return 55.0 + Double((offset * 9) % 30) // 55…84
            }()
            // Environmental sound reduction dBA (Honest #138). Simulator rarely has ANC samples — seed for UI.
            let environmentalSoundReductionDBAValue: Double? = {
                if offset == 0 { return 18.0 }
                if offset % 5 == 0 { return nil }
                return 8.0 + Double((offset * 7) % 22) // 8…29
            }()
            // Time in daylight minutes (Honest #139). Simulator rarely has samples — seed for UI.
            let timeInDaylightMinutesValue: Double? = {
                if offset == 0 { return 95.0 }
                if offset % 5 == 0 { return nil }
                return 35.0 + Double((offset * 11) % 90) // 35…124
            }()
            // UV exposure index (Honest #140). Simulator rarely has samples — seed for UI.
            let uvExposureIndexValue: Double? = {
                if offset == 0 { return 4.5 }
                if offset % 5 == 0 { return nil }
                return 1.0 + Double((offset * 7) % 80) / 10.0 // 1.0…8.9
            }()
            // Flights climbed (Honest #141). Simulator often empty — seed for UI.
            let flightsClimbedValue: Double? = {
                if offset == 0 { return 12.0 }
                if offset % 5 == 0 { return nil }
                return 3.0 + Double((offset * 5) % 18) // 3…20
            }()
            // Walking/running distance km (Honest #142). Simulator often empty — seed for UI.
            let distanceWalkingRunningKmValue: Double? = {
                if offset == 0 { return 6.2 }
                if offset % 5 == 0 { return nil }
                return 2.0 + Double((offset * 13) % 80) / 10.0 // 2.0…9.9
            }()
            // Apple Exercise Time minutes (Honest #143). Simulator often empty — seed for UI.
            let appleExerciseTimeMinutesValue: Double? = {
                if offset == 0 { return 32.0 }
                if offset % 5 == 0 { return nil }
                return 10.0 + Double((offset * 7) % 40) // 10…49
            }()
            // Apple Stand Hours (Honest #144). Simulator often empty — seed for UI.
            let appleStandHoursValue: Double? = {
                if offset == 0 { return 10.0 }
                if offset % 5 == 0 { return nil }
                return 4.0 + Double((offset * 3) % 9) // 4…12
            }()
            // Walking double support % (Honest #145). Simulator often empty — seed for UI.
            let walkingDoubleSupportPercentValue: Double? = {
                if offset == 0 { return 27.5 }
                if offset % 5 == 0 { return nil }
                return 22.0 + Double((offset * 11) % 16) // 22…37
            }()
            // Walking asymmetry % (Honest #146). Simulator often empty — seed for UI. Lower is more symmetric.
            let walkingAsymmetryPercentValue: Double? = {
                if offset == 0 { return 2.4 }
                if offset % 5 == 0 { return nil }
                return 1.0 + Double((offset * 7) % 12) / 2.0 // 1.0…6.5
            }()
            let hrSamplesValue: [HRSample] = offset == 0 ? syntheticHRSamples(on: date) : []
            let activeCaloriesValue: Double = offset == 0 ? 420 : 280 + Double((offset * 53) % 280)
            let stepsValue: Int = offset == 0 ? 8200 : 5500 + ((offset * 917) % 4500)
            let workoutMinutesValue: Int = offset == 0 ? 60 : 15 + ((offset * 11) % 45)
            let rawSessions: [StrainSession] = Self.syntheticStrainSessions(on: date, offset: offset)
            let strainSessionsValue: [StrainSession] = StrainCalculator.enrichSessions(
                rawSessions,
                hrSamples: hrSamplesValue,
                restingHR: 54,
                maxHR: maxHRValue
            )
            let skinTemperatureValue: Double = offset == 0 ? 36.40 : 36.15 + Double((offset * 7) % 11) * 0.05
            let respiratoryRateValue: Double = offset == 0 ? 15.2 : 14.2 + Double((offset * 3) % 9) * 0.25
            let bloodOxygenValue: Double = offset == 0 ? 97.0 : 95.5 + Double((offset * 5) % 7) * 0.3
            return DailyHealthData(
                date: date,
                source: .appleWatch,
                // Vary older nights so Sleep Quality spark/bars show shape; today stays 7.4h.
                sleepHours: sleepHoursValue,
                // Vary older nights so Sleep Efficiency 7-night spark has shape; today ~91% (Excellent).
                sleepEfficiency: sleepEfficiencyValue,
                deepSleepPercent: deepSleepPercentValue,
                remSleepPercent: remSleepPercentValue,
                lightSleepPercent: lightSleepPercentValue,
                awakePercent: awakePercentValue,
                sleepOnsetMinutes: sleepOnsetMinutesValue,
                sleepStartTime: sleepStart,
                sleepEndTime: sleepEnd,
                wakeEpisodes: wakeEpisodes,
                sleepStages: stages,
                // Vary older nights so Sleep HRV 7-night spark / chart show real shape; today stays 58.
                hrv: hrvValue,
                hrvIsRMSSD: true,
                // Vary older nights so Resting HR 7-night spark has shape; today 54 bpm.
                restingHeartRate: offset == 0 ? 54 : (50 + Double((offset * 3) % 11)),
                // Vary older days so Body tiles show real sparklines; today stays glance-stable.
                activeCalories: activeCaloriesValue,
                steps: stepsValue,
                workoutMinutes: workoutMinutesValue,
                maxHeartRate: maxHRValue,
                hrSamples: hrSamplesValue,
                strainSessions: strainSessionsValue,
                // Vary older nights so RR / Skin Temp 7-night spark / chart show real shape; today stays glance-stable.
                skinTemperature: skinTemperatureValue,
                respiratoryRate: respiratoryRateValue,
                bloodOxygen: bloodOxygenValue,
                vo2Max: vo2MaxValue,
                walkingHeartRateAverage: walkingHeartRateAverageValue,
                environmentalAudioExposureDBA: environmentalAudioExposureDBAValue,
                headphoneAudioExposureDBA: headphoneAudioExposureDBAValue,
                environmentalSoundReductionDBA: environmentalSoundReductionDBAValue,
                timeInDaylightMinutes: timeInDaylightMinutesValue,
                uvExposureIndex: uvExposureIndexValue,
                flightsClimbed: flightsClimbedValue,
                distanceWalkingRunningKm: distanceWalkingRunningKmValue,
                appleExerciseTimeMinutes: appleExerciseTimeMinutesValue,
                appleStandHours: appleStandHoursValue,
                walkingDoubleSupportPercent: walkingDoubleSupportPercentValue,
                walkingAsymmetryPercent: walkingAsymmetryPercentValue,
                nutrition: NutritionSummary(
                    waterLiters: offset == 0 ? 2.1 : (1.4 + Double((offset * 7) % 12) * 0.1),
                    caffeineMg: offset == 0 ? 90 : (60 + Double((offset * 23) % 180)),
                    proteinGrams: offset == 0 ? 95 : (70 + Double((offset * 13) % 60))
                ),
                // Short flow streak so Cycle detail 14-day strip has shape (today + prior 2 days).
                menstrualFlow: offset <= 2
            )
        }
    }


    /// Daytime + workout HR progression so Recovery & Strain HR Zones render under -ui-fixture.
    static func syntheticHRSamples(on day: Date, resting: Double = 54, maxHR: Double = 185) -> [HRSample] {
        HRZoneAnalyzer.syntheticSamples(on: day, restingHR: resting, maxHR: maxHR, count: 120)
    }


    /// Fixture workouts aligned to synthetic HR peak window (07:30–08:30 Running today).
    static func syntheticStrainSessions(on day: Date, offset: Int) -> [StrainSession] {
        let cal = Calendar.current
        if offset == 0 {
            let start = cal.date(bySettingHour: 7, minute: 30, second: 0, of: day) ?? day
            let end = cal.date(bySettingHour: 8, minute: 30, second: 0, of: day) ?? day.addingTimeInterval(3600)
            return [
                StrainSession(workoutType: "Running", startDate: start, endDate: end)
            ]
        }
        // Older days: seed TRIMP so Daily TRIMP 7-day spark has shape (enrich preserves when no HR).
        if offset <= 6 {
            let start = cal.date(bySettingHour: 17 + (offset % 2), minute: (offset * 7) % 50, second: 0, of: day) ?? day
            let durationMin = 25 + ((offset * 11) % 40) // 25…64
            let end = start.addingTimeInterval(Double(durationMin) * 60)
            let types = ["Strength Training", "Cycling", "Running", "HIIT", "Yoga", "Walking"]
            let trimp = 40.0 + Double((offset * 17) % 80) // 40…119
            return [
                StrainSession(
                    workoutType: types[(offset - 1) % types.count],
                    startDate: start,
                    endDate: end,
                    trimp: trimp,
                    contribution: 0
                )
            ]
        }
        return []
    }

    /// Fixture hypnogram night: contiguous stages from bed to wake with `wakeCount` mid-sleep awakes.
    /// Keeps Today disturbance count aligned with `SleepCycleDetector.awakePeriods` / HypnogramView.
    /// Default `wakeCount: 1` preserves prior single-awake shape for callers/tests.
    static func coherentSleepStages(sleepStart: Date, sleepEnd: Date, wakeCount: Int = 1) -> [SleepStageInterval] {
        let total = sleepEnd.timeIntervalSince(sleepStart)
        guard total >= 60 * 60 else { return [] }

        func at(_ fraction: Double) -> Date {
            sleepStart.addingTimeInterval(total * fraction)
        }

        let wakes = max(0, min(3, wakeCount))
        // Short awake slices (~2% of night each) placed mid-cycle so awakePeriods == wakes.
        let wakeCenters: [Double]
        switch wakes {
        case 0: wakeCenters = []
        case 1: wakeCenters = [0.49]
        case 2: wakeCenters = [0.33, 0.66]
        default: wakeCenters = [0.25, 0.50, 0.75]
        }
        let half: Double = 0.01

        var cursor = 0.0
        let sleepCycle: [(SleepStage, Double)] = [
            (.light, 0.14), (.deep, 0.16), (.light, 0.12), (.rem, 0.10),
            (.light, 0.12), (.deep, 0.10), (.rem, 0.14), (.light, 0.12)
        ]
        // Build contiguous sleep, then splice awake windows at centers (overwrite sleep).
        var filled: [(SleepStage, Double, Double)] = [] // stage, startFrac, endFrac
        for (stage, dur) in sleepCycle {
            let end = min(1.0, cursor + dur)
            if end > cursor {
                filled.append((stage, cursor, end))
            }
            cursor = end
            if cursor >= 1.0 { break }
        }
        if let last = filled.last, last.2 < 1.0 {
            filled[filled.count - 1] = (last.0, last.1, 1.0)
        }

        // Split filled segments around awake windows.
        var result: [(SleepStage, Double, Double)] = []
        let awakeWindows = wakeCenters.map { ($0 - half, $0 + half) }
        for (stage, start, end) in filled {
            var pieces: [(SleepStage, Double, Double)] = [(stage, start, end)]
            for (a0, a1) in awakeWindows {
                var next: [(SleepStage, Double, Double)] = []
                for (st, s0, s1) in pieces {
                    if a1 <= s0 || a0 >= s1 {
                        next.append((st, s0, s1))
                    } else {
                        if a0 > s0 { next.append((st, s0, a0)) }
                        next.append((.awake, max(s0, a0), min(s1, a1)))
                        if a1 < s1 { next.append((st, a1, s1)) }
                    }
                }
                pieces = next
            }
            result.append(contentsOf: pieces)
        }

        // Merge adjacent same-stage fragments and drop empties.
        var merged: [(SleepStage, Double, Double)] = []
        for seg in result where seg.2 - seg.1 > 0.0001 {
            if let last = merged.last, last.0 == seg.0, abs(last.2 - seg.1) < 0.0001 {
                merged[merged.count - 1] = (last.0, last.1, seg.2)
            } else {
                merged.append(seg)
            }
        }

        return merged.map { SleepStageInterval(stage: $0.0, startDate: at($0.1), endDate: at($0.2)) }
    }
}
