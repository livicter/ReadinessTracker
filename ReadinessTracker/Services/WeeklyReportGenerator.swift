import Foundation

struct WeeklyReport: Codable {
    let weekStart: Date
    let weekEnd: Date
    let avgReadiness: Double
    let avgGymScore: Double
    let avgWorkScore: Double
    let avgSleepScore: Double
    let avgHRV: Double
    let avgRHR: Double
    let avgStrain: Double
    let totalWorkouts: Int
    let avgWorkoutRPE: Double
    let sleepConsistency: Double
    let readinessTrend: TrendDirection
    let recommendations: [String]
    let highlights: [String]
}

@MainActor
class WeeklyReportGenerator {
    static let shared = WeeklyReportGenerator()
    
    private let calendar = Calendar.current
    
    func generateReport(for source: DataSource) -> WeeklyReport? {
        let history = DataStore.shared.dataForSource(source, days: 7)
        guard history.count >= 3 else { return nil }
        
        let readinessScores = history.map { Double(ReadinessCalculator.calculateBreakdown(from: $0, history: history).totalScore) }
        let hrvs = history.map { Double($0.hrv) }
        let rhrs = history.map { Double($0.restingHeartRate) }
        
        // Calculate averages
        let avgReadiness = readinessScores.reduce(0, +) / Double(readinessScores.count)
        let avgHRV = hrvs.reduce(0, +) / Double(hrvs.count)
        let avgRHR = rhrs.reduce(0, +) / Double(rhrs.count)

        // Strain
        let strains = history.map { StrainCalculator.calculate(from: $0, history: history) }
        let avgStrain = strains.reduce(0, +) / Double(max(1, strains.count))
        
        // Dual scores
        var gymScores: [Double] = []
        var workScores: [Double] = []
        var sleepScores: [Double] = []
        
        for data in history {
            let breakdown = ReadinessCalculator.calculateBreakdown(from: data, history: history)
            let metadata = MetadataStore.shared.metadataFor(date: data.date, timeOfDay: .morning)
            let dual = ReadinessCalculator.calculateDualScores(from: data, history: history, metadata: metadata)
            gymScores.append(Double(dual.gym))
            workScores.append(Double(dual.cognitive))
            sleepScores.append(Double(breakdown.sleepScore))
        }
        
        let avgGym = gymScores.reduce(0, +) / Double(gymScores.count)
        let avgWork = workScores.reduce(0, +) / Double(workScores.count)
        let avgSleep = sleepScores.reduce(0, +) / Double(sleepScores.count)
        
        // Workout stats
        let eveningMetadata = history.compactMap { MetadataStore.shared.metadataFor(date: $0.date, timeOfDay: .evening) }
        let workouts = eveningMetadata.filter { $0.workoutToday == true }
        let totalWorkouts = workouts.count
        let rpeValues = workouts.compactMap { $0.workoutRPE }
        let avgRPE = rpeValues.isEmpty ? 0 : Double(rpeValues.reduce(0, +)) / Double(rpeValues.count)
        
        // Sleep consistency (std dev of sleep hours)
        let sleepHours = history.map { $0.sleepHours }
        let sleepMean = sleepHours.reduce(0, +) / Double(sleepHours.count)
        let sleepVariance = sleepHours.map { pow($0 - sleepMean, 2) }.reduce(0, +) / Double(sleepHours.count)
        let sleepConsistency = max(0, 100 - sqrt(sleepVariance) * 20)
        
        // Trend (compare first half vs second half)
        let half = history.count / 2
        let firstHalf = readinessScores.prefix(half).reduce(0, +) / Double(half)
        let secondHalf = readinessScores.suffix(half).reduce(0, +) / Double(half)
        let trend: TrendDirection = secondHalf > firstHalf + 3 ? .up : secondHalf < firstHalf - 3 ? .down : .flat
        
        // Generate recommendations
        var recommendations: [String] = []
        var highlights: [String] = []
        
        if avgReadiness >= 80 {
            highlights.append("Excellent week! Your readiness averaged \(Int(avgReadiness))%.")
        } else if avgReadiness >= 60 {
            highlights.append("Good week with an average readiness of \(Int(avgReadiness))%.")
        } else {
            recommendations.append("Your readiness was low this week. Prioritize sleep and recovery.")
        }
        
        if avgHRV > 50 {
            highlights.append("Strong HRV recovery capacity (avg \(Int(avgHRV)) ms).")
        } else if avgHRV < 35 {
            recommendations.append("HRV is below baseline. Consider reducing training intensity.")
        }
        
        if sleepConsistency < 70 {
            recommendations.append("Sleep schedule was inconsistent. Try to maintain regular bed/wake times.")
        }
        
        if totalWorkouts >= 4 && avgRPE > 7 {
            recommendations.append("High training load detected. Ensure adequate recovery between sessions.")
        }
        
        if avgWork < 60 {
            recommendations.append("Mental fatigue is elevated. Consider stress management techniques.")
        }
        
        let weekStart = history.first?.date ?? Date()
        let weekEnd = history.last?.date ?? Date()
        
        return WeeklyReport(
            weekStart: weekStart,
            weekEnd: weekEnd,
            avgReadiness: avgReadiness,
            avgGymScore: avgGym,
            avgWorkScore: avgWork,
            avgSleepScore: avgSleep,
            avgHRV: avgHRV,
            avgRHR: avgRHR,
            avgStrain: avgStrain,
            totalWorkouts: totalWorkouts,
            avgWorkoutRPE: avgRPE,
            sleepConsistency: sleepConsistency,
            readinessTrend: trend,
            recommendations: recommendations,
            highlights: highlights
        )
    }
    
    func formattedReport(_ report: WeeklyReport) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        
        var text = "# Weekly Readiness Report\n\n"
        text += "**Week:** \(df.string(from: report.weekStart)) - \(df.string(from: report.weekEnd))\n\n"
        
        text += "## Summary\n"
        text += "- **Average Readiness:** \(Int(report.avgReadiness))%\n"
        text += "- **Gym Readiness:** \(Int(report.avgGymScore))%\n"
        text += "- **Work Readiness:** \(Int(report.avgWorkScore))%\n"
        text += "- **Sleep Score:** \(Int(report.avgSleepScore))%\n"
        text += "- **Average HRV:** \(Int(report.avgHRV)) ms\n"
        text += "- **Average RHR:** \(Int(report.avgRHR)) bpm\n"
        text += "- **Average Strain:** \(String(format: "%.1f", report.avgStrain)) / 21\n"
        text += "- **Workouts:** \(report.totalWorkouts) (avg RPE: \(Int(report.avgWorkoutRPE)))\n"
        text += "- **Sleep Consistency:** \(Int(report.sleepConsistency))%\n"
        text += "- **Trend:** \(report.readinessTrend == .up ? "Improving" : report.readinessTrend == .down ? "Declining" : "Stable")\n\n"
        
        if !report.highlights.isEmpty {
            text += "## Highlights\n"
            for highlight in report.highlights {
                text += "- \(highlight)\n"
            }
            text += "\n"
        }
        
        if !report.recommendations.isEmpty {
            text += "## Recommendations\n"
            for rec in report.recommendations {
                text += "- \(rec)\n"
            }
        }
        
        return text
    }
}
