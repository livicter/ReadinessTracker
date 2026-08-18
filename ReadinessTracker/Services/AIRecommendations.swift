import Foundation

struct TrainingRecommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let confidence: Double // 0-1
    let priority: Priority
    
    enum RecommendationType {
        case workoutIntensity, restDay, sleepOptimization, stressManagement, nutrition
    }
    
    enum Priority: Int {
        case low = 0, medium = 1, high = 2, critical = 3
        
        var color: String {
            switch self {
            case .low: return "#00D084"
            case .medium: return "#FFD60A"
            case .high: return "#FF9500"
            case .critical: return "#FF3B30"
            }
        }
    }
}

extension Array where Element == TrainingRecommendation {
    func uniqueByTitle() -> [TrainingRecommendation] {
        var seen = Set<String>()
        return filter { seen.insert($0.title).inserted }
    }
}

@MainActor
class AIRecommendationEngine {
    static let shared = AIRecommendationEngine()
    
    func generateRecommendations(for source: DataSource) -> [TrainingRecommendation] {
        var recommendations: [TrainingRecommendation] = []
        
        let history = DataStore.shared.dataForSource(source, days: 7)
        guard let latest = history.last else { return [] }
        
        let metadata = MetadataStore.shared.metadataFor(date: Date(), timeOfDay: .morning)
        let breakdown = ReadinessCalculator.calculateBreakdown(from: latest, history: history)
        let dualScores = ReadinessCalculator.calculateDualScores(from: latest, history: history, metadata: metadata)
        
        // Rule 1: Low readiness → Rest or light activity
        if dualScores.general < 50 {
            recommendations.append(TrainingRecommendation(
                type: .restDay,
                title: "Prioritize Recovery",
                description: "Your readiness is critically low (\(dualScores.general)%). Consider a rest day or very light activity like walking or stretching.",
                confidence: 0.95,
                priority: .critical
            ))
        } else if dualScores.general < 65 {
            recommendations.append(TrainingRecommendation(
                type: .workoutIntensity,
                title: "Reduce Intensity",
                description: "Readiness is below optimal. If training, keep RPE below 6 and reduce volume by 20-30%.",
                confidence: 0.85,
                priority: .high
            ))
        }
        
        // Rule 2: High gym but low work → Good for physical, limit cognitive
        if dualScores.gym >= 75 && dualScores.cognitive < 60 {
            recommendations.append(TrainingRecommendation(
                type: .workoutIntensity,
                title: "Good for Gym, Light Workload",
                description: "Your body is ready for training but mental fatigue is elevated. Schedule demanding tasks for tomorrow.",
                confidence: 0.80,
                priority: .medium
            ))
        }
        
        // Rule 3: Low gym but high work → Focus on work, skip heavy training
        if dualScores.gym < 60 && dualScores.cognitive >= 75 {
            recommendations.append(TrainingRecommendation(
                type: .workoutIntensity,
                title: "Focus on Work",
                description: "Mental readiness is strong but physical recovery is incomplete. Skip heavy lifting today.",
                confidence: 0.82,
                priority: .medium
            ))
        }
        
        // Rule 4: Poor sleep → Sleep optimization
        if breakdown.sleepScore < 60 {
            recommendations.append(TrainingRecommendation(
                type: .sleepOptimization,
                title: "Improve Sleep Tonight",
                description: "Sleep quality was poor. Aim for 8+ hours tonight. Avoid screens 1 hour before bed and keep room cool (65-68°F).",
                confidence: 0.90,
                priority: .high
            ))
        }
        
        // Rule 5: Low HRV → Parasympathetic recovery needed
        let hrvBaseline = BaselineManager.hrvBaseline(from: history, matchesRMSSD: latest.hrvIsRMSSD)
        if latest.hrv > 0, Double(latest.hrv) < hrvBaseline * 0.85 {
            recommendations.append(TrainingRecommendation(
                type: .stressManagement,
                title: "Boost Recovery",
                description: "HRV is 15% below your baseline. Try the breathing exercise or take a 20-minute nap to activate parasympathetic recovery.",
                confidence: 0.88,
                priority: .high
            ))
        }
        
        // Rule 6: High RHR → Overreaching detection
        let rhrBaseline = BaselineManager.rhrBaseline(from: history)
        if Double(latest.restingHeartRate) > rhrBaseline * 1.10 {
            recommendations.append(TrainingRecommendation(
                type: .restDay,
                title: "Overreaching Signal",
                description: "Resting HR is elevated 10%+ above baseline. This is an early sign of overreaching. Take a rest day.",
                confidence: 0.92,
                priority: .critical
            ))
        }
        
        // Rule 7: High workload stress → Stress management
        if metadata?.workloadStress ?? 0 >= 4 {
            recommendations.append(TrainingRecommendation(
                type: .stressManagement,
                title: "Manage Work Stress",
                description: "Work stress is high. Take 5-minute breaks every hour. Try box breathing (4-4-4-4) before meetings.",
                confidence: 0.78,
                priority: .medium
            ))
        }
        
        // Rule 8: Consistent high readiness → Progressive overload
        if history.count >= 5 {
            let avgReadiness = history.map { $0.readinessScore }.reduce(0, +) / history.count
            if avgReadiness >= 80 {
                recommendations.append(TrainingRecommendation(
                    type: .workoutIntensity,
                    title: "Ready to Progress",
                    description: "You've had \(history.count) strong days in a row. This is a good time to increase training load by 5-10%.",
                    confidence: 0.75,
                    priority: .low
                ))
            }
        }
        
        // Rule 9: Alcohol impact
        if metadata?.alcoholDrinks ?? 0 >= 3 {
            recommendations.append(TrainingRecommendation(
                type: .nutrition,
                title: "Hydrate and Recover",
                description: "Alcohol impacts sleep quality and HRV. Drink extra water today and consider an earlier bedtime.",
                confidence: 0.85,
                priority: .medium
            ))
        }
        
        // Rule 10: High strain + low recovery -> critical rest
        let latestStrain = StrainCalculator.calculate(from: latest, history: history)
        if latestStrain > 14 && dualScores.general < 50 {
            recommendations.append(TrainingRecommendation(
                type: .restDay,
                title: "Critical Rest Day",
                description: "Strain is \(String(format: "%.1f", latestStrain)) and readiness is only \(dualScores.general)%. Avoid hard training today.",
                confidence: 0.93,
                priority: .critical
            ))
        }
        
        // Rule 11: 3+ consecutive workout days with avg RPE >= 7 -> taper
        for run in consecutiveWorkoutRuns(in: history) {
            let avgRPE = Double(run.compactMap { $0.workoutRPE }.reduce(0, +)) / Double(run.count)
            if avgRPE >= 7 {
                recommendations.append(TrainingRecommendation(
                    type: .workoutIntensity,
                    title: "Taper Recommended",
                    description: "You've trained \(run.count) days in a row at an average RPE of \(Int(avgRPE)). Reduce load for 1-2 days.",
                    confidence: 0.85,
                    priority: .high
                ))
            }
        }
        
        // Rule 12: Recovery > 80 and strain < 7 -> progressive overload window
        if dualScores.general > 80 && latestStrain < 7 {
            recommendations.append(TrainingRecommendation(
                type: .workoutIntensity,
                title: "Progressive Overload Window",
                description: "Readiness is high (\(dualScores.general)%) and strain is low. Good day to add 5-10% load.",
                confidence: 0.78,
                priority: .low
            ))
        }
        
        // Rule 13: Hard workout today and next-day HRV < baseline * 0.9 -> recovery warning
        let hrvBaselineForRecovery = BaselineManager.hrvBaseline(from: history, matchesRMSSD: latest.hrvIsRMSSD)
        for i in 0..<(history.count - 1) {
            let day = history[i]
            let nextDay = history[i + 1]

            if let evening = MetadataStore.shared.metadataFor(date: day.date, timeOfDay: .evening),
               let rpe = evening.workoutRPE, rpe >= 8,
               nextDay.hrv > 0, Double(nextDay.hrv) < hrvBaselineForRecovery * 0.9 {
                recommendations.append(TrainingRecommendation(
                    type: .restDay,
                    title: "Recovery Warning",
                    description: "A hard workout (RPE \(rpe)) was followed by below-baseline HRV. Prioritize recovery.",
                    confidence: 0.86,
                    priority: .high
                ))
            }
        }
        
        recommendations = recommendations.uniqueByTitle()

        // Sort by priority
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    private func consecutiveWorkoutRuns(in history: [DailyHealthData]) -> [[UserMetadata]] {
        var runs: [[UserMetadata]] = []
        var current: [UserMetadata] = []

        for day in history {
            if let evening = MetadataStore.shared.metadataFor(date: day.date, timeOfDay: .evening),
               evening.workoutToday == true {
                current.append(evening)
            } else {
                if current.count >= 3 { runs.append(current) }
                current = []
            }
        }
        if current.count >= 3 { runs.append(current) }

        return runs
    }

    /// Builds the ranked daily coaching feed for the given source.
    /// Gathers inputs from the stores and delegates the rules to CoachingEngine.
    func generateCoachingFeed(for source: DataSource) -> [CoachingInsight] {
        let history = DataStore.shared.dataForSource(source, days: 30)
        guard let latest = history.last else { return [] }

        let metadata = MetadataStore.shared.metadataFor(date: Date(), timeOfDay: .morning)
        let dualScores = ReadinessCalculator.calculateDualScores(from: latest, history: history, metadata: metadata)
        let guidance = workoutSuggestion(readinessScore: dualScores.general, gymScore: dualScores.gym)

        return CoachingEngine.generateFeed(
            latest: latest,
            history: history,
            morningMetadata: metadata,
            journalEntries: Self.loadJournalEntries(),
            trainingGuidance: guidance
        )
    }

    /// Journal entries persisted by JournalView (same UserDefaults key).
    private static func loadJournalEntries() -> [JournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: "journal_entries"),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    func workoutSuggestion(readinessScore: Int, gymScore: Int) -> String {
        switch gymScore {
        case 80...100:
            return "Go heavy! Aim for 85-90% 1RM. 3-5 sets of 3-5 reps."
        case 65..<80:
            return "Moderate intensity. 70-80% 1RM. 3 sets of 8-10 reps."
        case 50..<65:
            return "Light session. 60-70% 1RM. Focus on technique and mobility."
        default:
            return "Rest day recommended. Active recovery only (walk, stretch, yoga)."
        }
    }
}
