import Foundation
import SwiftUI

enum SleepStage: String, Codable, CaseIterable {
    case awake, light, deep, rem

    var label: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light"
        case .deep: return "Deep"
        case .rem: return "REM"
        }
    }

    /// Matches existing stage colors used across SleepAnalysisView / DayDetailView.
    var color: Color {
        switch self {
        case .awake: return RTColor.warning
        case .light: return Color.blue.opacity(0.5)
        case .deep: return RTColor.sleep
        case .rem: return Color.cyan
        }
    }

    /// Hypnogram vertical rank: Awake on top (0), Deep at the bottom (3).
    var depthRank: Int {
        switch self {
        case .awake: return 0
        case .rem: return 1
        case .light: return 2
        case .deep: return 3
        }
    }
}

struct SleepStageInterval: Codable, Hashable, Identifiable {
    let stage: SleepStage
    let startDate: Date
    let endDate: Date

    var id: Date { startDate }

    var durationMinutes: Double {
        endDate.timeIntervalSince(startDate) / 60
    }
}

extension SleepStageInterval {
    /// Maps raw HKCategoryValueSleepAnalysis values. Returns nil for `.inBed`
    /// and unknown values (no stage interval should be recorded for them).
    static func stage(forHealthKitValue rawValue: Int) -> SleepStage? {
        switch rawValue {
        case 0: return .awake          // .awake
        case 1: return .light          // .asleepUnspecified
        case 3: return .light          // .asleepCore
        case 4: return .deep           // .asleepDeep
        case 5: return .rem            // .asleepREM
        default: return nil            // .inBed (2), unknown
        }
    }
}
