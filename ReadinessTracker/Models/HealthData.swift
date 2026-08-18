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
    
    // HRV - stored as SDNN (HealthKit native). RMSSD can be derived or computed from RR intervals
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
        case skinTemperature, respiratoryRate, bloodOxygen
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
