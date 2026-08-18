import Foundation

struct StrainRecoveryBalance {
    let score: Int        // 0-100
    let status: String    // "Balanced", "Moderate Load", "Overreaching Risk", "Rest Needed"

    static func compute(recovery: Int, strain: Double) -> StrainRecoveryBalance {
        let normalizedStrain = (strain / 21.0) * 100.0
        let raw = Double(recovery) - normalizedStrain
        let score = Int(min(100.0, max(0.0, raw + 50.0)))

        let status: String
        switch score {
        case 75...100:
            status = "Balanced"
        case 50..<75:
            status = "Moderate Load"
        case 25..<50:
            status = "Overreaching Risk"
        default:
            status = "Rest Needed"
        }

        return StrainRecoveryBalance(score: score, status: status)
    }
}
