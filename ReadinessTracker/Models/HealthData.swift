import Foundation
import HealthKit

enum DataSource: String, Codable, CaseIterable {
    case appleWatch = "Apple Watch"
    case fitbit = "Fitbit"
}

struct DailyHealthData: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let source: DataSource
    
    // Sleep
    let sleepHours: Double
    let sleepEfficiency: Double
    let deepSleepPercent: Double
    let remSleepPercent: Double
    let lightSleepPercent: Double
    let awakePercent: Double
    let sleepOnsetMinutes: Double
    let sleepStartTime: Date?
    let sleepEndTime: Date?
    let wakeEpisodes: Int
    let sleepStages: [SleepStageInterval]
    
    // HRV: RMSSD when `hrvIsRMSSD` is true (recovery path). Otherwise HealthKit SDNN.
    let hrv: Double
    let hrvIsRMSSD: Bool // false = SDNN, true = RMSSD
    
    let restingHeartRate: Double
    let activeCalories: Double
    let steps: Int
    let workoutMinutes: Int
    
    // WHOOP-style advanced metrics
    let skinTemperature: Double?  // Celsius, deviation from baseline
    let respiratoryRate: Double?  // breaths per minute
    let bloodOxygen: Double?      // SpO2 percentage
    let vo2Max: Double?           // ml/(kg·min) — Honest #133
    let walkingHeartRateAverage: Double?  // bpm — Honest #134
    let heartRateRecoveryOneMinuteBpm: Double?  // HRR 1-min bpm drop — Honest #167
    let atrialFibrillationBurdenPercent: Double?  // AF burden % — Honest #168
    let peripheralPerfusionIndexPercent: Double?  // PPI % — Honest #169
    let numberOfTimesFallen: Double?  // falls count — Honest #170
    let pushCount: Double?  // wheelchair pushes — Honest #171
    let distanceWheelchairKm: Double?  // wheelchair distance km — Honest #223
    let inhalerUsage: Double?  // inhaler puffs — Honest #178
    let peakExpiratoryFlowLpm: Double?  // PEF L/min — Honest #224
    let forcedVitalCapacityLiters: Double?  // FVC L — Honest #225
    let forcedExpiratoryVolume1Liters: Double?  // FEV1 L — Honest #226
    let insulinDeliveryIU: Double?  // insulin IU — Honest #179
    let bloodGlucoseMgDl: Double?  // blood glucose mg/dL — Honest #180
    let bloodPressureSystolicMmHg: Double?  // BP systolic mmHg — Honest #188
    let bloodPressureDiastolicMmHg: Double?  // BP diastolic mmHg — Honest #188
    let bodyMassKg: Double?  // body mass kg — Honest #181
    let leanBodyMassKg: Double?  // lean body mass kg — Honest #182
    let waistCircumferenceCm: Double?  // waist cm — Honest #183
    let bodyFatPercent: Double?  // body fat % — Honest #187
    let basalEnergyKcal: Double?  // basal kcal — Honest #184
    let toothbrushingMinutes: Double?  // brushing duration min — Honest #185
    let handwashingMinutes: Double?  // handwash duration min — Honest #186
    let mindfulMinutes: Double?  // mindful session min — Honest #189
    let environmentalAudioExposureDBA: Double?  // dB A-weighted — Honest #136
    let headphoneAudioExposureDBA: Double?  // dB A-weighted — Honest #137
    let environmentalSoundReductionDBA: Double?  // dB A-weighted — Honest #138
    let timeInDaylightMinutes: Double?  // minutes outdoors — Honest #139
    let uvExposureIndex: Double?  // UV index — Honest #140
    let flightsClimbed: Double?  // flights / floors — Honest #141
    let distanceWalkingRunningKm: Double?  // km walked/run — Honest #142
    let appleExerciseTimeMinutes: Double?  // Activity ring exercise min — Honest #143
    let appleStandHours: Double?  // Activity ring stand hours — Honest #144
    let appleStandTimeMinutes: Double?  // Cumulative stand minutes — Honest #221
    let appleMoveTimeMinutes: Double?  // Activity ring move minutes — Honest #164
    let walkingDoubleSupportPercent: Double?  // gait double-support % — Honest #145
    let walkingAsymmetryPercent: Double?  // gait asymmetry % — Honest #146
    let walkingSpeedMps: Double?  // gait walking speed m/s — Honest #147
    let walkingStepLengthMeters: Double?  // gait step length m — Honest #148
    let walkingSteadinessPercent: Double?  // gait walking steadiness % — Honest #166
    let stairAscentSpeedMps: Double?  // stair ascent m/s — Honest #149
    let stairDescentSpeedMps: Double?  // stair descent m/s — Honest #150
    let sixMinuteWalkDistanceMeters: Double?  // 6MWT distance m — Honest #151
    let distanceSwimmingMeters: Double?  // swim distance m — Honest #152
    let swimmingStrokeCount: Double?  // swim stroke count — Honest #153
    let cyclingCadenceRpm: Double?  // cycling cadence rpm — Honest #154
    let underwaterDepthMeters: Double?  // max underwater depth m — Honest #155
    let cyclingPowerWatts: Double?  // cycling power W — Honest #156
    let cyclingFTPWatts: Double?  // cycling FTP W — Honest #157
    let distanceCyclingKm: Double?  // cycling distance km — Honest #165
    let distanceRowingKm: Double?  // rowing distance km — Honest #229
    let rowingSpeedMps: Double?  // rowing speed m/s — Honest #230
    let cyclingSpeedMps: Double?  // cycling speed m/s — Honest #222
    let physicalEffortKcalPerHrKg: Double?  // physical effort kcal/hr·kg — Honest #158
    let workoutEffortScore: Double?  // workoutEffortScore 0–10 — Honest #227
    let estimatedWorkoutEffortScore: Double?  // estimatedWorkoutEffortScore 0–10 — Honest #228
    let runningPowerWatts: Double?  // running power W — Honest #159
    let runningSpeedMps: Double?  // running speed m/s — Honest #160
    let runningGroundContactMs: Double?  // running GCT ms — Honest #161
    let runningStrideLengthMeters: Double?  // running stride m — Honest #162
    let runningVerticalOscillationCm: Double?  // running VO cm — Honest #163
    
    // Cardiovascular strain data
    let maxHeartRate: Double?
    let hrSamples: [HRSample]
    
    // Workout-level strain sessions
    let strainSessions: [StrainSession]
    
    // Nutrition & wellness
    let nutrition: NutritionSummary
    let menstrualFlow: Bool
    
    var readinessScore: Int {
        ReadinessCalculator.calculate(from: self)
    }
    
    var sleepData: SleepData {
        SleepData(
            hours: sleepHours,
            efficiency: sleepEfficiency,
            deepPercent: deepSleepPercent,
            remPercent: remSleepPercent,
            hrvDuringSleep: hrvIsRMSSD ? hrv : nil
        )
    }
    
    init(id: UUID = UUID(), date: Date, source: DataSource,
         sleepHours: Double = 0, sleepEfficiency: Double = 0.85,
         deepSleepPercent: Double = 0.15, remSleepPercent: Double = 0.20,
         lightSleepPercent: Double = 0.55, awakePercent: Double = 0.05,
         sleepOnsetMinutes: Double = 15, sleepStartTime: Date? = nil,
         sleepEndTime: Date? = nil, wakeEpisodes: Int = 2,
         sleepStages: [SleepStageInterval] = [],
         hrv: Double = 0, hrvIsRMSSD: Bool = false,
         restingHeartRate: Double = 0, activeCalories: Double = 0,
         steps: Int = 0, workoutMinutes: Int = 0,
         maxHeartRate: Double? = nil, hrSamples: [HRSample] = [],
         strainSessions: [StrainSession] = [],
         skinTemperature: Double? = nil, respiratoryRate: Double? = nil, bloodOxygen: Double? = nil,
         vo2Max: Double? = nil,
         walkingHeartRateAverage: Double? = nil,
         heartRateRecoveryOneMinuteBpm: Double? = nil,
         atrialFibrillationBurdenPercent: Double? = nil,
         peripheralPerfusionIndexPercent: Double? = nil,
         numberOfTimesFallen: Double? = nil,
         pushCount: Double? = nil,
         distanceWheelchairKm: Double? = nil,
         inhalerUsage: Double? = nil,
         peakExpiratoryFlowLpm: Double? = nil,
         forcedVitalCapacityLiters: Double? = nil,
         forcedExpiratoryVolume1Liters: Double? = nil,
         insulinDeliveryIU: Double? = nil,
         bloodGlucoseMgDl: Double? = nil,
         bloodPressureSystolicMmHg: Double? = nil,
         bloodPressureDiastolicMmHg: Double? = nil,
         bodyMassKg: Double? = nil,
         leanBodyMassKg: Double? = nil,
         waistCircumferenceCm: Double? = nil,
         bodyFatPercent: Double? = nil,
         basalEnergyKcal: Double? = nil,
         toothbrushingMinutes: Double? = nil,
         handwashingMinutes: Double? = nil,
         mindfulMinutes: Double? = nil,
         environmentalAudioExposureDBA: Double? = nil,
         headphoneAudioExposureDBA: Double? = nil,
         environmentalSoundReductionDBA: Double? = nil,
         timeInDaylightMinutes: Double? = nil,
         uvExposureIndex: Double? = nil,
         flightsClimbed: Double? = nil,
         distanceWalkingRunningKm: Double? = nil,
         appleExerciseTimeMinutes: Double? = nil,
         appleStandHours: Double? = nil,
         appleStandTimeMinutes: Double? = nil,
         appleMoveTimeMinutes: Double? = nil,
         walkingDoubleSupportPercent: Double? = nil,
         walkingAsymmetryPercent: Double? = nil,
         walkingSpeedMps: Double? = nil,
         walkingStepLengthMeters: Double? = nil,
         walkingSteadinessPercent: Double? = nil,
         stairAscentSpeedMps: Double? = nil,
         stairDescentSpeedMps: Double? = nil,
         sixMinuteWalkDistanceMeters: Double? = nil,
         distanceSwimmingMeters: Double? = nil,
         swimmingStrokeCount: Double? = nil,
         cyclingCadenceRpm: Double? = nil,
         underwaterDepthMeters: Double? = nil,
         cyclingPowerWatts: Double? = nil,
         cyclingFTPWatts: Double? = nil,
         distanceCyclingKm: Double? = nil,
         distanceRowingKm: Double? = nil,
         rowingSpeedMps: Double? = nil,
         cyclingSpeedMps: Double? = nil,
         physicalEffortKcalPerHrKg: Double? = nil,
         workoutEffortScore: Double? = nil,
         estimatedWorkoutEffortScore: Double? = nil,
         runningPowerWatts: Double? = nil,
         runningSpeedMps: Double? = nil,
         runningGroundContactMs: Double? = nil,
         runningStrideLengthMeters: Double? = nil,
         runningVerticalOscillationCm: Double? = nil,
         nutrition: NutritionSummary = NutritionSummary(),
         menstrualFlow: Bool = false) {
        self.id = id
        self.date = date
        self.source = source
        self.sleepHours = sleepHours
        self.sleepEfficiency = sleepEfficiency
        self.deepSleepPercent = deepSleepPercent
        self.remSleepPercent = remSleepPercent
        self.lightSleepPercent = lightSleepPercent
        self.awakePercent = awakePercent
        self.sleepOnsetMinutes = sleepOnsetMinutes
        self.sleepStartTime = sleepStartTime
        self.sleepEndTime = sleepEndTime
        self.wakeEpisodes = wakeEpisodes
        self.sleepStages = sleepStages
        self.hrv = hrv
        self.hrvIsRMSSD = hrvIsRMSSD
        self.restingHeartRate = restingHeartRate
        self.activeCalories = activeCalories
        self.steps = steps
        self.workoutMinutes = workoutMinutes
        self.maxHeartRate = maxHeartRate
        self.hrSamples = hrSamples
        self.strainSessions = strainSessions
        self.skinTemperature = skinTemperature
        self.respiratoryRate = respiratoryRate
        self.bloodOxygen = bloodOxygen
        self.vo2Max = vo2Max
        self.walkingHeartRateAverage = walkingHeartRateAverage
        self.heartRateRecoveryOneMinuteBpm = heartRateRecoveryOneMinuteBpm
        self.atrialFibrillationBurdenPercent = atrialFibrillationBurdenPercent
        self.peripheralPerfusionIndexPercent = peripheralPerfusionIndexPercent
        self.numberOfTimesFallen = numberOfTimesFallen
        self.pushCount = pushCount
        self.distanceWheelchairKm = distanceWheelchairKm
        self.inhalerUsage = inhalerUsage
        self.peakExpiratoryFlowLpm = peakExpiratoryFlowLpm
        self.forcedVitalCapacityLiters = forcedVitalCapacityLiters
        self.forcedExpiratoryVolume1Liters = forcedExpiratoryVolume1Liters
        self.insulinDeliveryIU = insulinDeliveryIU
        self.bloodGlucoseMgDl = bloodGlucoseMgDl
        self.bloodPressureSystolicMmHg = bloodPressureSystolicMmHg
        self.bloodPressureDiastolicMmHg = bloodPressureDiastolicMmHg
        self.bodyMassKg = bodyMassKg
        self.leanBodyMassKg = leanBodyMassKg
        self.waistCircumferenceCm = waistCircumferenceCm
        self.bodyFatPercent = bodyFatPercent
        self.basalEnergyKcal = basalEnergyKcal
        self.toothbrushingMinutes = toothbrushingMinutes
        self.handwashingMinutes = handwashingMinutes
        self.mindfulMinutes = mindfulMinutes
        self.environmentalAudioExposureDBA = environmentalAudioExposureDBA
        self.headphoneAudioExposureDBA = headphoneAudioExposureDBA
        self.environmentalSoundReductionDBA = environmentalSoundReductionDBA
        self.timeInDaylightMinutes = timeInDaylightMinutes
        self.uvExposureIndex = uvExposureIndex
        self.flightsClimbed = flightsClimbed
        self.distanceWalkingRunningKm = distanceWalkingRunningKm
        self.appleExerciseTimeMinutes = appleExerciseTimeMinutes
        self.appleStandHours = appleStandHours
        self.appleStandTimeMinutes = appleStandTimeMinutes
        self.appleMoveTimeMinutes = appleMoveTimeMinutes
        self.walkingDoubleSupportPercent = walkingDoubleSupportPercent
        self.walkingAsymmetryPercent = walkingAsymmetryPercent
        self.walkingSpeedMps = walkingSpeedMps
        self.walkingStepLengthMeters = walkingStepLengthMeters
        self.walkingSteadinessPercent = walkingSteadinessPercent
        self.stairAscentSpeedMps = stairAscentSpeedMps
        self.stairDescentSpeedMps = stairDescentSpeedMps
        self.sixMinuteWalkDistanceMeters = sixMinuteWalkDistanceMeters
        self.distanceSwimmingMeters = distanceSwimmingMeters
        self.swimmingStrokeCount = swimmingStrokeCount
        self.cyclingCadenceRpm = cyclingCadenceRpm
        self.underwaterDepthMeters = underwaterDepthMeters
        self.cyclingPowerWatts = cyclingPowerWatts
        self.cyclingFTPWatts = cyclingFTPWatts
        self.distanceCyclingKm = distanceCyclingKm
        self.distanceRowingKm = distanceRowingKm
        self.rowingSpeedMps = rowingSpeedMps
        self.cyclingSpeedMps = cyclingSpeedMps
        self.physicalEffortKcalPerHrKg = physicalEffortKcalPerHrKg
        self.workoutEffortScore = workoutEffortScore
        self.estimatedWorkoutEffortScore = estimatedWorkoutEffortScore
        self.runningPowerWatts = runningPowerWatts
        self.runningSpeedMps = runningSpeedMps
        self.runningGroundContactMs = runningGroundContactMs
        self.runningStrideLengthMeters = runningStrideLengthMeters
        self.runningVerticalOscillationCm = runningVerticalOscillationCm
        self.nutrition = nutrition
        self.menstrualFlow = menstrualFlow
    }
    
    // Legacy init for backward compatibility
    init(id: UUID = UUID(), date: Date, source: DataSource,
         sleepHours: Double, sleepQuality: Double, hrv: Double,
         restingHeartRate: Double, activeCalories: Double,
         steps: Int, workoutMinutes: Int) {
        self.id = id
        self.date = date
        self.source = source
        self.sleepHours = sleepHours
        self.sleepEfficiency = sleepQuality
        self.deepSleepPercent = 0.15
        self.remSleepPercent = 0.20
        self.lightSleepPercent = 0.55
        self.awakePercent = 0.10
        self.sleepOnsetMinutes = 15
        self.sleepStartTime = nil
        self.sleepEndTime = nil
        self.wakeEpisodes = 2
        self.sleepStages = []
        self.hrv = hrv
        self.hrvIsRMSSD = false
        self.restingHeartRate = restingHeartRate
        self.activeCalories = activeCalories
        self.steps = steps
        self.workoutMinutes = workoutMinutes
        self.maxHeartRate = nil
        self.hrSamples = []
        self.strainSessions = []
        self.skinTemperature = nil
        self.respiratoryRate = nil
        self.bloodOxygen = nil
        self.vo2Max = nil
        self.walkingHeartRateAverage = nil
        self.heartRateRecoveryOneMinuteBpm = nil
        self.atrialFibrillationBurdenPercent = nil
        self.peripheralPerfusionIndexPercent = nil
        self.numberOfTimesFallen = nil
        self.pushCount = nil
        self.distanceWheelchairKm = nil
        self.inhalerUsage = nil
        self.peakExpiratoryFlowLpm = nil
        self.forcedVitalCapacityLiters = nil
        self.forcedExpiratoryVolume1Liters = nil
        self.insulinDeliveryIU = nil
        self.bloodGlucoseMgDl = nil
        self.bloodPressureSystolicMmHg = nil
        self.bloodPressureDiastolicMmHg = nil
        self.bodyMassKg = nil
        self.leanBodyMassKg = nil
        self.waistCircumferenceCm = nil
        self.bodyFatPercent = nil
        self.basalEnergyKcal = nil
        self.toothbrushingMinutes = nil
        self.handwashingMinutes = nil
        self.mindfulMinutes = nil
        self.environmentalAudioExposureDBA = nil
        self.headphoneAudioExposureDBA = nil
        self.environmentalSoundReductionDBA = nil
        self.timeInDaylightMinutes = nil
        self.uvExposureIndex = nil
        self.flightsClimbed = nil
        self.distanceWalkingRunningKm = nil
        self.appleExerciseTimeMinutes = nil
        self.appleStandHours = nil
        self.appleStandTimeMinutes = nil
        self.appleMoveTimeMinutes = nil
        self.walkingDoubleSupportPercent = nil
        self.walkingAsymmetryPercent = nil
        self.walkingSpeedMps = nil
        self.walkingStepLengthMeters = nil
        self.walkingSteadinessPercent = nil
        self.stairAscentSpeedMps = nil
        self.stairDescentSpeedMps = nil
        self.sixMinuteWalkDistanceMeters = nil
        self.distanceSwimmingMeters = nil
        self.swimmingStrokeCount = nil
        self.cyclingCadenceRpm = nil
        self.underwaterDepthMeters = nil
        self.cyclingPowerWatts = nil
        self.cyclingFTPWatts = nil
        self.distanceCyclingKm = nil
        self.distanceRowingKm = nil
        self.rowingSpeedMps = nil
        self.cyclingSpeedMps = nil
        self.physicalEffortKcalPerHrKg = nil
        self.workoutEffortScore = nil
        self.estimatedWorkoutEffortScore = nil
        self.runningPowerWatts = nil
        self.runningSpeedMps = nil
        self.runningGroundContactMs = nil
        self.runningStrideLengthMeters = nil
        self.runningVerticalOscillationCm = nil
        self.nutrition = NutritionSummary()
        self.menstrualFlow = false
    }
    
    // Custom decoder so persisted data from older builds loads even when new fields are missing.
    private enum CodingKeys: String, CodingKey {
        case id, date, source
        case sleepHours, sleepEfficiency
        case deepSleepPercent, remSleepPercent, lightSleepPercent, awakePercent
        case sleepOnsetMinutes, sleepStartTime, sleepEndTime, wakeEpisodes, sleepStages
        case hrv, hrvIsRMSSD
        case restingHeartRate, activeCalories, steps, workoutMinutes
        case maxHeartRate, hrSamples
        case strainSessions
        case skinTemperature, respiratoryRate, bloodOxygen, vo2Max, walkingHeartRateAverage, heartRateRecoveryOneMinuteBpm, atrialFibrillationBurdenPercent, peripheralPerfusionIndexPercent, numberOfTimesFallen, pushCount, distanceWheelchairKm, inhalerUsage, peakExpiratoryFlowLpm, forcedVitalCapacityLiters, forcedExpiratoryVolume1Liters, insulinDeliveryIU, bloodGlucoseMgDl, bloodPressureSystolicMmHg, bloodPressureDiastolicMmHg, bodyMassKg, leanBodyMassKg, waistCircumferenceCm, bodyFatPercent, basalEnergyKcal, toothbrushingMinutes, handwashingMinutes, mindfulMinutes, environmentalAudioExposureDBA, headphoneAudioExposureDBA, environmentalSoundReductionDBA, timeInDaylightMinutes, uvExposureIndex, flightsClimbed, distanceWalkingRunningKm, appleExerciseTimeMinutes, appleStandHours, appleStandTimeMinutes, appleMoveTimeMinutes, walkingDoubleSupportPercent, walkingAsymmetryPercent, walkingSpeedMps, walkingStepLengthMeters, walkingSteadinessPercent, stairAscentSpeedMps, stairDescentSpeedMps, sixMinuteWalkDistanceMeters, distanceSwimmingMeters, swimmingStrokeCount, cyclingCadenceRpm, underwaterDepthMeters, cyclingPowerWatts, cyclingFTPWatts, distanceCyclingKm, distanceRowingKm, rowingSpeedMps, cyclingSpeedMps, physicalEffortKcalPerHrKg, workoutEffortScore, estimatedWorkoutEffortScore, runningPowerWatts, runningSpeedMps, runningGroundContactMs, runningStrideLengthMeters, runningVerticalOscillationCm
        case nutrition, menstrualFlow
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.source = try container.decode(DataSource.self, forKey: .source)
        self.sleepHours = try container.decodeIfPresent(Double.self, forKey: .sleepHours) ?? 0
        self.sleepEfficiency = try container.decodeIfPresent(Double.self, forKey: .sleepEfficiency) ?? 0.85
        self.deepSleepPercent = try container.decodeIfPresent(Double.self, forKey: .deepSleepPercent) ?? 0.15
        self.remSleepPercent = try container.decodeIfPresent(Double.self, forKey: .remSleepPercent) ?? 0.20
        self.lightSleepPercent = try container.decodeIfPresent(Double.self, forKey: .lightSleepPercent) ?? 0.55
        self.awakePercent = try container.decodeIfPresent(Double.self, forKey: .awakePercent) ?? 0.05
        self.sleepOnsetMinutes = try container.decodeIfPresent(Double.self, forKey: .sleepOnsetMinutes) ?? 15
        self.sleepStartTime = try container.decodeIfPresent(Date.self, forKey: .sleepStartTime)
        self.sleepEndTime = try container.decodeIfPresent(Date.self, forKey: .sleepEndTime)
        self.wakeEpisodes = try container.decodeIfPresent(Int.self, forKey: .wakeEpisodes) ?? 2
        self.sleepStages = try container.decodeIfPresent([SleepStageInterval].self, forKey: .sleepStages) ?? []
        self.hrv = try container.decodeIfPresent(Double.self, forKey: .hrv) ?? 0
        self.hrvIsRMSSD = try container.decodeIfPresent(Bool.self, forKey: .hrvIsRMSSD) ?? false
        self.restingHeartRate = try container.decodeIfPresent(Double.self, forKey: .restingHeartRate) ?? 0
        self.activeCalories = try container.decodeIfPresent(Double.self, forKey: .activeCalories) ?? 0
        self.steps = try container.decodeIfPresent(Int.self, forKey: .steps) ?? 0
        self.workoutMinutes = try container.decodeIfPresent(Int.self, forKey: .workoutMinutes) ?? 0
        self.maxHeartRate = try container.decodeIfPresent(Double.self, forKey: .maxHeartRate)
        self.hrSamples = try container.decodeIfPresent([HRSample].self, forKey: .hrSamples) ?? []
        self.strainSessions = try container.decodeIfPresent([StrainSession].self, forKey: .strainSessions) ?? []
        self.skinTemperature = try container.decodeIfPresent(Double.self, forKey: .skinTemperature)
        self.respiratoryRate = try container.decodeIfPresent(Double.self, forKey: .respiratoryRate)
        self.bloodOxygen = try container.decodeIfPresent(Double.self, forKey: .bloodOxygen)
        self.vo2Max = try container.decodeIfPresent(Double.self, forKey: .vo2Max)
        self.walkingHeartRateAverage = try container.decodeIfPresent(Double.self, forKey: .walkingHeartRateAverage)
        self.heartRateRecoveryOneMinuteBpm = try container.decodeIfPresent(Double.self, forKey: .heartRateRecoveryOneMinuteBpm)
        self.atrialFibrillationBurdenPercent = try container.decodeIfPresent(Double.self, forKey: .atrialFibrillationBurdenPercent)
        self.peripheralPerfusionIndexPercent = try container.decodeIfPresent(Double.self, forKey: .peripheralPerfusionIndexPercent)
        self.numberOfTimesFallen = try container.decodeIfPresent(Double.self, forKey: .numberOfTimesFallen)
        self.pushCount = try container.decodeIfPresent(Double.self, forKey: .pushCount)
        self.distanceWheelchairKm = try container.decodeIfPresent(Double.self, forKey: .distanceWheelchairKm)
        self.inhalerUsage = try container.decodeIfPresent(Double.self, forKey: .inhalerUsage)
        self.peakExpiratoryFlowLpm = try container.decodeIfPresent(Double.self, forKey: .peakExpiratoryFlowLpm)
        self.forcedVitalCapacityLiters = try container.decodeIfPresent(Double.self, forKey: .forcedVitalCapacityLiters)
        self.forcedExpiratoryVolume1Liters = try container.decodeIfPresent(Double.self, forKey: .forcedExpiratoryVolume1Liters)
        self.insulinDeliveryIU = try container.decodeIfPresent(Double.self, forKey: .insulinDeliveryIU)
        self.bloodGlucoseMgDl = try container.decodeIfPresent(Double.self, forKey: .bloodGlucoseMgDl)
        self.bloodPressureSystolicMmHg = try container.decodeIfPresent(Double.self, forKey: .bloodPressureSystolicMmHg)
        self.bloodPressureDiastolicMmHg = try container.decodeIfPresent(Double.self, forKey: .bloodPressureDiastolicMmHg)
        self.bodyMassKg = try container.decodeIfPresent(Double.self, forKey: .bodyMassKg)
        self.leanBodyMassKg = try container.decodeIfPresent(Double.self, forKey: .leanBodyMassKg)
        self.waistCircumferenceCm = try container.decodeIfPresent(Double.self, forKey: .waistCircumferenceCm)
        self.bodyFatPercent = try container.decodeIfPresent(Double.self, forKey: .bodyFatPercent)
        self.basalEnergyKcal = try container.decodeIfPresent(Double.self, forKey: .basalEnergyKcal)
        self.toothbrushingMinutes = try container.decodeIfPresent(Double.self, forKey: .toothbrushingMinutes)
        self.handwashingMinutes = try container.decodeIfPresent(Double.self, forKey: .handwashingMinutes)
        self.mindfulMinutes = try container.decodeIfPresent(Double.self, forKey: .mindfulMinutes)
        self.environmentalAudioExposureDBA = try container.decodeIfPresent(Double.self, forKey: .environmentalAudioExposureDBA)
        self.headphoneAudioExposureDBA = try container.decodeIfPresent(Double.self, forKey: .headphoneAudioExposureDBA)
        self.environmentalSoundReductionDBA = try container.decodeIfPresent(Double.self, forKey: .environmentalSoundReductionDBA)
        self.timeInDaylightMinutes = try container.decodeIfPresent(Double.self, forKey: .timeInDaylightMinutes)
        self.uvExposureIndex = try container.decodeIfPresent(Double.self, forKey: .uvExposureIndex)
        self.flightsClimbed = try container.decodeIfPresent(Double.self, forKey: .flightsClimbed)
        self.distanceWalkingRunningKm = try container.decodeIfPresent(Double.self, forKey: .distanceWalkingRunningKm)
        self.appleExerciseTimeMinutes = try container.decodeIfPresent(Double.self, forKey: .appleExerciseTimeMinutes)
        self.appleStandHours = try container.decodeIfPresent(Double.self, forKey: .appleStandHours)
        self.appleStandTimeMinutes = try container.decodeIfPresent(Double.self, forKey: .appleStandTimeMinutes)
        self.appleMoveTimeMinutes = try container.decodeIfPresent(Double.self, forKey: .appleMoveTimeMinutes)
        self.walkingDoubleSupportPercent = try container.decodeIfPresent(Double.self, forKey: .walkingDoubleSupportPercent)
        self.walkingAsymmetryPercent = try container.decodeIfPresent(Double.self, forKey: .walkingAsymmetryPercent)
        self.walkingSpeedMps = try container.decodeIfPresent(Double.self, forKey: .walkingSpeedMps)
        self.walkingStepLengthMeters = try container.decodeIfPresent(Double.self, forKey: .walkingStepLengthMeters)
        self.walkingSteadinessPercent = try container.decodeIfPresent(Double.self, forKey: .walkingSteadinessPercent)
        self.stairAscentSpeedMps = try container.decodeIfPresent(Double.self, forKey: .stairAscentSpeedMps)
        self.stairDescentSpeedMps = try container.decodeIfPresent(Double.self, forKey: .stairDescentSpeedMps)
        self.sixMinuteWalkDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .sixMinuteWalkDistanceMeters)
        self.distanceSwimmingMeters = try container.decodeIfPresent(Double.self, forKey: .distanceSwimmingMeters)
        self.swimmingStrokeCount = try container.decodeIfPresent(Double.self, forKey: .swimmingStrokeCount)
        self.cyclingCadenceRpm = try container.decodeIfPresent(Double.self, forKey: .cyclingCadenceRpm)
        self.underwaterDepthMeters = try container.decodeIfPresent(Double.self, forKey: .underwaterDepthMeters)
        self.cyclingPowerWatts = try container.decodeIfPresent(Double.self, forKey: .cyclingPowerWatts)
        self.cyclingFTPWatts = try container.decodeIfPresent(Double.self, forKey: .cyclingFTPWatts)
        self.distanceCyclingKm = try container.decodeIfPresent(Double.self, forKey: .distanceCyclingKm)
        self.distanceRowingKm = try container.decodeIfPresent(Double.self, forKey: .distanceRowingKm)
        self.rowingSpeedMps = try container.decodeIfPresent(Double.self, forKey: .rowingSpeedMps)
        self.cyclingSpeedMps = try container.decodeIfPresent(Double.self, forKey: .cyclingSpeedMps)
        self.physicalEffortKcalPerHrKg = try container.decodeIfPresent(Double.self, forKey: .physicalEffortKcalPerHrKg)
        self.workoutEffortScore = try container.decodeIfPresent(Double.self, forKey: .workoutEffortScore)
        self.estimatedWorkoutEffortScore = try container.decodeIfPresent(Double.self, forKey: .estimatedWorkoutEffortScore)
        self.runningPowerWatts = try container.decodeIfPresent(Double.self, forKey: .runningPowerWatts)
        self.runningSpeedMps = try container.decodeIfPresent(Double.self, forKey: .runningSpeedMps)
        self.runningGroundContactMs = try container.decodeIfPresent(Double.self, forKey: .runningGroundContactMs)
        self.runningStrideLengthMeters = try container.decodeIfPresent(Double.self, forKey: .runningStrideLengthMeters)
        self.runningVerticalOscillationCm = try container.decodeIfPresent(Double.self, forKey: .runningVerticalOscillationCm)
        self.nutrition = try container.decodeIfPresent(NutritionSummary.self, forKey: .nutrition) ?? NutritionSummary()
        self.menstrualFlow = try container.decodeIfPresent(Bool.self, forKey: .menstrualFlow) ?? false
    }
}

struct ReadinessBreakdown: Codable {
    let sleepScore: Int
    let hrvScore: Int
    let recoveryScore: Int
    let strainScore: Int
    let consistencyScore: Int
    let totalScore: Int
    let tempScore: Int
    let respScore: Int
    let spo2Score: Int
    let strainScoreValue: Double
    
    private enum CodingKeys: String, CodingKey {
        case sleepScore, hrvScore, recoveryScore, strainScore, consistencyScore, totalScore
        case tempScore, respScore, spo2Score, strainScoreValue
    }
    
    init(
        sleepScore: Int,
        hrvScore: Int,
        recoveryScore: Int,
        strainScore: Int,
        consistencyScore: Int,
        totalScore: Int,
        tempScore: Int = 0,
        respScore: Int = 0,
        spo2Score: Int = 0,
        strainScoreValue: Double = 0
    ) {
        self.sleepScore = sleepScore
        self.hrvScore = hrvScore
        self.recoveryScore = recoveryScore
        self.strainScore = strainScore
        self.consistencyScore = consistencyScore
        self.totalScore = totalScore
        self.tempScore = tempScore
        self.respScore = respScore
        self.spo2Score = spo2Score
        self.strainScoreValue = strainScoreValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sleepScore = try container.decode(Int.self, forKey: .sleepScore)
        self.hrvScore = try container.decode(Int.self, forKey: .hrvScore)
        self.recoveryScore = try container.decode(Int.self, forKey: .recoveryScore)
        self.strainScore = try container.decode(Int.self, forKey: .strainScore)
        self.consistencyScore = try container.decode(Int.self, forKey: .consistencyScore)
        self.totalScore = try container.decode(Int.self, forKey: .totalScore)
        self.tempScore = try container.decodeIfPresent(Int.self, forKey: .tempScore) ?? 0
        self.respScore = try container.decodeIfPresent(Int.self, forKey: .respScore) ?? 0
        self.spo2Score = try container.decodeIfPresent(Int.self, forKey: .spo2Score) ?? 0
        self.strainScoreValue = try container.decodeIfPresent(Double.self, forKey: .strainScoreValue) ?? 0
    }
}
