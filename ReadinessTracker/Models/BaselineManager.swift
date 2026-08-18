import Foundation

/// Manages personalized baselines using adaptive 7/14/30-day windows.
/// HRV varies 10x between individuals — personal baselines are essential.
enum BaselineManager {
    
    static func baseline(for values: [Double], window: Int = 14) -> Double? {
        let recent = values.filter { $0 > 0 }.suffix(window)
        guard recent.count >= 3 else { return nil }
        return recent.reduce(0, +) / Double(recent.count)
    }
    
    static func standardDeviation(for values: [Double], window: Int = 14) -> Double? {
        let recent = values.filter { $0 > 0 }.suffix(window)
        guard recent.count >= 3 else { return nil }
        let mean = recent.reduce(0, +) / Double(recent.count)
        let variance = recent.map { pow($0 - mean, 2) }.reduce(0, +) / Double(recent.count)
        return sqrt(variance)
    }
    
    static func isOutlier(value: Double, baseline: Double, stdDev: Double, threshold: Double = 2.0) -> Bool {
        guard stdDev > 0 else { return false }
        return abs(value - baseline) > threshold * stdDev
    }
    
    static func hrvBaseline(from history: [DailyHealthData], window: Int = 14, matchesRMSSD: Bool? = nil) -> Double {
        let filtered: [DailyHealthData]
        if let matchesRMSSD = matchesRMSSD {
            filtered = history.filter { $0.hrvIsRMSSD == matchesRMSSD }
        } else {
            filtered = history
        }
        guard filtered.count >= 3,
              let matchingBaseline = baseline(for: filtered.map(\.hrv), window: window) else {
            return baseline(for: history.map(\.hrv), window: window) ?? 50.0
        }
        return matchingBaseline
    }
    
    static func rhrBaseline(from history: [DailyHealthData], window: Int = 14) -> Double {
        baseline(for: history.map(\.restingHeartRate), window: window) ?? 60.0
    }
    
    static func sleepBaseline(from history: [DailyHealthData], window: Int = 7) -> Double {
        baseline(for: history.map(\.sleepHours), window: window) ?? 7.5
    }
    
    static func respiratoryRateBaseline(from history: [DailyHealthData], window: Int = 14) -> Double {
        baseline(for: history.compactMap(\.respiratoryRate), window: window) ?? 16.0
    }
    
    static func skinTempBaseline(from history: [DailyHealthData], window: Int = 14) -> Double? {
        baseline(for: history.compactMap(\.skinTemperature), window: window)
    }
    
    /// Calculate sleep schedule consistency (bedtime variance)
    /// Returns 0-100 where 100 = perfectly consistent ±30min
    static func consistencyScore(from history: [DailyHealthData]) -> Int {
        guard history.count >= 3 else { return 75 }
        
        let calendar = Calendar.current
        var bedtimes: [Int] = [] // Minutes from midnight
        
        for data in history {
            let components = calendar.dateComponents([.hour, .minute], from: data.sleepStartTime ?? data.date)
            let minutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            bedtimes.append(minutes)
        }
        
        guard bedtimes.count >= 3 else { return 75 }
        
        let mean = Double(bedtimes.reduce(0, +)) / Double(bedtimes.count)
        let variance = bedtimes.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(bedtimes.count)
        let stdDev = sqrt(variance)
        
        // ±30 min = 100, ±2h = 0
        let score = max(0, min(100, Int(100 - (stdDev / 1.5))))
        return score
    }
}
