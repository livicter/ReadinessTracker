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
    let environmentalAudioExposureDBA: Double?  // dB A-weighted — Honest #136
    let headphoneAudioExposureDBA: Double?  // dB A-weighted — Honest #137
    let environmentalSoundReductionDBA: Double?  // dB A-weighted — Honest #138
    let timeInDaylightMinutes: Double?  // minutes outdoors — Honest #139
    let uvExposureIndex: Double?  // UV index — Honest #140
    let flightsClimbed: Double?  // flights / floors — Honest #141
    let distanceWalkingRunningKm: Double?  // km walked/run — Honest #142
    let appleExerciseTimeMinutes: Double?  // Activity ring exercise min — Honest #143
    let appleStandHours: Double?  // Activity ring stand hours — Honest #144
    let walkingDoubleSupportPercent: Double?  // gait double-support % — Honest #145
    let walkingAsymmetryPercent: Double?  // gait asymmetry % — Honest #146
    let walkingSpeedMps: Double?  // gait walking speed m/s — Honest #147
    let walkingStepLengthMeters: Double?  // gait step length m — Honest #148
    let stairAscentSpeedMps: Double?  // stair ascent m/s — Honest #149
    let stairDescentSpeedMps: Double?  // stair descent m/s — Honest #150
    let sixMinuteWalkDistanceMeters: Double?  // 6MWT distance m — Honest #151
    
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
         environmentalAudioExposureDBA: Double? = nil,
         headphoneAudioExposureDBA: Double? = nil,
         environmentalSoundReductionDBA: Double? = nil,
         timeInDaylightMinutes: Double? = nil,
         uvExposureIndex: Double? = nil,
         flightsClimbed: Double? = nil,
         distanceWalkingRunningKm: Double? = nil,
         appleExerciseTimeMinutes: Double? = nil,
         appleStandHours: Double? = nil,
         walkingDoubleSupportPercent: Double? = nil,
         walkingAsymmetryPercent: Double? = nil,
         walkingSpeedMps: Double? = nil,
         walkingStepLengthMeters: Double? = nil,
         stairAscentSpeedMps: Double? = nil,
         stairDescentSpeedMps: Double? = nil,
         sixMinuteWalkDistanceMeters: Double? = nil,
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
        self.environmentalAudioExposureDBA = environmentalAudioExposureDBA
        self.headphoneAudioExposureDBA = headphoneAudioExposureDBA
        self.environmentalSoundReductionDBA = environmentalSoundReductionDBA
        self.timeInDaylightMinutes = timeInDaylightMinutes
        self.uvExposureIndex = uvExposureIndex
        self.flightsClimbed = flightsClimbed
        self.distanceWalkingRunningKm = distanceWalkingRunningKm
        self.appleExerciseTimeMinutes = appleExerciseTimeMinutes
        self.appleStandHours = appleStandHours
        self.walkingDoubleSupportPercent = walkingDoubleSupportPercent
        self.walkingAsymmetryPercent = walkingAsymmetryPercent
        self.walkingSpeedMps = walkingSpeedMps
        self.walkingStepLengthMeters = walkingStepLengthMeters
        self.stairAscentSpeedMps = stairAscentSpeedMps
        self.stairDescentSpeedMps = stairDescentSpeedMps
        self.sixMinuteWalkDistanceMeters = sixMinuteWalkDistanceMeters
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
        self.environmentalAudioExposureDBA = nil
        self.headphoneAudioExposureDBA = nil
        self.environmentalSoundReductionDBA = nil
        self.timeInDaylightMinutes = nil
        self.uvExposureIndex = nil
        self.flightsClimbed = nil
        self.distanceWalkingRunningKm = nil
        self.appleExerciseTimeMinutes = nil
        self.appleStandHours = nil
        self.walkingDoubleSupportPercent = nil
        self.walkingAsymmetryPercent = nil
        self.walkingSpeedMps = nil
        self.walkingStepLengthMeters = nil
        self.stairAscentSpeedMps = nil
        self.stairDescentSpeedMps = nil
        self.sixMinuteWalkDistanceMeters = nil
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
        case skinTemperature, respiratoryRate, bloodOxygen, vo2Max, walkingHeartRateAverage, environmentalAudioExposureDBA, headphoneAudioExposureDBA, environmentalSoundReductionDBA, timeInDaylightMinutes, uvExposureIndex, flightsClimbed, distanceWalkingRunningKm, appleExerciseTimeMinutes, appleStandHours, walkingDoubleSupportPercent, walkingAsymmetryPercent, walkingSpeedMps, walkingStepLengthMeters, stairAscentSpeedMps, stairDescentSpeedMps, sixMinuteWalkDistanceMeters
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
        self.environmentalAudioExposureDBA = try container.decodeIfPresent(Double.self, forKey: .environmentalAudioExposureDBA)
        self.headphoneAudioExposureDBA = try container.decodeIfPresent(Double.self, forKey: .headphoneAudioExposureDBA)
        self.environmentalSoundReductionDBA = try container.decodeIfPresent(Double.self, forKey: .environmentalSoundReductionDBA)
        self.timeInDaylightMinutes = try container.decodeIfPresent(Double.self, forKey: .timeInDaylightMinutes)
        self.uvExposureIndex = try container.decodeIfPresent(Double.self, forKey: .uvExposureIndex)
        self.flightsClimbed = try container.decodeIfPresent(Double.self, forKey: .flightsClimbed)
        self.distanceWalkingRunningKm = try container.decodeIfPresent(Double.self, forKey: .distanceWalkingRunningKm)
        self.appleExerciseTimeMinutes = try container.decodeIfPresent(Double.self, forKey: .appleExerciseTimeMinutes)
        self.appleStandHours = try container.decodeIfPresent(Double.self, forKey: .appleStandHours)
        self.walkingDoubleSupportPercent = try container.decodeIfPresent(Double.self, forKey: .walkingDoubleSupportPercent)
        self.walkingAsymmetryPercent = try container.decodeIfPresent(Double.self, forKey: .walkingAsymmetryPercent)
        self.walkingSpeedMps = try container.decodeIfPresent(Double.self, forKey: .walkingSpeedMps)
        self.walkingStepLengthMeters = try container.decodeIfPresent(Double.self, forKey: .walkingStepLengthMeters)
        self.stairAscentSpeedMps = try container.decodeIfPresent(Double.self, forKey: .stairAscentSpeedMps)
        self.stairDescentSpeedMps = try container.decodeIfPresent(Double.self, forKey: .stairDescentSpeedMps)
        self.sixMinuteWalkDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .sixMinuteWalkDistanceMeters)
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
