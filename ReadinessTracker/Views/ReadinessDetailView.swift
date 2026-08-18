import SwiftUI
import Charts

/// Full readiness score detail — tapped from Dashboard hero ring.
/// Shows all three scores (general, cognitive, gym) with breakdowns and history.
struct ReadinessDetailView: View {
    let scores: DualReadinessScores
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                // Triple score hero
                tripleScoreHero
                
                // Score breakdown bars
                scoreBreakdown
                
                // Score history chart
                scoreHistoryChart
                
                // Component breakdown
                componentBreakdown
                
                // Recommendation
                recommendationCard
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .navigationTitle("Readiness Detail")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Triple Score Hero
    private var tripleScoreHero: some View {
        NativeCard {
            VStack(spacing: 24) {
                TripleRingHero(
                    gymScore: scores.gym,
                    workScore: scores.cognitive,
                    sleepScore: scores.breakdown.sleepScore,
                    size: 220
                )
                
                HStack(spacing: 16) {
                    ScorePill(label: "General", score: scores.general, color: RTColor.optimal)
                    ScorePill(label: "Cognitive", score: scores.cognitive, color: RTColor.hrv)
                    ScorePill(label: "Gym", score: scores.gym, color: RTColor.strain)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Score Breakdown
    private var scoreBreakdown: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Score Breakdown")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                VStack(spacing: 14) {
                    BreakdownBar(label: "Sleep", score: scores.breakdown.sleepScore, color: RTColor.sleep, weight: "25%", metricType: .sleep, currentValue: data.sleepHours, history: history, source: data.source)
                    BreakdownBar(label: data.hrvIsRMSSD ? "RMSSD" : "HRV", score: scores.breakdown.hrvScore, color: RTColor.hrv, weight: "25%", metricType: .hrv, currentValue: data.hrv, history: history, source: data.source)
                    BreakdownBar(label: "Recovery", score: scores.breakdown.recoveryScore, color: RTColor.recovery, weight: "20%", metricType: .restingHR, currentValue: data.restingHeartRate, history: history, source: data.source)
                    BreakdownBar(label: "Strain", score: scores.breakdown.strainScore, color: RTColor.strain, weight: "15%", metricType: .activeCalories, currentValue: data.activeCalories, history: history, source: data.source)
                    BreakdownBar(label: "Consistency", score: scores.breakdown.consistencyScore, color: RTColor.consistency, weight: "10%", metricType: .sleep, currentValue: data.sleepHours, history: history, source: data.source)
                    BreakdownBar(label: "SpO2", score: scores.breakdown.spo2Score, color: RTColor.optimal, weight: "5%", metricType: .bloodOxygen, currentValue: (data.bloodOxygen ?? 0) > 1.0 ? (data.bloodOxygen ?? 0) : (data.bloodOxygen ?? 0) * 100.0, history: history, source: data.source)
                }
                
                Divider()
                    .background(RTColor.divider)
                
                HStack {
                    Text("Total")
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Text("\(scores.breakdown.totalScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(ScoreZone(score: scores.breakdown.totalScore).color)
                }
            }
        }
    }
    
    // MARK: - Score History Chart
    private var scoreHistoryChart: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Score History")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                if history.count >= 2 {
                    Chart(history) { day in
                        let generalScore = ReadinessCalculator.calculateBreakdown(from: day, history: history).totalScore
                        
                        LineMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("General", generalScore)
                        )
                        .foregroundStyle(RTColor.optimal)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        AreaMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("General", generalScore)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RTColor.optimal.opacity(0.2), RTColor.optimal.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", day.date, unit: .day),
                            y: .value("General", generalScore)
                        )
                        .foregroundStyle(day.id == data.id ? RTColor.optimal : RTColor.optimal.opacity(0.4))
                        .symbolSize(day.id == data.id ? 80 : 40)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...100)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundStyle(RTColor.surfaceHighlight)

                        Text("Not Enough Data")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)

                        Text("Score history appears once at least 2 days are recorded")
                            .font(.caption)
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Component Breakdown
    private var componentBreakdown: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Component Detail")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                VStack(spacing: 12) {
                    ComponentRow(
                        icon: "bed.double.fill",
                        label: "Sleep Duration",
                        value: String(format: "%.1f", data.sleepHours),
                        unit: "h",
                        color: RTColor.sleep,
                        contribution: scores.breakdown.sleepScore
                    )
                    
                    ComponentRow(
                        icon: "waveform.path.ecg",
                        label: "Heart Rate Variability",
                        value: "\(Int(data.hrv))",
                        unit: "ms",
                        color: RTColor.hrv,
                        contribution: scores.breakdown.hrvScore
                    )
                    
                    ComponentRow(
                        icon: "heart.fill",
                        label: "Resting Heart Rate",
                        value: "\(Int(data.restingHeartRate))",
                        unit: "bpm",
                        color: RTColor.recovery,
                        contribution: scores.breakdown.recoveryScore
                    )
                    
                    ComponentRow(
                        icon: "flame.fill",
                        label: "Active Calories",
                        value: "\(Int(data.activeCalories))",
                        unit: "cal",
                        color: RTColor.strain,
                        contribution: scores.breakdown.strainScore
                    )
                    
                    ComponentRow(
                        icon: "clock.arrow.circlepath",
                        label: "Sleep Consistency",
                        value: "\(scores.breakdown.consistencyScore)",
                        unit: "pts",
                        color: RTColor.consistency,
                        contribution: scores.breakdown.consistencyScore
                    )
                    
                    let spo2Display = (data.bloodOxygen ?? 0) > 1.0 ? (data.bloodOxygen ?? 0) : (data.bloodOxygen ?? 0) * 100.0
                    ComponentRow(
                        icon: "drop.fill",
                        label: "Blood Oxygen",
                        value: "\(Int(spo2Display))",
                        unit: "%",
                        color: RTColor.optimal,
                        contribution: scores.breakdown.spo2Score
                    )
                    
                    ComponentRow(
                        icon: "thermometer",
                        label: "Skin Temp",
                        value: data.skinTemperature.map { String(format: "%.2f", $0) } ?? "--",
                        unit: "°C",
                        color: RTColor.secondaryText,
                        contribution: scores.breakdown.tempScore
                    )
                    
                    ComponentRow(
                        icon: "lungs.fill",
                        label: "Respiratory Rate",
                        value: data.respiratoryRate.map { String(format: "%.1f", $0) } ?? "--",
                        unit: "bpm",
                        color: RTColor.secondaryText,
                        contribution: scores.breakdown.respScore
                    )
                }
            }
        }
    }
    
    // MARK: - Recommendation
    private var recommendationCard: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(RTColor.caution)
                    
                    Text("Recommendation")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                
                Text(scores.recommendation())
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Score Pill
private struct ScorePill: View {
    let label: String
    let score: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Component Row
private struct ComponentRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    let contribution: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)

                Text("\(value) \(unit)")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }

            Spacer()

            Text("\(contribution)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surface)
        )
    }
}
