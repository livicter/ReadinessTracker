import SwiftUI

struct QuickTrend {
    let window: Int
    let average: Double
    let percentChange: Double
    let hasPriorWindow: Bool
    let strength: TrendAnalysisEngine.TrendStrength
    let sparkline: [Double]
}

struct QuickTrendCard: View {
    let metric: MetricType
    let history: [DailyHealthData]
    let window: Int

    private var trend: QuickTrend {
        QuickTrendCard.computeTrend(metric: metric, history: history, window: window)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: metric.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(metric.color)

                        Text(metric.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    Text(trend.strength.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trend.strength.trendColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(trend.strength.trendColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(formattedAverage(trend.average))
                        .font(AppleTheme.cardValue)
                        .foregroundStyle(RTColor.primaryText)

                    Text(metric.unit)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                HStack(spacing: 4) {
                    Image(systemName: percentChangeDirection.systemImage)
                        .font(.caption.weight(.semibold))

                    Text(percentChangeText)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(percentChangeColor)

                if trend.sparkline.count >= 2 {
                    AnimatedSparkline(data: trend.sparkline, color: metric.color)
                        .frame(height: 32)
                } else {
                    // Keep card height consistent when the window has too few samples
                    Text("Not enough data")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RTColor.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
            }
        }
    }

    private var percentChange: Double { trend.percentChange }

    private var percentChangeDirection: TrendDirection {
        percentChange > 0 ? .up : percentChange < 0 ? .down : .flat
    }

    private var percentChangeText: String {
        guard trend.hasPriorWindow else { return "--" }
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", percentChange))% vs prior window"
    }

    private var percentChangeColor: Color {
        if metric.higherIsBetter {
            return percentChange >= 0 ? RTColor.optimal : RTColor.warning
        } else {
            return percentChange >= 0 ? RTColor.warning : RTColor.optimal
        }
    }

    private func formattedAverage(_ value: Double) -> String {
        switch metric {
        case .sleep:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories:
            return "\(Int(value))"
        case .bloodOxygen:
            return String(format: "%.0f", value)
        }
    }

    static func computeTrend(metric: MetricType, history: [DailyHealthData], window: Int) -> QuickTrend {
        let values = history.compactMap { metricValue($0, metric: metric) }
        let current = Array(values.suffix(window))
        let previous = Array(values.dropLast(window).suffix(window))

        let currentAvg = current.reduce(0, +) / Double(max(1, current.count))
        let previousAvg = previous.reduce(0, +) / Double(max(1, previous.count))
        let hasPriorWindow = !previous.isEmpty
        let percentChange = previousAvg > 0 ? (currentAvg - previousAvg) / previousAvg * 100 : 0

        let (slope, rSquared, _) = TrendAnalysisEngine.linearRegression(values: current)
        let strength = TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: rSquared, metric: metric)

        return QuickTrend(
            window: window,
            average: currentAvg,
            percentChange: percentChange,
            hasPriorWindow: hasPriorWindow,
            strength: strength,
            sparkline: current
        )
    }

    static func metricValue(_ data: DailyHealthData, metric: MetricType) -> Double? {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen
        }
    }
}

extension TrendAnalysisEngine.TrendStrength {
    var trendColor: Color {
        switch self {
        case .strongUp, .moderateUp:
            return RTColor.optimal
        case .flat:
            return RTColor.tertiaryText
        case .moderateDown, .strongDown:
            return RTColor.warning
        }
    }
}
