import Foundation

/// Real data science analysis on user's actual health data.
/// No mock data, no guessing — pure statistical operations on stored history.
struct TrendAnalysisEngine {
    
    // MARK: - Moving Averages
    
    /// Simple moving average over N days
    static func movingAverage(values: [Double], window: Int) -> [Double] {
        guard values.count >= window else { return [] }
        var result: [Double] = []
        for i in (window - 1)..<values.count {
            let slice = values[(i - window + 1)...i]
            result.append(slice.reduce(0, +) / Double(slice.count))
        }
        return result
    }
    
    /// Exponential moving average — weights recent data more heavily
    /// Alpha = 2 / (window + 1), standard smoothing factor
    static func exponentialMovingAverage(values: [Double], window: Int) -> [Double] {
        guard values.count >= 2 else { return values }
        let alpha = 2.0 / (Double(window) + 1)
        var result: [Double] = [values[0]]
        
        for i in 1..<values.count {
            let ema = alpha * values[i] + (1 - alpha) * result[i - 1]
            result.append(ema)
        }
        return result
    }
    
    // MARK: - Standard Deviation & Variance
    
    static func standardDeviation(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    static func mean(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Baseline Deviation
    
    /// How many standard deviations from personal baseline
    /// Positive = above baseline, Negative = below baseline
    static func zScore(value: Double, baseline: Double, stdDev: Double) -> Double {
        guard stdDev > 0 else { return 0 }
        return (value - baseline) / stdDev
    }
    
    /// Percentage deviation from baseline
    static func percentDeviation(value: Double, baseline: Double) -> Double {
        guard baseline > 0 else { return 0 }
        return (value - baseline) / baseline
    }
    
    // MARK: - Rate of Change / Momentum
    
    /// Day-over-day rate of change as percentage
    static func rateOfChange(values: [Double]) -> [Double] {
        guard values.count >= 2 else { return [] }
        var result: [Double] = []
        for i in 1..<values.count {
            let prev = values[i - 1]
            guard prev > 0 else {
                result.append(0)
                continue
            }
            result.append((values[i] - prev) / prev)
        }
        return result
    }
    
    /// Momentum: rate of change over a longer window (e.g. 7-day ROC)
    static func momentum(values: [Double], window: Int) -> [Double] {
        guard values.count > window else { return [] }
        var result: [Double] = []
        for i in window..<values.count {
            let prev = values[i - window]
            guard prev > 0 else {
                result.append(0)
                continue
            }
            result.append((values[i] - prev) / prev)
        }
        return result
    }
    
    // MARK: - Trend Direction & Strength
    
    enum TrendStrength: String {
        case strongUp = "Strong Up"
        case moderateUp = "Improving"
        case flat = "Stable"
        case moderateDown = "Declining"
        case strongDown = "Strong Down"
        
        var color: String {
            switch self {
            case .strongUp: return "optimal"
            case .moderateUp: return "good"
            case .flat: return "neutral"
            case .moderateDown: return "caution"
            case .strongDown: return "warning"
            }
        }
    }
    
    /// Linear regression slope on recent data to determine trend strength
    /// Returns slope (units per day) and r-squared (goodness of fit)
    static func linearRegression(values: [Double]) -> (slope: Double, rSquared: Double, intercept: Double) {
        guard values.count >= 3 else { return (0, 0, 0) }
        
        let n = Double(values.count)
        let x = Array(0..<values.count).map(Double.init)
        let y = values
        
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        _ = y.map { $0 * $0 }.reduce(0, +)
        
        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return (0, 0, 0) }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        // R-squared
        let yMean = sumY / n
        let ssTotal = y.map { pow($0 - yMean, 2) }.reduce(0, +)
        let ssResidual = y.enumerated().map { i, val in
            let predicted = intercept + slope * Double(i)
            return pow(val - predicted, 2)
        }.reduce(0.0, +)
        let rSquared = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0
        
        return (slope, max(0, rSquared), intercept)
    }
    
    /// Classify trend strength based on slope magnitude and r-squared confidence
    static func classifyTrend(slope: Double, rSquared: Double, metric: MetricType) -> TrendStrength {
        // Normalize slope as percentage change per day relative to typical values
        let normalizedSlope: Double
        switch metric {
        case .sleep: normalizedSlope = slope / 7.5 * 100  // % of typical sleep
        case .hrv: normalizedSlope = slope / 50.0 * 100   // % of typical HRV
        case .restingHR: normalizedSlope = slope / 60.0 * 100
        case .activeCalories: normalizedSlope = slope / 400.0 * 100
        case .bloodOxygen: normalizedSlope = slope / 5.0 * 100
        }
        
        // Only trust trend if r-squared > 0.3 (some correlation)
        guard rSquared > 0.15 else { return .flat }
        
        let absSlope = abs(normalizedSlope)
        let isUp = normalizedSlope > 0
        
        // For metrics where lower is better, invert direction interpretation
        let isGoodDirection = metric.higherIsBetter ? isUp : !isUp
        
        switch absSlope {
        case 0..<1.5: return .flat
        case 1.5..<4:
            return isGoodDirection ? .moderateUp : .moderateDown
        default:
            return isGoodDirection ? .strongUp : .strongDown
        }
    }
    
    // MARK: - Volatility
    
    /// Coefficient of variation (stdDev / mean) — normalized volatility
    static func coefficientOfVariation(values: [Double]) -> Double {
        let m = mean(values: values)
        guard m > 0 else { return 0 }
        return standardDeviation(values: values) / m
    }
    
    /// Rolling volatility over a window
    static func rollingVolatility(values: [Double], window: Int) -> [Double] {
        guard values.count >= window else { return [] }
        var result: [Double] = []
        for i in (window - 1)..<values.count {
            let slice = Array(values[(i - window + 1)...i])
            result.append(coefficientOfVariation(values: slice))
        }
        return result
    }
    
    // MARK: - Weekly Patterns
    
    /// Average value per day of week (0=Sunday, 6=Saturday)
    static func weeklyPattern(values: [(date: Date, value: Double)]) -> [Int: Double] {
        var byDay: [Int: [Double]] = [:]
        let calendar = Calendar.current
        
        for point in values {
            let weekday = calendar.component(.weekday, from: point.date) - 1  // 0-indexed
            byDay[weekday, default: []].append(point.value)
        }
        
        var result: [Int: Double] = [:]
        for (day, vals) in byDay {
            result[day] = vals.reduce(0, +) / Double(vals.count)
        }
        return result
    }
    
    // MARK: - Correlation
    
    /// Pearson correlation coefficient between two metric series
    /// -1 = perfect inverse, 0 = no correlation, 1 = perfect correlation
    static func pearsonCorrelation(x: [Double], y: [Double]) -> Double {
        guard x.count == y.count, x.count >= 3 else { return 0 }
        
        let meanX = mean(values: x)
        let meanY = mean(values: y)
        
        let numerator = zip(x, y).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
        let sumSqX = x.map { pow($0 - meanX, 2) }.reduce(0, +)
        let sumSqY = y.map { pow($0 - meanY, 2) }.reduce(0, +)
        
        let denominator = sqrt(sumSqX * sumSqY)
        guard denominator > 0 else { return 0 }
        
        return numerator / denominator
    }
    
    // MARK: - Recovery Analysis
    
    /// Analyze how a metric recovers after high-strain days
    /// Returns day-by-day values following strain days above threshold
    static func recoveryTrajectory(
        metricValues: [(date: Date, value: Double)],
        strainValues: [(date: Date, value: Double)],
        strainThreshold: Double,
        recoveryWindow: Int = 5
    ) -> [Int: [Double]] {
        // strainThreshold: e.g. 500 calories or 60 min workout
        var trajectories: [Int: [Double]] = [:]  // day offset -> [values]
        
        for i in 0..<(strainValues.count - 1) {
            let strainDay = strainValues[i]
            guard strainDay.value >= strainThreshold else { continue }
            
            // Find metric values for subsequent days
            for offset in 1...recoveryWindow {
                let targetIndex = i + offset
                guard targetIndex < metricValues.count else { break }
                
                let metricValue = metricValues[targetIndex].value
                trajectories[offset, default: []].append(metricValue)
            }
        }
        
        return trajectories
    }
    
    // MARK: - Zone Distribution
    
    /// How much time spent in each zone
    static func zoneDistribution(values: [Double], zones: [(range: ClosedRange<Double>, label: String)]) -> [(label: String, count: Int, percentage: Double)] {
        guard !values.isEmpty else { return [] }
        
        var counts: [String: Int] = [:]
        for value in values {
            for zone in zones {
                if zone.range.contains(value) {
                    counts[zone.label, default: 0] += 1
                    break
                }
            }
        }
        
        return counts.map { (label: $0.key, count: $0.value, percentage: Double($0.value) / Double(values.count)) }
            .sorted { $0.percentage > $1.percentage }
    }
}

// MARK: - Data Point for Charts

/// A single analyzed data point with all computed fields for visualization
struct AnalyzedDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rawValue: Double
    let baseline: Double
    let movingAverage7: Double?
    let movingAverage14: Double?
    let ema7: Double?
    let zScore: Double
    let percentDeviation: Double
    let rateOfChange: Double?
    let trendSlope: Double?
    let trendRSquared: Double?
    let volatility: Double?
    let isOutlier: Bool
}

/// Factory to create analyzed points from raw history
extension TrendAnalysisEngine {
    
    static func analyze(
        history: [(date: Date, value: Double)],
        metric: MetricType
    ) -> [AnalyzedDataPoint] {
        guard history.count >= 2 else { return [] }
        
        let values = history.map { $0.value }
        
        // Compute all series
        let ma7 = movingAverage(values: values, window: 7)
        let ma14 = movingAverage(values: values, window: 14)
        let ema7 = exponentialMovingAverage(values: values, window: 7)
        let roc = rateOfChange(values: values)
        let vol = rollingVolatility(values: values, window: 7)
        
        // Overall baseline (30-day or all available)
        let baseline = mean(values: values)
        let stdDev = standardDeviation(values: values)
        
        // Linear regression on all data
        let (slope, rSquared, _) = linearRegression(values: values)
        
        return history.enumerated().map { i, point in
            let value = point.value
            let z = zScore(value: value, baseline: baseline, stdDev: stdDev)
            
            // MA7 index: starts at window-1
            let ma7Index = i - 6
            let ma14Index = i - 13
            
            return AnalyzedDataPoint(
                date: point.date,
                rawValue: value,
                baseline: baseline,
                movingAverage7: ma7Index >= 0 && ma7Index < ma7.count ? ma7[ma7Index] : nil,
                movingAverage14: ma14Index >= 0 && ma14Index < ma14.count ? ma14[ma14Index] : nil,
                ema7: i < ema7.count ? ema7[i] : nil,
                zScore: z,
                percentDeviation: percentDeviation(value: value, baseline: baseline),
                rateOfChange: i > 0 && (i - 1) < roc.count ? roc[i - 1] : nil,
                trendSlope: i == history.count - 1 ? slope : nil,  // Only on last point
                trendRSquared: i == history.count - 1 ? rSquared : nil,
                volatility: i >= 6 && (i - 6) < vol.count ? vol[i - 6] : nil,
                isOutlier: abs(z) > 2
            )
        }
    }
}
