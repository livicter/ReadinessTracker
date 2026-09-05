import Foundation

enum RecoveryCalculator {
    struct RecoveryBreakdown {
        let hrvScore: Int
        let rhrScore: Int
        let sleepScore: Int
        let tempScore: Int
        let respScore: Int
        let spo2Score: Int
        let totalScore: Int
    }
    
    static func calculate(from data: DailyHealthData, history: [DailyHealthData]) -> Int {
        calculateBreakdown(from: data, history: history).totalScore
    }

    /// Score fed to the Recovery & Strain wheel. Recovery 0-100, not general readiness.
    static func dashboardWheelScore(from data: DailyHealthData, history: [DailyHealthData]) -> Double {
        Double(calculate(from: data, history: history))
    }
    
    static func calculateBreakdown(from data: DailyHealthData, history: [DailyHealthData]) -> RecoveryBreakdown {
        let hrvScore = scoreHRV(data.hrv, history: history, data: data)
        let rhrScore = scoreRHR(data.restingHeartRate, history: history)
        let sleepScore = data.sleepData.score()
        let tempScore = scoreSkinTemp(data.skinTemperature, history: history)
        let respScore = scoreRespiratoryRate(data.respiratoryRate, history: history)
        let spo2Score = scoreSpO2(data.bloodOxygen)
        
        var total = Int(
            Double(hrvScore) * 0.30 +
            Double(sleepScore) * 0.25 +
            Double(rhrScore) * 0.20 +
            Double(spo2Score) * 0.05 +
            Double(tempScore) * 0.10 +
            Double(respScore) * 0.10
        )
        
        if UserSettings.load().trackMenstrualCycle && data.menstrualFlow {
            total -= 3
        }
        
        return RecoveryBreakdown(
            hrvScore: hrvScore,
            rhrScore: rhrScore,
            sleepScore: sleepScore,
            tempScore: tempScore,
            respScore: respScore,
            spo2Score: spo2Score,
            totalScore: min(100, max(0, total))
        )
    }
    
    private static func scoreHRV(_ hrv: Double, history: [DailyHealthData], data: DailyHealthData) -> Int {
        guard hrv > 0 else { return 50 }
        let baseline = BaselineManager.hrvBaseline(from: history, matchesRMSSD: data.hrvIsRMSSD)
        guard baseline > 0 else { return 50 }
        let ratio = hrv / baseline
        // Input is RMSSD when available, otherwise SDNN. Ratio logic is identical.
        // 100 at 1.15x baseline, 75 at baseline, 0 at 0.55x baseline
        let score = Int((ratio - 0.55) / 0.60 * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreRHR(_ rhr: Double, history: [DailyHealthData]) -> Int {
        guard rhr > 0 else { return 50 }
        let baseline = BaselineManager.rhrBaseline(from: history)
        guard baseline > 0 else { return 50 }
        let ratio = rhr / baseline
        // Lower RHR = better recovery
        let score = Int((1.25 - ratio) / 0.25 * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreSkinTemp(_ temp: Double?, history: [DailyHealthData]) -> Int {
        guard let temp = temp, temp > 0 else { return 75 }
        guard let baseline = BaselineManager.skinTempBaseline(from: history) else { return 75 }
        // Skin temp 0.5°C above baseline = lower recovery (illness/overreaching)
        let deviation = temp - baseline
        let score = Int(100 - abs(deviation) / 2.0 * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreRespiratoryRate(_ rate: Double?, history: [DailyHealthData]) -> Int {
        guard let rate = rate, rate > 0 else { return 75 }
        let baseline = BaselineManager.respiratoryRateBaseline(from: history)
        guard baseline > 0 else { return 75 }
        let ratio = rate / baseline
        // Lower resp rate = better recovery; penalize elevation
        let score = Int((1.25 - ratio) / 0.25 * 100)
        return min(100, max(0, score))
    }
    
    private static func scoreSpO2(_ spo2: Double?) -> Int {
        guard let spo2 = spo2, spo2 > 0 else { return 75 }
        let fraction = spo2 > 1.0 ? spo2 / 100.0 : spo2 // handle both 95 and 0.95
        if fraction >= 0.98 { return 100 }
        if fraction <= 0.90 { return 0 }
        return Int((fraction - 0.90) / 0.08 * 100)
    }
}
