import Foundation

/// Calculates readiness score based on peer-reviewed research:
/// - HRV Score: 25% (recovery capacity)
/// - Sleep Score: 25% (restoration quality)
/// - RHR Score: 20% (cardiac recovery)
/// - SpO2 Score: 5% (oxygen saturation)
/// - Strain Score: 15% (previous day load)
/// - Consistency: 10% (sleep/wake regularity)
///
/// Uses personal 7-day rolling baselines — population norms are useless for HRV.
enum ReadinessCalculator {
    
    static func calculate(from data: DailyHealthData) -> Int {
        let breakdown = calculateBreakdown(from: data)
        return breakdown.totalScore
    }
    
    static func calculateBreakdown(from data: DailyHealthData, history: [DailyHealthData] = []) -> ReadinessBreakdown {
        let recovery = RecoveryCalculator.calculateBreakdown(from: data, history: history)
        let strainValue = StrainCalculator.calculate(from: data, history: history)
        let strainScore = Int(max(0, 100 - (strainValue / 21.0) * 100))
        let consistencyScore = BaselineManager.consistencyScore(from: history)
        
        var total = Int(
            Double(recovery.hrvScore) * 0.25 +
            Double(recovery.sleepScore) * 0.25 +
            Double(recovery.rhrScore) * 0.20 +
            Double(recovery.spo2Score) * 0.05 +
            Double(strainScore) * 0.15 +
            Double(consistencyScore) * 0.10
        )

        if UserSettings.load().trackMenstrualCycle && data.menstrualFlow {
            total -= 3
        }

        return ReadinessBreakdown(
            sleepScore: recovery.sleepScore,
            hrvScore: recovery.hrvScore,
            recoveryScore: recovery.rhrScore,
            strainScore: strainScore,
            consistencyScore: consistencyScore,
            totalScore: min(100, max(0, total)),
            tempScore: recovery.tempScore,
            respScore: recovery.respScore,
            spo2Score: recovery.spo2Score,
            strainScoreValue: strainValue
        )
    }
    
    /// Calculate dual readiness scores: General / Cognitive / Gym
    /// Based on research showing mental fatigue and physical strain have different recovery patterns
    static func calculateDualScores(
        from data: DailyHealthData,
        history: [DailyHealthData] = [],
        metadata: UserMetadata? = nil
    ) -> DualReadinessScores {
        let baseBreakdown = calculateBreakdown(from: data, history: history)
        let baseScore = baseBreakdown.totalScore
        
        // General readiness (balanced)
        let generalMultiplier = metadata?.readinessMultiplier() ?? 1.0
        let generalScore = min(100, max(0, Int(Double(baseScore) * generalMultiplier)))
        
        // Cognitive readiness (mental fatigue weighted more)
        let cognitiveMultiplier = metadata?.cognitiveReadinessMultiplier() ?? 1.0
        let cognitiveScore = min(100, max(0, Int(Double(baseScore) * cognitiveMultiplier)))
        
        // Gym readiness (physical strain weighted more)
        let gymMultiplier = metadata?.gymReadinessMultiplier() ?? 1.0
        let gymScore = min(100, max(0, Int(Double(baseScore) * gymMultiplier)))
        
        return DualReadinessScores(
            general: generalScore,
            cognitive: cognitiveScore,
            gym: gymScore,
            breakdown: baseBreakdown
        )
    }
    
    /// Apply multi-day strain decay (Alves 2024 — HIIT suppresses HRV 24-48h)
    /// Previous day high RPE reduces readiness for 2 days
    static func applyStrainDecay(
        to score: Int,
        previousRPE: Int?,
        daysSinceWorkout: Int
    ) -> Int {
        guard let rpe = previousRPE, rpe > 6 else { return score }
        
        let decayFactor: Double
        switch daysSinceWorkout {
        case 1:
            // Day after: -3% per RPE point above 6
            decayFactor = 1.0 - (Double(rpe - 6) * 0.03)
        case 2:
            // Day 2: residual -1.5% per RPE point
            decayFactor = 1.0 - (Double(rpe - 6) * 0.015)
        default:
            decayFactor = 1.0
        }
        
        return min(100, max(0, Int(Double(score) * decayFactor)))
    }
    
    /// Apply cognitive recovery lag (Kallinen 2023 — cognitive recovery lags 24-48h)
    static func applyCognitiveLag(
        to score: Int,
        previousMentalFatigue: Int?,
        previousWorkloadStress: Int?,
        daysSince: Int
    ) -> Int {
        guard daysSince <= 2 else { return score }
        
        var decayFactor = 1.0
        
        if let fatigue = previousMentalFatigue, fatigue > 3 {
            let penalty = Double(fatigue - 3) * (daysSince == 1 ? 0.04 : 0.02)
            decayFactor -= penalty
        }
        
        if let stress = previousWorkloadStress, stress > 3 {
            let penalty = Double(stress - 3) * (daysSince == 1 ? 0.03 : 0.015)
            decayFactor -= penalty
        }
        
        return min(100, max(0, Int(Double(score) * decayFactor)))
    }
    
    static func recommendation(for score: Int) -> String {
        switch score {
        case 80...100: return "Excellent recovery. Push hard today."
        case 65..<80: return "Good recovery. Moderate intensity is fine."
        case 50..<65: return "Fair recovery. Take it easy."
        case 30..<50: return "Poor recovery. Light activity only."
        default: return "Very poor recovery. Rest is essential."
        }
    }
}

/// Dual readiness scores for different contexts
struct DualReadinessScores {
    let general: Int
    let cognitive: Int
    let gym: Int
    let breakdown: ReadinessBreakdown
    
    var primaryScore: Int { general }
    
    var balance: StrainRecoveryBalance {
        StrainRecoveryBalance.compute(
            recovery: general,
            strain: breakdown.strainScoreValue
        )
    }
    
    func recommendation() -> String {
        if gym >= 80 && cognitive >= 70 {
            return "Ready for heavy gym + heavy workload"
        } else if gym >= 80 {
            return "Ready for heavy gym, take it easy on work"
        } else if cognitive >= 80 {
            return "Ready for heavy workload, light gym only"
        } else if gym >= 60 && cognitive >= 60 {
            return "Moderate day — light gym + manageable work"
        } else {
            return "Rest day recommended"
        }
    }
}
