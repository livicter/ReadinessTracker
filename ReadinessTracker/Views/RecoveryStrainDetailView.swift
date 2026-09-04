import SwiftUI
import Charts

/// Full recovery & strain detail — tapped from Dashboard WHOOP section.
/// Shows strain/recovery wheel breakdown, sleep performance, and advanced metrics.
struct RecoveryStrainDetailView: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    let scores: DualReadinessScores
    
    @Environment(\.dismiss) private var dismiss

    // Precomputed once at init so calculators don't run per chart point per render.
    private let balanceHistory: [(date: Date, score: Int)]
    private let historicalStrainData: [(date: Date, strain: Double, recovery: Int)]

    init(data: DailyHealthData, history: [DailyHealthData], scores: DualReadinessScores) {
        self.data = data
        self.history = history
        self.scores = scores
        self.balanceHistory = history.suffix(7).map { day in
            let recovery = ReadinessCalculator.calculateBreakdown(from: day, history: history).totalScore
            let strain = StrainCalculator.calculate(from: day, history: history)
            return (day.date, StrainRecoveryBalance.compute(recovery: recovery, strain: strain).score)
        }
        self.historicalStrainData = history.map { day in
            let recovery = ReadinessCalculator.calculateBreakdown(from: day, history: history).totalScore
            let strain = StrainCalculator.calculate(from: day, history: history)
            return (day.date, strain, recovery)
        }
    }

    private var strainScore: Double {
        scores.breakdown.strainScoreValue
    }

    private var balance: StrainRecoveryBalance {
        StrainRecoveryBalance.compute(recovery: scores.general, strain: strainScore)
    }
    
    private var sleepBaseline: Double {
        BaselineManager.sleepBaseline(from: history)
    }
    
    private var sleepConsistency: Double {
        guard history.count >= 3 else { return 50 }
        let sleepHours = history.map { $0.sleepHours }
        let mean = sleepHours.reduce(0, +) / Double(sleepHours.count)
        let variance = sleepHours.map { pow($0 - mean, 2) }.reduce(0, +) / Double(sleepHours.count)
        let stdDev = sqrt(variance)
        return max(0, min(100, 100 - stdDev * 30))
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                // Strain/Recovery wheel
                wheelSection
                    .slideIn(delay: 0)

                balanceChartSection
                    .slideIn(delay: 0.05)
                
                // Strain detail
                strainDetail
                    .slideIn(delay: 0.1)
                
                // Recovery detail
                recoveryDetail
                    .slideIn(delay: 0.15)
                
                // Sleep performance
                SleepPerformanceScore(
                    sleepNeeded: sleepBaseline * 1.1,
                    sleepObtained: data.sleepHours,
                    efficiency: data.sleepEfficiency * 100,
                    consistency: sleepConsistency
                )
                .slideIn(delay: 0.2)
                
                // Nutrition
                nutritionSection
                    .slideIn(delay: 0.25)
                
                // Advanced metrics
                advancedMetrics
                    .slideIn(delay: 0.3)
                
                // Workouts
                workoutSection
                    .slideIn(delay: 0.35)
                
                // Strain vs Recovery history
                strainRecoveryHistory
                    .slideIn(delay: 0.4)
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .navigationTitle("Recovery & Strain")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
    }
    
    // MARK: - Wheel Section
    private var wheelSection: some View {
        NativeCard {
            VStack(spacing: 20) {
                ZStack {
                    // Background rings
                    Circle()
                        .stroke(RTColor.surfaceHighlight, lineWidth: 20)
                    Circle()
                        .stroke(RTColor.surfaceHighlight, lineWidth: 14)
                        .padding(20)
                    
                    // Strain ring fills proportionally to strain/21
                    Circle()
                        .trim(from: 0, to: CGFloat(min(strainScore / 21, 1.0)))
                        .stroke(RTColor.caution, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    // Recovery ring fills proportionally to recovery/100
                    Circle()
                        .trim(from: 0, to: CGFloat(min(Double(scores.general) / 100, 1.0)))
                        .stroke(RTColor.optimal, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .padding(20)
                }
                .frame(width: 200, height: 200)
                .padding(.vertical, 10)
                
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(Int(strainScore))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.caution)
                        Text("Strain")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(scores.general)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(RTColor.optimal)
                        Text("Recovery")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
                
                StrainRecoveryBalanceCard(balance: balance)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Balance Chart Section
    private var balanceChartSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("7-Day Balance")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)

                if balanceHistory.count >= 2 {
                    Chart(balanceHistory, id: \.date) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Balance", item.score)
                        )
                        .foregroundStyle(
                            item.score >= 75 ? RTColor.optimal :
                            item.score >= 50 ? RTColor.good :
                            item.score >= 25 ? RTColor.caution : RTColor.warning
                        )
                        .cornerRadius(4, style: .continuous)
                    }
                    .frame(height: 140)
                    .chartYScale(domain: 0...100)
                } else {
                    Text("Need more data")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Strain Detail
    private var strainDetail: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Strain Breakdown")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    
                    Spacer()
                    
                    Text("0-21 scale")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
                
                VStack(spacing: 12) {
                    if !data.hrSamples.isEmpty {
                        let rawTRIMP = StrainCalculator.sampleStrain(from: data)
                        StrainRow(
                            icon: "heart.fill",
                            label: "Cardiovascular",
                            value: "\(String(format: "%.0f", rawTRIMP))",
                            unit: "TRIMP",
                            contribution: strainScore,
                            maxContribution: 21,
                            color: RTColor.warning
                        )
                    } else {
                        StrainRow(
                            icon: "flame.fill",
                            label: "Active Calories",
                            value: "\(Int(data.activeCalories))",
                            unit: "cal",
                            contribution: min(15, data.activeCalories / 200),
                            maxContribution: 15,
                            color: RTColor.caution
                        )
                        
                        StrainRow(
                            icon: "dumbbell.fill",
                            label: "Workout Duration",
                            value: "\(data.workoutMinutes)",
                            unit: "min",
                            contribution: min(6, Double(data.workoutMinutes) / 30),
                            maxContribution: 6,
                            color: RTColor.strain
                        )
                    }
                }
                
                // Total strain bar
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Total Strain")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.primaryText)
                        Spacer()
                        Text("\(String(format: "%.1f", strainScore)) / 21")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(strainColor)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(RTColor.surfaceHighlight)
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(strainColor)
                                .frame(width: geo.size.width * CGFloat(strainScore / 21), height: 10)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var strainColor: Color {
        switch strainScore {
        case 0..<7: return RTColor.optimal
        case 7..<14: return RTColor.good
        case 14..<18: return RTColor.caution
        default: return RTColor.warning
        }
    }
    
    // MARK: - Recovery Detail
    private var recoveryDetail: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recovery Factors")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                VStack(spacing: 12) {
                    RecoveryFactorRow(
                        icon: "bed.double.fill",
                        label: "Sleep Quality",
                        score: scores.breakdown.sleepScore,
                        color: RTColor.sleep
                    )
                    
                    RecoveryFactorRow(
                        icon: "waveform.path.ecg",
                        label: "HRV Status",
                        score: scores.breakdown.hrvScore,
                        color: RTColor.hrv
                    )
                    
                    RecoveryFactorRow(
                        icon: "heart.fill",
                        label: "Resting HR",
                        score: scores.breakdown.recoveryScore,
                        color: RTColor.recovery
                    )
                    
                    RecoveryFactorRow(
                        icon: "clock.arrow.circlepath",
                        label: "Consistency",
                        score: scores.breakdown.consistencyScore,
                        color: RTColor.consistency
                    )
                }
            }
        }
    }
    
    // MARK: - Nutrition
    private var nutritionSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Nutrition")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                if data.nutrition.isEmpty {
                    Text("No nutrition data")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 12) {
                        if let water = data.nutrition.waterLiters {
                            NutritionRow(icon: "drop.fill", label: "Water", value: String(format: "%.1f", water), unit: "L", color: .cyan)
                        }
                        if let caffeine = data.nutrition.caffeineMg {
                            NutritionRow(icon: "cup.and.saucer.fill", label: "Caffeine", value: "\(Int(caffeine))", unit: "mg", color: RTColor.caution)
                        }
                        if let protein = data.nutrition.proteinGrams {
                            NutritionRow(icon: "fork.knife", label: "Protein", value: "\(Int(protein))", unit: "g", color: RTColor.good)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Metrics
    private var advancedMetrics: some View {
        VStack(spacing: AppleTheme.cardPadding) {
            SectionHeader(title: "Advanced Metrics")
            
            HStack(spacing: 12) {
                if let respRate = data.respiratoryRate {
                    RespiratoryRateCard(
                        currentRate: respRate,
                        history: history.compactMap { d in
                            d.respiratoryRate.map { (d.date, $0) }
                        },
                        baseline: history.compactMap { $0.respiratoryRate }.reduce(0, +) / Double(max(1, history.compactMap { $0.respiratoryRate }.count))
                    )
                }
                
                if let skinTemp = data.skinTemperature {
                    let tempHistory = history.compactMap { d in
                        d.skinTemperature.map { (date: d.date, value: $0) }
                    }
                    let baseline = tempHistory.map { $0.value }.reduce(0, +) / Double(max(1, tempHistory.count))
                    SkinTemperatureCard(
                        currentTemp: skinTemp,
                        baselineTemp: baseline > 0 ? baseline : skinTemp,
                        history: tempHistory
                    )
                }
            }
        }
    }
    
    // MARK: - Workouts
    private var workoutSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Workouts")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                if data.strainSessions.isEmpty {
                    Text("No recorded workouts")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 12) {
                        ForEach(data.strainSessions) { session in
                            WorkoutRow(session: session, trimp: session.trimp)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Strain vs Recovery History
    private var strainRecoveryHistory: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Strain vs Recovery")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                if historicalStrainData.count >= 2 {
                    Chart(historicalStrainData, id: \.date) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Recovery", item.recovery)
                        )
                        .foregroundStyle(RTColor.optimal.opacity(0.6))
                        .cornerRadius(4, style: .continuous)
                        
                        LineMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Strain", item.strain * 100 / 21)
                        )
                        .foregroundStyle(RTColor.caution)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 180)
                    .chartYScale(domain: 0...100)
                    
                    HStack(spacing: 16) {
                        LegendDot(label: "Recovery", color: RTColor.optimal, style: .solid)
                        LegendDot(label: "Strain (scaled)", color: RTColor.caution, style: .solid)
                    }
                } else {
                    Text("Need more data")
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Strain Row
private struct StrainRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let contribution: Double?
    let maxContribution: Double
    let color: Color

    var body: some View {
        let base = unit.isEmpty ? value : "\(value) \(unit)"
        let display = contribution.map { "\(base)  +\(String(format: "%.1f", $0))" } ?? base
        AppListRow(icon: icon, color: color, label: label, value: display, showChevron: false)
    }
}

// MARK: - Nutrition Row
private struct NutritionRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        AppListRow(icon: icon, color: color, label: label, value: "\(value) \(unit)", showChevron: false)
    }
}

// MARK: - Recovery Factor Row
private struct RecoveryFactorRow: View {
    let icon: String
    let label: String
    let score: Int
    let color: Color

    var body: some View {
        AppListRow(icon: icon, color: color, label: label, value: "\(score)", showChevron: false)
    }
}

// MARK: - Workout Row
private struct WorkoutRow: View {
    let session: StrainSession
    let trimp: Double

    var body: some View {
        AppListRow(
            icon: "figure.run",
            color: RTColor.strain,
            label: session.workoutType,
            value: "\(Int(session.durationMinutes)) min · \(Int(trimp)) TRIMP",
            showChevron: false
        )
    }
}
