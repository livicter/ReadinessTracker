import Foundation

struct SleepCycle: Hashable, Identifiable {
    let startDate: Date
    let endDate: Date
    let deepMinutes: Double
    let remMinutes: Double
    let lightMinutes: Double

    var id: Date { startDate }
    var durationMinutes: Double { endDate.timeIntervalSince(startDate) / 60 }
}

/// Detects sleep cycles from raw stage intervals.
/// A cycle ends when an awake gap exceeds `awakeGapThresholdMinutes` (spec: 15 min).
enum SleepCycleDetector {

    static let awakeGapThresholdMinutes: Double = 15

    static func detectCycles(in intervals: [SleepStageInterval]) -> [SleepCycle] {
        let sorted = intervals.sorted { $0.startDate < $1.startDate }
        var cycles: [SleepCycle] = []
        var current: [SleepStageInterval] = []

        func flush() {
            guard !current.isEmpty else { return }
            cycles.append(SleepCycle(
                startDate: current.first!.startDate,
                endDate: current.last!.endDate,
                deepMinutes: current.filter { $0.stage == .deep }.reduce(0) { $0 + $1.durationMinutes },
                remMinutes: current.filter { $0.stage == .rem }.reduce(0) { $0 + $1.durationMinutes },
                lightMinutes: current.filter { $0.stage == .light }.reduce(0) { $0 + $1.durationMinutes }
            ))
            current = []
        }

        for interval in sorted {
            if interval.stage == .awake {
                if interval.durationMinutes > awakeGapThresholdMinutes {
                    flush()
                }
                continue
            }
            current.append(interval)
        }
        flush()
        return cycles
    }

    /// Awake intervals between sleep onset and final wake, for SleepDisturbanceTracker.
    static func awakePeriods(from intervals: [SleepStageInterval]) -> [(start: Date, end: Date)] {
        intervals
            .filter { $0.stage == .awake }
            .sorted { $0.startDate < $1.startDate }
            .map { (start: $0.startDate, end: $0.endDate) }
    }
}
