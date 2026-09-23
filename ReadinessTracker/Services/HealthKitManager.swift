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
        
        var typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .appleStandHour)!,
            HKObjectType.quantityType(forIdentifier: .appleMoveTime)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .numberOfTimesFallen)!,
            HKObjectType.quantityType(forIdentifier: .pushCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage)!,
            HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage)!,
            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
            HKObjectType.quantityType(forIdentifier: .walkingStepLength)!,
            HKObjectType.quantityType(forIdentifier: .appleWalkingSteadiness)!,
            HKObjectType.quantityType(forIdentifier: .stairAscentSpeed)!,
            HKObjectType.quantityType(forIdentifier: .stairDescentSpeed)!,
            HKObjectType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .peripheralPerfusionIndex)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
            HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!,
            HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure)!,
            HKObjectType.quantityType(forIdentifier: .environmentalSoundReduction)!,
            HKObjectType.quantityType(forIdentifier: .uvExposure)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKSeriesType.heartbeat(),
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.categoryType(forIdentifier: .menstrualFlow)!
        ]
        
        do {
        if #available(iOS 17.0, *) {
            if let daylightType = HKObjectType.quantityType(forIdentifier: .timeInDaylight) {
                typesToRead.insert(daylightType)
            }
            if let cadenceType = HKObjectType.quantityType(forIdentifier: .cyclingCadence) {
                typesToRead.insert(cadenceType)
            }
            if let powerType = HKObjectType.quantityType(forIdentifier: .cyclingPower) {
                typesToRead.insert(powerType)
            }
            if let ftpType = HKObjectType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower) {
                typesToRead.insert(ftpType)
            }
            if let effortType = HKObjectType.quantityType(forIdentifier: .physicalEffort) {
                typesToRead.insert(effortType)
            }
        }

        if #available(iOS 16.0, *) {
            if let depthType = HKObjectType.quantityType(forIdentifier: .underwaterDepth) {
                typesToRead.insert(depthType)
            }
            if let runPowerType = HKObjectType.quantityType(forIdentifier: .runningPower) {
                typesToRead.insert(runPowerType)
            }
            if let runSpeedType = HKObjectType.quantityType(forIdentifier: .runningSpeed) {
                typesToRead.insert(runSpeedType)
            }
            if let gctType = HKObjectType.quantityType(forIdentifier: .runningGroundContactTime) {
                typesToRead.insert(gctType)
            }
            if let strideType = HKObjectType.quantityType(forIdentifier: .runningStrideLength) {
                typesToRead.insert(strideType)
            }
            if let voType = HKObjectType.quantityType(forIdentifier: .runningVerticalOscillation) {
                typesToRead.insert(voType)
            }
            if let hrrType = HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute) {
                typesToRead.insert(hrrType)
            }
            if let afType = HKObjectType.quantityType(forIdentifier: .atrialFibrillationBurden) {
                typesToRead.insert(afType)
            }
        }

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
        async let vo2 = fetchVO2Max()
        async let walkingHR = fetchWalkingHeartRateAverage(predicate: predicate)
        async let hrr = fetchHeartRateRecoveryOneMinute(predicate: predicate)
        async let afBurden = fetchAtrialFibrillationBurden(predicate: predicate)
        async let ppi = fetchPeripheralPerfusionIndex(predicate: predicate)
        async let falls = fetchNumberOfTimesFallen(predicate: predicate)
        async let pushes = fetchPushCount(predicate: predicate)
        async let envAudio = fetchEnvironmentalAudioExposure(predicate: predicate)
        async let headphoneAudio = fetchHeadphoneAudioExposure(predicate: predicate)
        async let soundReduction = fetchEnvironmentalSoundReduction(predicate: predicate)
        async let daylight = fetchTimeInDaylight(predicate: predicate)
        async let uv = fetchUVExposure(predicate: predicate)
        async let flights = fetchFlightsClimbed(predicate: predicate)
        async let distance = fetchDistanceWalkingRunning(predicate: predicate)
        async let exerciseTime = fetchAppleExerciseTime(predicate: predicate)
        async let standHours = fetchAppleStandHours(predicate: predicate)
        async let moveTime = fetchAppleMoveTime(predicate: predicate)
        async let doubleSupport = fetchWalkingDoubleSupport(predicate: predicate)
        async let asymmetry = fetchWalkingAsymmetry(predicate: predicate)
        async let walkSpeed = fetchWalkingSpeed(predicate: predicate)
        async let stepLength = fetchWalkingStepLength(predicate: predicate)
        async let steadiness = fetchWalkingSteadiness(predicate: predicate)
        async let stairAscent = fetchStairAscentSpeed(predicate: predicate)
        async let stairDescent = fetchStairDescentSpeed(predicate: predicate)
        async let sixMWT = fetchSixMinuteWalkDistance(predicate: predicate)
        async let swimDistance = fetchDistanceSwimming(predicate: predicate)
        async let swimStrokes = fetchSwimmingStrokeCount(predicate: predicate)
        async let cycleCadence = fetchCyclingCadence(predicate: predicate)
        async let underwaterDepth = fetchUnderwaterDepth(predicate: predicate)
        async let cyclePower = fetchCyclingPower(predicate: predicate)
        async let cycleFTP = fetchCyclingFTP(predicate: predicate)
        async let cycleDistance = fetchDistanceCycling(predicate: predicate)
        async let physicalEffort = fetchPhysicalEffort(predicate: predicate)
        async let runPower = fetchRunningPower(predicate: predicate)
        async let runSpeed = fetchRunningSpeed(predicate: predicate)
        async let runGCT = fetchRunningGroundContact(predicate: predicate)
        async let runStride = fetchRunningStrideLength(predicate: predicate)
        async let runVO = fetchRunningVerticalOscillation(predicate: predicate)
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
            vo2Max: await vo2,
            walkingHeartRateAverage: await walkingHR,
            heartRateRecoveryOneMinuteBpm: await hrr,
            atrialFibrillationBurdenPercent: await afBurden,
            peripheralPerfusionIndexPercent: await ppi,
            numberOfTimesFallen: await falls,
            pushCount: await pushes,
            environmentalAudioExposureDBA: await envAudio,
            headphoneAudioExposureDBA: await headphoneAudio,
            environmentalSoundReductionDBA: await soundReduction,
            timeInDaylightMinutes: await daylight,
            uvExposureIndex: await uv,
            flightsClimbed: await flights,
            distanceWalkingRunningKm: await distance,
            appleExerciseTimeMinutes: await exerciseTime,
            appleStandHours: await standHours,
            appleMoveTimeMinutes: await moveTime,
            walkingDoubleSupportPercent: await doubleSupport,
            walkingAsymmetryPercent: await asymmetry,
            walkingSpeedMps: await walkSpeed,
            walkingStepLengthMeters: await stepLength,
            walkingSteadinessPercent: await steadiness,
            stairAscentSpeedMps: await stairAscent,
            stairDescentSpeedMps: await stairDescent,
            sixMinuteWalkDistanceMeters: await sixMWT,
            distanceSwimmingMeters: await swimDistance,
            swimmingStrokeCount: await swimStrokes,
            cyclingCadenceRpm: await cycleCadence,
            underwaterDepthMeters: await underwaterDepth,
            cyclingPowerWatts: await cyclePower,
            cyclingFTPWatts: await cycleFTP,
            distanceCyclingKm: await cycleDistance,
            physicalEffortKcalPerHrKg: await physicalEffort,
            runningPowerWatts: await runPower,
            runningSpeedMps: await runSpeed,
            runningGroundContactMs: await runGCT,
            runningStrideLengthMeters: await runStride,
            runningVerticalOscillationCm: await runVO,
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
            async let vo2 = fetchVO2Max()
            async let walkingHR = fetchWalkingHeartRateAverage(predicate: predicate)
            async let hrr = fetchHeartRateRecoveryOneMinute(predicate: predicate)
            async let afBurden = fetchAtrialFibrillationBurden(predicate: predicate)
            async let ppi = fetchPeripheralPerfusionIndex(predicate: predicate)
            async let falls = fetchNumberOfTimesFallen(predicate: predicate)
            async let pushes = fetchPushCount(predicate: predicate)
            async let envAudio = fetchEnvironmentalAudioExposure(predicate: predicate)
            async let headphoneAudio = fetchHeadphoneAudioExposure(predicate: predicate)
            async let soundReduction = fetchEnvironmentalSoundReduction(predicate: predicate)
            async let daylight = fetchTimeInDaylight(predicate: predicate)
            async let uv = fetchUVExposure(predicate: predicate)
            async let flights = fetchFlightsClimbed(predicate: predicate)
            async let distance = fetchDistanceWalkingRunning(predicate: predicate)
            async let exerciseTime = fetchAppleExerciseTime(predicate: predicate)
            async let standHours = fetchAppleStandHours(predicate: predicate)
            async let moveTime = fetchAppleMoveTime(predicate: predicate)
            async let doubleSupport = fetchWalkingDoubleSupport(predicate: predicate)
            async let asymmetry = fetchWalkingAsymmetry(predicate: predicate)
            async let walkSpeed = fetchWalkingSpeed(predicate: predicate)
            async let stepLength = fetchWalkingStepLength(predicate: predicate)
            async let steadiness = fetchWalkingSteadiness(predicate: predicate)
            async let stairAscent = fetchStairAscentSpeed(predicate: predicate)
            async let stairDescent = fetchStairDescentSpeed(predicate: predicate)
            async let sixMWT = fetchSixMinuteWalkDistance(predicate: predicate)
            async let swimDistance = fetchDistanceSwimming(predicate: predicate)
            async let swimStrokes = fetchSwimmingStrokeCount(predicate: predicate)
            async let cycleCadence = fetchCyclingCadence(predicate: predicate)
            async let underwaterDepth = fetchUnderwaterDepth(predicate: predicate)
            async let cyclePower = fetchCyclingPower(predicate: predicate)
            async let cycleFTP = fetchCyclingFTP(predicate: predicate)
            async let cycleDistance = fetchDistanceCycling(predicate: predicate)
            async let physicalEffort = fetchPhysicalEffort(predicate: predicate)
            async let runPower = fetchRunningPower(predicate: predicate)
            async let runSpeed = fetchRunningSpeed(predicate: predicate)
            async let runGCT = fetchRunningGroundContact(predicate: predicate)
            async let runStride = fetchRunningStrideLength(predicate: predicate)
            async let runVO = fetchRunningVerticalOscillation(predicate: predicate)
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
            let vo2Value = await vo2
            let walkingHRValue = await walkingHR
            let hrrValue = await hrr
            let afBurdenValue = await afBurden
            let ppiValue = await ppi
            let fallsValue = await falls
            let pushesValue = await pushes
            let envAudioValue = await envAudio
            let headphoneAudioValue = await headphoneAudio
            let soundReductionValue = await soundReduction
            let daylightValue = await daylight
            let uvValue = await uv
            let flightsValue = await flights
            let distanceValue = await distance
            let exerciseTimeValue = await exerciseTime
            let standHoursValue = await standHours
            let moveTimeValue = await moveTime
            let doubleSupportValue = await doubleSupport
            let asymmetryValue = await asymmetry
            let walkSpeedValue = await walkSpeed
            let stepLengthValue = await stepLength
            let steadinessValue = await steadiness
            let stairAscentValue = await stairAscent
            let stairDescentValue = await stairDescent
            let sixMWTValue = await sixMWT
            let swimDistanceValue = await swimDistance
            let swimStrokesValue = await swimStrokes
            let cycleCadenceValue = await cycleCadence
            let underwaterDepthValue = await underwaterDepth
            let cyclePowerValue = await cyclePower
            let cycleFTPValue = await cycleFTP
            let cycleDistanceValue = await cycleDistance
            let physicalEffortValue = await physicalEffort
            let runPowerValue = await runPower
            let runSpeedValue = await runSpeed
            let runGCTValue = await runGCT
            let runStrideValue = await runStride
            let runVOValue = await runVO
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
                vo2Max: vo2Value,
                walkingHeartRateAverage: walkingHRValue,
                heartRateRecoveryOneMinuteBpm: hrrValue,
                atrialFibrillationBurdenPercent: afBurdenValue,
                peripheralPerfusionIndexPercent: ppiValue,
                numberOfTimesFallen: fallsValue,
                pushCount: pushesValue,
                environmentalAudioExposureDBA: envAudioValue,
                headphoneAudioExposureDBA: headphoneAudioValue,
                environmentalSoundReductionDBA: soundReductionValue,
                timeInDaylightMinutes: daylightValue,
                uvExposureIndex: uvValue,
                flightsClimbed: flightsValue,
                distanceWalkingRunningKm: distanceValue,
                appleExerciseTimeMinutes: exerciseTimeValue,
                appleStandHours: standHoursValue,
                appleMoveTimeMinutes: moveTimeValue,
                walkingDoubleSupportPercent: doubleSupportValue,
                walkingAsymmetryPercent: asymmetryValue,
                walkingSpeedMps: walkSpeedValue,
                walkingStepLengthMeters: stepLengthValue,
                walkingSteadinessPercent: steadinessValue,
                stairAscentSpeedMps: stairAscentValue,
                stairDescentSpeedMps: stairDescentValue,
                sixMinuteWalkDistanceMeters: sixMWTValue,
                distanceSwimmingMeters: swimDistanceValue,
                swimmingStrokeCount: swimStrokesValue,
                cyclingCadenceRpm: cycleCadenceValue,
                underwaterDepthMeters: underwaterDepthValue,
                cyclingPowerWatts: cyclePowerValue,
                cyclingFTPWatts: cycleFTPValue,
                distanceCyclingKm: cycleDistanceValue,
                physicalEffortKcalPerHrKg: physicalEffortValue,
                runningPowerWatts: runPowerValue,
                runningSpeedMps: runSpeedValue,
                runningGroundContactMs: runGCTValue,
                runningStrideLengthMeters: runStrideValue,
                runningVerticalOscillationCm: runVOValue,
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


    /// Latest VO2 Max (ml/kg/min). Sparse on Simulator — fixture seeds values for UI.
    private func fetchVO2Max() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .vo2Max) else { return nil }
        // ml/(kg·min)
        // Prefer string unit — works across SDK spellings of mL/kg·min.
        let unit = HKUnit(from: "mL/kg*min")
        return await withCheckedContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day walking heart-rate average (bpm). Apple Watch quantity; sparse on Simulator.
    private func fetchWalkingHeartRateAverage(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day average heart-rate recovery (bpm drop in first minute). Sparse readiness — fixture seeds UI. iOS 16+.
    private func fetchHeartRateRecoveryOneMinute(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateRecoveryOneMinute) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day average atrial fibrillation burden (0–100%). Sparse cardio — fixture seeds UI. iOS 16+.
    private func fetchAtrialFibrillationBurden(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .atrialFibrillationBurden) else { return nil }
        let unit = HKUnit.percent()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let raw = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                let pct = raw <= 1.0 ? raw * 100.0 : raw
                continuation.resume(returning: pct)
            }
            self.healthStore.execute(query)
        }
    }



    /// Day average peripheral perfusion index (0–100%). Sparse SpO2-adjacent — fixture seeds UI.
    private func fetchPeripheralPerfusionIndex(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .peripheralPerfusionIndex) else { return nil }
        let unit = HKUnit.percent()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let raw = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                let pct = raw <= 1.0 ? raw * 100.0 : raw
                continuation.resume(returning: pct)
            }
            self.healthStore.execute(query)
        }
    }



    /// Day cumulative number of times fallen. Sparse mobility safety — fixture seeds UI.
    private func fetchNumberOfTimesFallen(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .count())
    }


    /// Day cumulative wheelchair push count. Sparse mobility — fixture seeds UI.
    private func fetchPushCount(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .pushCount) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .count())
    }




    /// Day environmental audio exposure average (dB A-weighted). Sparse on Simulator.
    private func fetchEnvironmentalAudioExposure(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure) else { return nil }
        let unit = HKUnit.decibelAWeightedSoundPressureLevel()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day headphone audio exposure average (dB A-weighted). Sparse on Simulator.
    private func fetchHeadphoneAudioExposure(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure) else { return nil }
        let unit = HKUnit.decibelAWeightedSoundPressureLevel()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day environmental sound reduction average (dB A-weighted). AirPods Pro ANC delta; sparse on Simulator.
    private func fetchEnvironmentalSoundReduction(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .environmentalSoundReduction) else { return nil }
        let unit = HKUnit.decibelAWeightedSoundPressureLevel()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day cumulative time in daylight (minutes). Apple Watch outdoor daylight; iOS 17+, sparse on Simulator.
    private func fetchTimeInDaylight(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 17.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .minute())
    }





    /// Day average UV exposure index. Sparse on Simulator — fixture seeds UI.
    private func fetchUVExposure(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .uvExposure) else { return nil }
        let unit = HKUnit.count()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }



    /// Day cumulative flights climbed (floors). Sparse-ish on Simulator — fixture seeds UI.
    private func fetchFlightsClimbed(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .count())
    }



    /// Day cumulative walking+running distance in kilometers. Sparse on Simulator — fixture seeds UI.
    private func fetchDistanceWalkingRunning(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return nil }
        guard let meters = await fetchSumQuantity(type: type, predicate: predicate, unit: .meter()) else { return nil }
        return meters / 1000.0
    }



    /// Day cumulative Apple Exercise Time (Activity ring minutes). Sparse on Simulator — fixture seeds UI.
    private func fetchAppleExerciseTime(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .minute())
    }


    /// Count of hours where user stood ≥1 min (Activity Stand ring). Sparse on Simulator — fixture seeds UI.
    private func fetchAppleStandHours(predicate: NSPredicate) async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .appleStandHour) else { return nil }
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                let stood = samples.filter { $0.value == HKCategoryValueAppleStandHour.stood.rawValue }.count
                continuation.resume(returning: Double(stood))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day cumulative Apple Move Time (Activity Move ring minutes). Sparse on Simulator — fixture seeds UI.
    private func fetchAppleMoveTime(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleMoveTime) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .minute())
    }



    /// Day average walking double-support percentage (both feet down). Sparse gait metric — fixture seeds UI.
    private func fetchWalkingDoubleSupport(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingDoubleSupportPercentage) else { return nil }
        let unit = HKUnit.percent()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let raw = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                // HK percent unit is 0…1 fraction; store as 0…100 for UI.
                let pct = raw <= 1.0 ? raw * 100.0 : raw
                continuation.resume(returning: pct)
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average walking asymmetry percentage (left/right imbalance). Sparse gait — fixture seeds UI.
    private func fetchWalkingAsymmetry(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingAsymmetryPercentage) else { return nil }
        let unit = HKUnit.percent()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let raw = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                let pct = raw <= 1.0 ? raw * 100.0 : raw
                continuation.resume(returning: pct)
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average walking speed (m/s). Sparse gait — fixture seeds UI.
    private func fetchWalkingSpeed(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else { return nil }
        let unit = HKUnit.meter().unitDivided(by: .second())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average walking step length (meters). Sparse gait — fixture seeds UI.
    private func fetchWalkingStepLength(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .walkingStepLength) else { return nil }
        let unit = HKUnit.meter()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average Apple Walking Steadiness (0–100%). Sparse gait balance — fixture seeds UI.
    private func fetchWalkingSteadiness(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .appleWalkingSteadiness) else { return nil }
        let unit = HKUnit.percent()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let raw = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                let pct = raw <= 1.0 ? raw * 100.0 : raw
                continuation.resume(returning: pct)
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average stair ascent speed (m/s). Sparse mobility — fixture seeds UI.
    private func fetchStairAscentSpeed(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stairAscentSpeed) else { return nil }
        let unit = HKUnit.meter().unitDivided(by: .second())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average stair descent speed (m/s). Sparse mobility — fixture seeds UI.
    private func fetchStairDescentSpeed(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stairDescentSpeed) else { return nil }
        let unit = HKUnit.meter().unitDivided(by: .second())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Most recent / day average six-minute walk test distance (meters). Sparse clinical mobility — fixture seeds UI.
    private func fetchSixMinuteWalkDistance(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .sixMinuteWalkTestDistance) else { return nil }
        let unit = HKUnit.meter()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day cumulative swimming distance (meters). Sparse activity — fixture seeds UI.
    private func fetchDistanceSwimming(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceSwimming) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .meter())
    }


    /// Day cumulative cycling distance in kilometers. Sparse activity — fixture seeds UI.
    private func fetchDistanceCycling(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceCycling) else { return nil }
        guard let meters = await fetchSumQuantity(type: type, predicate: predicate, unit: .meter()) else { return nil }
        return meters / 1000.0
    }



    /// Day cumulative swimming stroke count. Sparse activity — fixture seeds UI.
    private func fetchSwimmingStrokeCount(predicate: NSPredicate) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount) else { return nil }
        return await fetchSumQuantity(type: type, predicate: predicate, unit: .count())
    }


    /// Day average cycling cadence (rpm). Sparse activity — fixture seeds UI. iOS 17+.
    private func fetchCyclingCadence(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 17.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .cyclingCadence) else { return nil }
        let unit = HKUnit.count().unitDivided(by: .minute())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day max underwater depth (meters). Sparse Ultra/dive activity — fixture seeds UI. iOS 16+.
    private func fetchUnderwaterDepth(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .underwaterDepth) else { return nil }
        let unit = HKUnit.meter()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteMax
            ) { _, stats, _ in
                continuation.resume(returning: stats?.maximumQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average cycling power (watts). Sparse activity — fixture seeds UI. iOS 17+.
    private func fetchCyclingPower(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 17.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .cyclingPower) else { return nil }
        let unit = HKUnit.watt()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day / latest cycling functional threshold power (watts). Sparse fitness — fixture seeds UI. iOS 17+.
    private func fetchCyclingFTP(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 17.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .cyclingFunctionalThresholdPower) else { return nil }
        let unit = HKUnit.watt()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average physical effort (kcal/hr·kg). Sparse readiness intensity — fixture seeds UI. iOS 17+.
    private func fetchPhysicalEffort(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 17.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .physicalEffort) else { return nil }
        let unit = HKUnit.kilocalorie().unitDivided(by: HKUnit.hour().unitMultiplied(by: .gramUnit(with: .kilo)))
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average running power (watts). Sparse run intensity — fixture seeds UI. iOS 16+.
    private func fetchRunningPower(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningPower) else { return nil }
        let unit = HKUnit.watt()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average running speed (m/s). Sparse run pace — fixture seeds UI. iOS 16+.
    private func fetchRunningSpeed(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningSpeed) else { return nil }
        let unit = HKUnit.meter().unitDivided(by: .second())
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                continuation.resume(returning: stats?.averageQuantity()?.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average running ground contact time (ms). Sparse run-form — fixture seeds UI. iOS 16+.
    private func fetchRunningGroundContact(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningGroundContactTime) else { return nil }
        let unit = HKUnit.second()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let seconds = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: seconds * 1000.0)
            }
            self.healthStore.execute(query)
        }
    }


    /// Day average running stride length (meters). Sparse run-form — fixture seeds UI. iOS 16+.
    private func fetchRunningStrideLength(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningStrideLength) else { return nil }
        let unit = HKUnit.meter()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let meters = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: meters)
            }
            self.healthStore.execute(query)
        }
    }



    /// Day average running vertical oscillation (cm). Sparse run-form — fixture seeds UI. iOS 16+.
    private func fetchRunningVerticalOscillation(predicate: NSPredicate) async -> Double? {
        guard #available(iOS 16.0, *) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .runningVerticalOscillation) else { return nil }
        let unit = HKUnit.meter()
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, stats, _ in
                guard let meters = stats?.averageQuantity()?.doubleValue(for: unit) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: meters * 100.0)
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

        let energy = await fetchSumQuantity(
            type: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            predicate: predicate,
            unit: .kilocalorie()
        ).map { $0 }

        let carbs = await fetchSumQuantity(
            type: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            predicate: predicate,
            unit: .gram()
        ).map { $0 }
        
        return NutritionSummary(
            waterLiters: water,
            caffeineMg: caffeine,
            proteinGrams: protein,
            energyKcal: energy,
            carbohydrateGrams: carbs
        )
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
