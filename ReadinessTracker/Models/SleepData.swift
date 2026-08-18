import Foundation

/// Detailed sleep metrics following research plan
/// All consumer wearables have high sensitivity (>90%) but poor specificity (29-52%) for wake detection
struct SleepData: Codable {
    let hours: Double
    let efficiency: Double      // % (asleep time / time in bed)
    let deepPercent: Double     // % of total sleep time
    let remPercent: Double      // % of total sleep time
    let hrvDuringSleep: Double? // RMSSD or SDNN during sleep
    
    static let optimalHours = 7.5...9.0
    static let optimalDeep = 0.15...0.20
    static let optimalRem = 0.20...0.25
    static let minEfficiency = 0.85
    
    /// Composite sleep score 0-100 per research plan:
    /// - Duration 40%, Efficiency 30%, Deep 20%, REM 10%
    func score() -> Int {
        let durationScore = scoreDuration()
        let efficiencyScore = scoreEfficiency()
        let deepScore = scoreDeep()
        let remScore = scoreRem()
        
        let total = Int(
            Double(durationScore) * 0.40 +
            Double(efficiencyScore) * 0.30 +
            Double(deepScore) * 0.20 +
            Double(remScore) * 0.10
        )
        return min(100, max(0, total))
    }
    
    private func scoreDuration() -> Int {
        if SleepData.optimalHours.contains(hours) { return 100 }
        if hours < 4.0 { return 20 }
        if hours < 6.0 { return 50 }
        if hours < 7.0 { return 75 }
        if hours > 10.0 { return 70 }
        if hours > 9.0 { return 90 }
        return 85 // 6-7h or 9-10h
    }
    
    private func scoreEfficiency() -> Int {
        if efficiency >= 0.90 { return 100 }
        if efficiency >= 0.85 { return 85 }
        if efficiency >= 0.75 { return 60 }
        return 30
    }
    
    private func scoreDeep() -> Int {
        if SleepData.optimalDeep.contains(deepPercent) { return 100 }
        if deepPercent < 0.05 { return 30 }
        if deepPercent < 0.10 { return 60 }
        if deepPercent > 0.30 { return 70 }
        return 85
    }
    
    private func scoreRem() -> Int {
        if SleepData.optimalRem.contains(remPercent) { return 100 }
        if remPercent < 0.10 { return 40 }
        if remPercent < 0.15 { return 70 }
        if remPercent > 0.35 { return 60 }
        return 85
    }
}
