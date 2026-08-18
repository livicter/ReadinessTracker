import Foundation

enum HRVCalculator {
    /// Root mean square of successive differences (RMSSD) in milliseconds.
    static func rmssd(from rrIntervalsMs: [Double]) -> Double? {
        guard rrIntervalsMs.count >= 2 else { return nil }
        let diffs = zip(rrIntervalsMs.dropFirst(), rrIntervalsMs).map { $0 - $1 }
        let squared = diffs.map { $0 * $0 }
        let mean = squared.reduce(0, +) / Double(squared.count)
        return sqrt(mean)
    }

    /// Standard deviation of NN intervals (SDNN) in milliseconds.
    static func sdnn(from rrIntervalsMs: [Double]) -> Double? {
        guard rrIntervalsMs.count >= 2 else { return nil }
        let mean = rrIntervalsMs.reduce(0, +) / Double(rrIntervalsMs.count)
        let variance = rrIntervalsMs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(rrIntervalsMs.count)
        return sqrt(variance)
    }
}
