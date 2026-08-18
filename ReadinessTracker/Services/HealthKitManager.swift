import HealthKit
import Foundation

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var latestData: DailyHealthData?
    @Published var errorMessage: String?
    @Published var dataSource: String = "HealthKit"
    
    private init() {}
    
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async {
        guard isAvailable else {
            await MainActor.run {
                errorMessage = "HealthKit not available on this device"
            }
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKSeriesType.heartbeat(),
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                isAuthorized = true
            }
            await fetchTodayData()
        } catch {
            await MainActor.run {
                errorMessage = "HealthKit auth failed: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchTodayData() async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        async let hrvResult = fetchRMSSD(predicate: predicate)
        async let rhr = fetchRestingHR(predicate: predicate)
        async let calories = fetchActiveCalories(predicate: predicate)
        async let steps = fetchSteps(predicate: predicate)
        async let sleep = fetchSleepData(startOfDay: startOfDay)
        async let workouts = fetchWorkouts(startOfDay: startOfDay)
        async let respRate = fetchRespiratoryRate(predicate: predicate)
        async let spO2 = fetchBloodOxygen(predicate: predicate)
        async let skinTemp = fetchSkinTemperature(predicate: predicate)
        async let hrSamples = fetchHeartRateSamples(predicate: predicate)
        async let maxHR = fetchMaxHeartRate(predicate: predicate)
        async let nutrition = fetchNutrition(predicate: predicate)
        async let menstrualFlow = fetchMenstrualFlow(predicate: predicate)
        
        let rhrValue = await rhr
        let hrSamplesValue = await hrSamples
        let maxHRValue = await maxHR
        let workoutsValue = await workouts
        let appleWatchHistory = DataStore.shared.history.filter { $0.source == .appleWatch }
        let enrichedSessions = StrainCalculator.enrichSessions(
            workoutsValue,
            hrSamples: hrSamplesValue,
            restingHR: rhrValue,
            maxHR: maxHRValue,
            history: appleWatchHistory
        )
        
        let data = DailyHealthData(
            date: now,
            source: .appleWatch,
            sleepHours: await sleep.hours,
            sleepEfficiency: await sleep.efficiency,
            deepSleepPercent: await sleep.deepPercent,
            remSleepPercent: await sleep.remPercent,
            lightSleepPercent: await sleep.lightPercent,
            awakePercent: await sleep.awakePercent,
            sleepOnsetMinutes: await sleep.onsetMinutes,
            sleepStartTime: await sleep.sleepStart,
            sleepEndTime: await sleep.sleepEnd,
            wakeEpisodes: await sleep.wakeEpisodes,
            sleepStages: await sleep.intervals,
            hrv: await hrvResult.value,
            hrvIsRMSSD: await hrvResult.isRMSSD,
            restingHeartRate: rhrValue,
            activeCalories: await calories,
            steps: await steps,
            workoutMinutes: Int(workoutsValue.reduce(0) { $0 + $1.durationMinutes }),
            maxHeartRate: maxHRValue,
            hrSamples: hrSamplesValue,
            strainSessions: enrichedSessions,
            skinTemperature: await skinTemp,
            respiratoryRate: await respRate,
            bloodOxygen: await spO2,
            nutrition: await nutrition,
            menstrualFlow: await menstrualFlow
        )
        
        // Detect data source from HealthKit
        await detectDataSource()
        
        await MainActor.run {
            self.latestData = data
            DataStore.shared.save(data)
        }
    }
    
    /// Fetch historical data from HealthKit for the past N days
    /// This reads data that ALREADY EXISTS in Apple Health (e.g. from Apple Watch, other apps)
    func fetchHistoricalData(days: Int = 30) async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Fetch each day's data from HealthKit
        for dayOffset in (1...days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
            
            // Skip if we already have data for this day
            let existing = DataStore.shared.history.first {
                calendar.isDate($0.date, inSameDayAs: date) && $0.source == .appleWatch
            }
            guard existing == nil else { continue }
            
            async let hrvResult = fetchRMSSD(predicate: predicate)
            async let rhr = fetchRestingHR(predicate: predicate)
            async let calories = fetchActiveCalories(predicate: predicate)
            async let steps = fetchSteps(predicate: predicate)
            async let sleep = fetchSleepDataForDate(startOfDay: startOfDay, endOfDay: endOfDay)
            async let workouts = fetchWorkouts(startOfDay: startOfDay, endOfDay: endOfDay)
            async let hrSamples = fetchHeartRateSamples(predicate: predicate)
            async let maxHR = fetchMaxHeartRate(predicate: predicate)
            async let nutrition = fetchNutrition(predicate: predicate)
            async let menstrualFlow = fetchMenstrualFlow(predicate: predicate)
            
            let hrvValue = await hrvResult.value
            let hrvIsRMSSDValue = await hrvResult.isRMSSD
            let rhrValue = await rhr
            let calValue = await calories
            let stepsValue = await steps
            let sleepValue = await sleep
            let workoutsValue = await workouts
            let workoutMinutesValue = Int(workoutsValue.reduce(0) { $0 + $1.durationMinutes })
            let hrSamplesValue = await hrSamples
            let maxHRValue = await maxHR
            let nutritionValue = await nutrition
            let menstrualFlowValue = await menstrualFlow
            
            let appleWatchHistory = DataStore.shared.history.filter { $0.source == .appleWatch }
            let enrichedSessions = StrainCalculator.enrichSessions(
                workoutsValue,
                hrSamples: hrSamplesValue,
                restingHR: rhrValue,
                maxHR: maxHRValue,
                history: appleWatchHistory
            )
            
            // Only save if we have some meaningful data
            let hasData = hrvValue > 0 || rhrValue > 0 || calValue > 0 || stepsValue > 0 || sleepValue.hours > 0 || !hrSamplesValue.isEmpty || !nutritionValue.isEmpty || menstrualFlowValue
            guard hasData else { continue }
            
            let data = DailyHealthData(
                date: date,
                source: .appleWatch,
                sleepHours: sleepValue.hours,
                sleepEfficiency: sleepValue.efficiency,
                deepSleepPercent: sleepValue.deepPercent,
                remSleepPercent: sleepValue.remPercent,
                lightSleepPercent: sleepValue.lightPercent,
                awakePercent: sleepValue.awakePercent,
                sleepOnsetMinutes: sleepValue.onsetMinutes,
                sleepStartTime: sleepValue.sleepStart,
                sleepEndTime: sleepValue.sleepEnd,
                wakeEpisodes: sleepValue.wakeEpisodes,
                sleepStages: sleepValue.intervals,
                hrv: hrvValue,
                hrvIsRMSSD: hrvIsRMSSDValue,
                restingHeartRate: rhrValue,
                activeCalories: calValue,
                steps: stepsValue,
                workoutMinutes: workoutMinutesValue,
                maxHeartRate: maxHRValue,
                hrSamples: hrSamplesValue,
                strainSessions: enrichedSessions,
                nutrition: nutritionValue,
                menstrualFlow: menstrualFlowValue
            )
            
            await MainActor.run {
                DataStore.shared.save(data)
            }
        }
    }
    
    private func fetchHRV(predicate: NSPredicate) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0 }
        return await fetchMostRecentQuantity(type: type, predicate: predicate, unit: HKUnit.secondUnit(with: .milli)) ?? 0
    }
    
    private func fetchRestingHR(predicate: NSPredicate) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 60 }
        return await fetchMostRecentQuantity(type: type, predicate: predicate, unit: HKUnit.count().unitDivided(by: .minute())) ?? 60
    }
    
    private func fetchHeartRateSamples(predicate: NSPredicate) async -> [HRSample] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return [] }
        return await withCheckedContinuation { continuation in
            // Cap samples to avoid memory issues with dense Apple Watch HR data.
            // 2880 ≈ 2 samples/minute over 24h; enough for minute-level TRIMP.
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 2880, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                let hrsamples = samples.map {
                    HRSample(timestamp: $0.startDate, bpm: $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                }
                continuation.resume(returning: hrsamples)
            }
            self.healthStore.execute(query)
        }
    }
    
    private func fetchMaxHeartRate(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMax) { _, stats, _ in
                continuation.resume(returning: stats?.maximumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
            }
            self.healthStore.execute(query)
        }
    }

    private func fetchHeartbeatSeriesRRIntervals(predicate: NSPredicate) async -> [Double] {
        let seriesType = HKSeriesType.heartbeat()
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: seriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                guard let seriesSamples = samples as? [HKHeartbeatSeriesSample], let first = seriesSamples.first else {
                    continuation.resume(returning: [])
                    return
                }
                var rrIntervals: [Double] = []
                var previousTimeSeconds: TimeInterval?
                let query = HKHeartbeatSeriesQuery(heartbeatSeries: first) { _, timeSinceSampleStart, precededByGap, done, error in
                    let time = timeSinceSampleStart
                    if let previous = previousTimeSeconds, !precededByGap {
                        let rrMs = (time - previous) * 1000.0
                        rrIntervals.append(rrMs)
                    }
                    previousTimeSeconds = time
                    if done {
                        continuation.resume(returning: rrIntervals)
                    }
                }
                self.healthStore.execute(query)
            }
            self.healthStore.execute(query)
        }
    }

    private func fetchRMSSD(predicate: NSPredicate) async -> (value: Double, isRMSSD: Bool) {
        let rrIntervals = await fetchHeartbeatSeriesRRIntervals(predicate: predicate)
        if let rmssd = HRVCalculator.rmssd(from: rrIntervals), rmssd > 0 {
            return (rmssd, true)
        }
        let sdnn = await fetchHRV(predicate: predicate)
        return (sdnn, false)
    }

    private func fetchActiveCalories(predicate: NSPredicate) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .kilocalorie()) ?? 0
    }
    
    private func fetchSteps(predicate: NSPredicate) async -> Int {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        return Int(await fetchSumQuantity(type: type, predicate: predicate, unit: .count()) ?? 0)
    }
    
    /// Fetches sleep analysis with stage breakdown (iOS 16+)
    /// Falls back to basic asleep/awake for older data
    private func fetchSleepData(startOfDay: Date) async -> (
        hours: Double, efficiency: Double, deepPercent: Double, remPercent: Double,
        lightPercent: Double, awakePercent: Double, onsetMinutes: Double,
        sleepStart: Date?, sleepEnd: Date?, wakeEpisodes: Int, intervals: [SleepStageInterval]
    ) {
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return (0, 0, 0, 0, 0, 0, 15, nil, nil, 0, [])
        }
        return await fetchSleepDataForDate(startOfDay: startOfDay, endOfDay: endOfDay)
    }
    
    /// Fetch sleep data for a specific date range
    private func fetchSleepDataForDate(startOfDay: Date, endOfDay: Date) async -> (
        hours: Double, efficiency: Double, deepPercent: Double, remPercent: Double,
        lightPercent: Double, awakePercent: Double, onsetMinutes: Double,
        sleepStart: Date?, sleepEnd: Date?, wakeEpisodes: Int, intervals: [SleepStageInterval]
    ) {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return (0, 0, 0, 0, 0, 0, 15, nil, nil, 0, [])
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: (0, 0, 0, 0, 0, 0, 15, nil, nil, 0, []))
                    return
                }
                
                var totalSleepSeconds: TimeInterval = 0
                var deepSeconds: TimeInterval = 0
                var remSeconds: TimeInterval = 0
                var lightSeconds: TimeInterval = 0
                var awakeSeconds: TimeInterval = 0
                var inBedSeconds: TimeInterval = 0
                var wakeEpisodes = 0
                var wasAsleep = false
                var sleepEnd: Date? = nil
                var firstInBed: Date? = nil
                var firstAsleep: Date? = nil
                var intervals: [SleepStageInterval] = []
                
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    
                    // Track first in-bed time
                    if firstInBed == nil {
                        firstInBed = sample.startDate
                    }
                    
                    if #available(iOS 16.0, watchOS 9.0, *) {
                        if let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) {
                            if let stage = SleepStageInterval.stage(forHealthKitValue: sample.value) {
                                intervals.append(SleepStageInterval(stage: stage, startDate: sample.startDate, endDate: sample.endDate))
                            }
                            switch value {
                            case .asleepREM:
                                remSeconds += duration
                                totalSleepSeconds += duration
                                if !wasAsleep { wakeEpisodes += 1 }
                                wasAsleep = true
                                if firstAsleep == nil { firstAsleep = sample.startDate }
                                sleepEnd = sample.endDate
                            case .asleepDeep:
                                deepSeconds += duration
                                totalSleepSeconds += duration
                                if !wasAsleep { wakeEpisodes += 1 }
                                wasAsleep = true
                                if firstAsleep == nil { firstAsleep = sample.startDate }
                                sleepEnd = sample.endDate
                            case .asleepCore:
                                lightSeconds += duration
                                totalSleepSeconds += duration
                                if !wasAsleep { wakeEpisodes += 1 }
                                wasAsleep = true
                                if firstAsleep == nil { firstAsleep = sample.startDate }
                                sleepEnd = sample.endDate
                            case .asleepUnspecified:
                                totalSleepSeconds += duration
                                if !wasAsleep { wakeEpisodes += 1 }
                                wasAsleep = true
                                if firstAsleep == nil { firstAsleep = sample.startDate }
                                sleepEnd = sample.endDate
                            case .awake:
                                awakeSeconds += duration
                                wasAsleep = false
                            case .inBed:
                                inBedSeconds += duration
                            @unknown default:
                                break
                            }
                        }
                    } else {
                        // Pre-iOS 16: only asleep/awake categories
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            intervals.append(SleepStageInterval(stage: .light, startDate: sample.startDate, endDate: sample.endDate))
                            totalSleepSeconds += duration
                            if !wasAsleep { wakeEpisodes += 1 }
                            wasAsleep = true
                            if firstAsleep == nil { firstAsleep = sample.startDate }
                            sleepEnd = sample.endDate
                        } else {
                            intervals.append(SleepStageInterval(stage: .awake, startDate: sample.startDate, endDate: sample.endDate))
                            awakeSeconds += duration
                            wasAsleep = false
                        }
                    }
                }
                
                let hours = totalSleepSeconds / 3600
                let inBedTotal = inBedSeconds > 0 ? inBedSeconds : (firstInBed != nil && sleepEnd != nil ? sleepEnd!.timeIntervalSince(firstInBed!) : totalSleepSeconds)
                let efficiency = inBedTotal > 0 ? totalSleepSeconds / inBedTotal : 0
                let deepPercent = totalSleepSeconds > 0 ? deepSeconds / totalSleepSeconds : 0
                let remPercent = totalSleepSeconds > 0 ? remSeconds / totalSleepSeconds : 0
                let lightPercent = totalSleepSeconds > 0 ? lightSeconds / totalSleepSeconds : 0
                let awakePercent = inBedTotal > 0 ? awakeSeconds / inBedTotal : 0
                let onsetMinutes = firstInBed != nil && firstAsleep != nil ? firstAsleep!.timeIntervalSince(firstInBed!) / 60 : 15
                
                intervals.sort { $0.startDate < $1.startDate }
                continuation.resume(returning: (
                    hours, efficiency, deepPercent, remPercent,
                    lightPercent, awakePercent, onsetMinutes,
                    firstInBed, sleepEnd, max(0, wakeEpisodes - 1), intervals
                ))
            }
            self.healthStore.execute(query)
        }
    }
    
    private func fetchWorkouts(startOfDay: Date, endOfDay: Date? = nil) async -> [StrainSession] {
        let end = endOfDay ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, _ in
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let sessions = workouts.map { workout in
                    StrainSession(
                        workoutType: self.name(for: workout.workoutActivityType),
                        startDate: workout.startDate,
                        endDate: workout.endDate
                    )
                }
                continuation.resume(returning: sessions)
            }
            self.healthStore.execute(query)
        }
    }
    
    private nonisolated func name(for activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
    
    private func fetchRespiratoryRate(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return nil }
        return await fetchMostRecentQuantity(type: type, predicate: predicate, unit: HKUnit.count().unitDivided(by: .minute()))
    }
    
    private func fetchBloodOxygen(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return nil }
        let value = await fetchMostRecentQuantity(type: type, predicate: predicate, unit: HKUnit.percent())
        return value.map { $0 * 100 } // HealthKit stores as 0.0-1.0
    }
    
    private func fetchSkinTemperature(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else { return nil }
        return await fetchMostRecentQuantity(type: type, predicate: predicate, unit: .degreeCelsius())
    }
    
    private func fetchNutrition(predicate: NSPredicate) async -> NutritionSummary {
        let water = await fetchSumQuantity(
            type: HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            predicate: predicate,
            unit: .literUnit(with: .milli)
        ).map { $0 / 1000.0 }
        
        let caffeine = await fetchSumQuantity(
            type: HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine)!,
            predicate: predicate,
            unit: .gramUnit(with: .milli)
        ).map { $0 }
        
        let protein = await fetchSumQuantity(
            type: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
            predicate: predicate,
            unit: .gram()
        ).map { $0 }
        
        return NutritionSummary(waterLiters: water, caffeineMg: caffeine, proteinGrams: protein)
    }
    
    private func fetchMenstrualFlow(predicate: NSPredicate) async -> Bool {
        guard let type = HKObjectType.categoryType(forIdentifier: .menstrualFlow) else { return false }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                continuation.resume(returning: samples?.isEmpty == false)
            }
            self.healthStore.execute(query)
        }
    }
    
    private func fetchMostRecentQuantity(type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }
    
    private func fetchSumQuantity(type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }
    
    /// Detect which device/source provided the most recent data
    private func detectDataSource() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let detectedSource: String = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, _ in
                guard let sample = samples?.first else {
                    continuation.resume(returning: "HealthKit")
                    return
                }
                
                // Check source name
                let sourceName = sample.sourceRevision.source.name.lowercased()
                let result: String
                if sourceName.contains("watch") {
                    result = "Apple Watch"
                } else if sourceName.contains("oura") {
                    result = "Oura Ring"
                } else if sourceName.contains("whoop") {
                    result = "Whoop"
                } else if sourceName.contains("garmin") {
                    result = "Garmin"
                } else if sourceName.contains("fitbit") {
                    result = "Fitbit"
                } else {
                    result = "HealthKit"
                }
                
                continuation.resume(returning: result)
            }
            self.healthStore.execute(query)
        }
        
        await MainActor.run {
            self.dataSource = detectedSource
        }
    }
}
