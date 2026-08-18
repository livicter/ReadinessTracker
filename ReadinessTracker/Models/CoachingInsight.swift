import Foundation

/// A single ranked coaching card: a plain-language explanation of why a metric
/// moved vs the user's own baselines, plus one concrete action.
struct CoachingInsight: Identifiable {
    enum Category: String, CaseIterable {
        case sleep, hrv, restingHR, strain, nutrition, behavior, stress, training

        var icon: String {
            switch self {
            case .sleep: return "bed.double.fill"
            case .hrv: return "waveform.path.ecg"
            case .restingHR: return "heart.fill"
            case .strain: return "flame.fill"
            case .nutrition: return "fork.knife"
            case .behavior: return "book.closed.fill"
            case .stress: return "brain.head.profile"
            case .training: return "figure.strengthtraining.traditional"
            }
        }
    }

    let id = UUID()
    let category: Category
    let title: String
    /// Plain-language why: what moved vs the user's own 7/30-day baseline.
    let explanation: String
    /// One concrete, doable suggestion.
    let action: String
    /// 0-100. Higher impact ranks first in the feed.
    let impact: Int

    init(category: Category, title: String, explanation: String, action: String, impact: Int) {
        self.category = category
        self.title = title
        self.explanation = explanation
        self.action = action
        self.impact = min(100, max(0, impact))
    }
}

/// Builds the daily coaching feed by comparing today against the user's own
/// 7/30-day baselines, journal behaviors, and nutrition logs.
/// Pure logic — callers gather the inputs, so it is unit-testable.
enum CoachingEngine {

    static func generateFeed(
        latest: DailyHealthData,
        history: [DailyHealthData],
        morningMetadata: UserMetadata? = nil,
        journalEntries: [JournalEntry] = [],
        trainingGuidance: String? = nil
    ) -> [CoachingInsight] {
        var insights: [CoachingInsight] = []
        let breakdown = ReadinessCalculator.calculateBreakdown(from: latest, history: history)

        if let trend = readinessTrendInsight(latest: latest, history: history, breakdown: breakdown) {
            insights.append(trend)
        }
        insights.append(contentsOf: hrvInsights(latest: latest, history: history))
        if let sleep = sleepInsight(latest: latest, history: history) {
            insights.append(sleep)
        }
        if let rhr = restingHRInsight(latest: latest, history: history) {
            insights.append(rhr)
        }
        if let balance = strainBalanceInsight(latest: latest, history: history, breakdown: breakdown) {
            insights.append(balance)
        }
        insights.append(contentsOf: journalInsights(entries: journalEntries))
        insights.append(contentsOf: nutritionInsights(latest: latest))
        insights.append(contentsOf: metadataInsights(metadata: morningMetadata))
        if let consistency = consistencyInsight(history: history) {
            insights.append(consistency)
        }
        if let guidance = trainingGuidance {
            insights.append(CoachingInsight(
                category: .training,
                title: "Today's training guidance",
                explanation: "Based on today's gym readiness and recent strain.",
                action: guidance,
                impact: 50
            ))
        }

        var seen = Set<String>()
        let unique = insights.filter { seen.insert($0.title).inserted }
        return Array(unique.sorted { $0.impact > $1.impact }.prefix(8))
    }

    // MARK: - Readiness trend vs 7-day baseline

    private static func readinessTrendInsight(
        latest: DailyHealthData,
        history: [DailyHealthData],
        breakdown: ReadinessBreakdown
    ) -> CoachingInsight? {
        let previous = history.dropLast().suffix(7)
        guard previous.count >= 4 else { return nil }

        let previousScores = previous.map {
            ReadinessCalculator.calculateBreakdown(from: $0, history: history).totalScore
        }
        let avg = Double(previousScores.reduce(0, +)) / Double(previousScores.count)
        let delta = Double(breakdown.totalScore) - avg
        guard abs(delta) >= 5 else { return nil }

        let driver = biggestDriver(breakdown: breakdown, previous: Array(previous), history: history)
        let driverText = driver.map { " Biggest driver: \($0.explanation)." } ?? ""

        if delta < 0 {
            return CoachingInsight(
                category: driver?.category ?? .training,
                title: "Readiness down \(Int(abs(delta))) points vs your 7-day average",
                explanation: "Today is \(breakdown.totalScore)% vs a 7-day average of \(Int(avg))%.\(driverText)",
                action: driver?.action ?? "Keep today light and prioritize sleep tonight.",
                impact: 55 + Int(abs(delta))
            )
        }
        return CoachingInsight(
            category: driver?.category ?? .training,
            title: "Readiness up \(Int(delta)) points vs your 7-day average",
            explanation: "Today is \(breakdown.totalScore)% vs a 7-day average of \(Int(avg))%.\(driverText)",
            action: "Recovery is trending well. Normal training is fine today.",
            impact: 25 + Int(delta)
        )
    }

    /// Which readiness component moved most vs the previous 7 days.
    private static func biggestDriver(
        breakdown: ReadinessBreakdown,
        previous: [DailyHealthData],
        history: [DailyHealthData]
    ) -> (category: CoachingInsight.Category, explanation: String, action: String)? {
        let previousBreakdowns = previous.map {
            ReadinessCalculator.calculateBreakdown(from: $0, history: history)
        }
        func avg(_ keyPath: KeyPath<ReadinessBreakdown, Int>) -> Double {
            Double(previousBreakdowns.map { $0[keyPath: keyPath] }.reduce(0, +)) / Double(previousBreakdowns.count)
        }

        let drivers: [(CoachingInsight.Category, String, String, String)] = [
            (.sleep, "Sleep",
             "Sleep fell from a 7-day average score of \(Int(avg(\.sleepScore))) to \(breakdown.sleepScore)",
             "Move bedtime 30-45 minutes earlier tonight and keep the room cool (65-68°F)."),
            (.hrv, "HRV",
             "HRV recovery fell from an average score of \(Int(avg(\.hrvScore))) to \(breakdown.hrvScore)",
             "Try a 5-minute breathing session or a 20-minute nap to activate parasympathetic recovery."),
            (.restingHR, "Resting heart rate",
             "Resting HR recovery fell from an average score of \(Int(avg(\.recoveryScore))) to \(breakdown.recoveryScore)",
             "Hydrate well and avoid hard training until your resting HR settles back down."),
            (.strain, "Recent strain",
             "Accumulated strain fell from an average score of \(Int(avg(\.strainScore))) to \(breakdown.strainScore)",
             "Reduce training volume for 1-2 days to let the strain load clear.")
        ]

        let deltas: [(Int, Int)] = [
            (0, breakdown.sleepScore - Int(avg(\.sleepScore))),
            (1, breakdown.hrvScore - Int(avg(\.hrvScore))),
            (2, breakdown.recoveryScore - Int(avg(\.recoveryScore))),
            (3, breakdown.strainScore - Int(avg(\.strainScore)))
        ]
        guard let (index, delta) = deltas.max(by: { abs($0.1) < abs($1.1) }), abs(delta) >= 5 else {
            return nil
        }
        let (category, name, downExplanation, action) = drivers[index]
        let explanation: String
        if delta < 0 {
            explanation = downExplanation
        } else {
            switch category {
            case .sleep: explanation = "Sleep improved from a 7-day average score of \(Int(avg(\.sleepScore))) to \(breakdown.sleepScore)"
            case .hrv: explanation = "HRV recovery improved from an average score of \(Int(avg(\.hrvScore))) to \(breakdown.hrvScore)"
            case .restingHR: explanation = "Resting HR recovery improved from an average score of \(Int(avg(\.recoveryScore))) to \(breakdown.recoveryScore)"
            case .strain: explanation = "Strain load lightened vs the last week"
            default: explanation = "\(name) improved"
            }
        }
        return (category, explanation, action)
    }

    // MARK: - HRV vs 7/30-day baselines

    private static func hrvInsights(latest: DailyHealthData, history: [DailyHealthData]) -> [CoachingInsight] {
        guard latest.hrv > 0 else { return [] }
        let baseline30 = BaselineManager.hrvBaseline(from: history, window: 30, matchesRMSSD: latest.hrvIsRMSSD)
        let baseline7 = BaselineManager.hrvBaseline(from: history, window: 7, matchesRMSSD: latest.hrvIsRMSSD)
        guard baseline30 > 0 else { return [] }

        let ratio = latest.hrv / baseline30
        let weeklyTrend = baseline7 > baseline30 * 1.05 ? "trending up over the last week"
            : baseline7 < baseline30 * 0.95 ? "trending down over the last week"
            : "flat over the last week"

        if ratio <= 0.90 {
            let percent = Int((1 - ratio) * 100)
            return [CoachingInsight(
                category: .hrv,
                title: "HRV \(percent)% below your 30-day baseline",
                explanation: "Today is \(Int(latest.hrv)) ms vs a baseline of \(Int(baseline30)) ms, and your weekly average is \(weeklyTrend). Low HRV means your nervous system is still recovering.",
                action: "Do a 5-minute slow breathing session, take a 20-minute nap, and keep training light today.",
                impact: 60 + percent
            )]
        }
        if ratio >= 1.10 {
            let percent = Int((ratio - 1) * 100)
            return [CoachingInsight(
                category: .hrv,
                title: "HRV \(percent)% above your 30-day baseline",
                explanation: "Today is \(Int(latest.hrv)) ms vs a baseline of \(Int(baseline30)) ms, and your weekly average is \(weeklyTrend). Recovery capacity is high.",
                action: "Good window for a harder session if you planned one.",
                impact: 25
            )]
        }
        return []
    }

    // MARK: - Sleep vs 7-day baseline

    private static func sleepInsight(latest: DailyHealthData, history: [DailyHealthData]) -> CoachingInsight? {
        guard latest.sleepHours > 0 else { return nil }
        let baseline = BaselineManager.sleepBaseline(from: history, window: 7)
        let delta = latest.sleepHours - baseline
        guard abs(delta) >= 0.75 else { return nil }

        if delta < 0 {
            return CoachingInsight(
                category: .sleep,
                title: "Slept \(String(format: "%.1f", abs(delta)))h less than your 7-day average",
                explanation: "Last night was \(String(format: "%.1f", latest.sleepHours))h vs your average of \(String(format: "%.1f", baseline))h. Short sleep suppresses HRV and next-day readiness.",
                action: "Move bedtime 30-45 minutes earlier tonight and avoid screens in the last hour.",
                impact: 50 + Int(abs(delta) * 10)
            )
        }
        return CoachingInsight(
            category: .sleep,
            title: "Slept \(String(format: "%.1f", delta))h more than your 7-day average",
            explanation: "Last night was \(String(format: "%.1f", latest.sleepHours))h vs your average of \(String(format: "%.1f", baseline))h. Extra sleep pays down sleep debt.",
            action: "Keep the same bedtime tonight to lock in the gain.",
            impact: 20
        )
    }

    // MARK: - Resting HR vs 30-day baseline

    private static func restingHRInsight(latest: DailyHealthData, history: [DailyHealthData]) -> CoachingInsight? {
        guard latest.restingHeartRate > 0 else { return nil }
        let baseline = BaselineManager.rhrBaseline(from: history, window: 30)
        guard baseline > 0, latest.restingHeartRate > baseline * 1.05 else { return nil }

        let percent = Int((latest.restingHeartRate / baseline - 1) * 100)
        return CoachingInsight(
            category: .restingHR,
            title: "Resting HR \(percent)% above your 30-day baseline",
            explanation: "Today is \(Int(latest.restingHeartRate)) bpm vs a baseline of \(Int(baseline)) bpm. An elevated resting HR is an early sign of incomplete recovery, dehydration, or oncoming illness.",
            action: "Hydrate, skip alcohol tonight, and take a rest day if you also feel off.",
            impact: 65 + percent
        )
    }

    // MARK: - Strain vs recovery balance

    private static func strainBalanceInsight(
        latest: DailyHealthData,
        history: [DailyHealthData],
        breakdown: ReadinessBreakdown
    ) -> CoachingInsight? {
        let strain = StrainCalculator.calculate(from: latest, history: history)
        let balance = StrainRecoveryBalance.compute(recovery: breakdown.totalScore, strain: strain)

        switch balance.status {
        case "Rest Needed":
            return CoachingInsight(
                category: .strain,
                title: "Strain is outpacing your recovery",
                explanation: "Strain is \(String(format: "%.1f", strain)) while readiness is only \(breakdown.totalScore)%. The load you are carrying exceeds what your body has recovered from.",
                action: "Take a full rest day — walk, stretch, and get to bed early.",
                impact: 85
            )
        case "Overreaching Risk":
            return CoachingInsight(
                category: .strain,
                title: "Approaching overreaching territory",
                explanation: "Strain is \(String(format: "%.1f", strain)) against a readiness of \(breakdown.totalScore)%. One more hard day pushes you into the red.",
                action: "Swap today's hard session for zone-2 cardio or mobility work.",
                impact: 70
            )
        default:
            return nil
        }
    }

    // MARK: - Journal behavior impact

    private static func journalInsights(entries: [JournalEntry]) -> [CoachingInsight] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let scored = entries.filter { $0.date >= cutoff && $0.readinessScore != nil }
        guard scored.count >= 3 else { return [] }

        let scores = scored.compactMap(\.readinessScore)
        let overall = Double(scores.reduce(0, +)) / Double(scores.count)

        var byBehavior: [JournalEntryView.Behavior: [Int]] = [:]
        for entry in scored {
            guard let score = entry.readinessScore else { continue }
            for behavior in entry.behaviors {
                byBehavior[behavior, default: []].append(score)
            }
        }

        var insights: [CoachingInsight] = []
        for (behavior, behaviorScores) in byBehavior where behaviorScores.count >= 2 {
            let avg = Double(behaviorScores.reduce(0, +)) / Double(behaviorScores.count)
            let impact = avg - overall

            if impact <= -5 {
                insights.append(CoachingInsight(
                    category: .behavior,
                    title: "\(behavior.rawValue) is costing you readiness",
                    explanation: "On the \(behaviorScores.count) days you logged \(behavior.rawValue.lowercased()) this month, readiness averaged \(Int(avg)) — \(Int(abs(impact))) points below your usual \(Int(overall)).",
                    action: behaviorAction(behavior),
                    impact: 50 + Int(abs(impact))
                ))
            } else if impact >= 5 {
                insights.append(CoachingInsight(
                    category: .behavior,
                    title: "\(behavior.rawValue) is working for you",
                    explanation: "On the \(behaviorScores.count) days you logged \(behavior.rawValue.lowercased()) this month, readiness averaged \(Int(avg)) — \(Int(impact)) points above your usual \(Int(overall)).",
                    action: "Keep it up — your data shows it pays off.",
                    impact: 20
                ))
            }
        }
        return insights
    }

    private static func behaviorAction(_ behavior: JournalEntryView.Behavior) -> String {
        switch behavior {
        case .alcohol: return "If you drink, stop at least 3 hours before bed and cap it at 1-2 drinks."
        case .caffeineLate: return "Move your last caffeine before 2pm — it lingers 8+ hours."
        case .screenTime: return "Set a screen curfew 60 minutes before bed."
        case .stress: return "Add a 5-minute breathing break between work blocks."
        case .travel: return "On travel days, hydrate aggressively and anchor your sleep to the new timezone."
        case .sick: return "Rest fully until symptoms clear — training through illness extends it."
        case .massage, .iceBath, .sauna, .meditation: return "Keep it in your routine — it is working."
        }
    }

    // MARK: - Nutrition

    private static func nutritionInsights(latest: DailyHealthData) -> [CoachingInsight] {
        var insights: [CoachingInsight] = []

        if let water = latest.nutrition.waterLiters, water < 1.5 {
            insights.append(CoachingInsight(
                category: .nutrition,
                title: "Hydration is low",
                explanation: "You logged \(String(format: "%.1f", water))L of water yesterday. Even mild dehydration raises resting HR and suppresses HRV.",
                action: "Drink 2-2.5L today, front-loaded before 3pm.",
                impact: 35
            ))
        }
        if let caffeine = latest.nutrition.caffeineMg, caffeine >= 250 {
            insights.append(CoachingInsight(
                category: .nutrition,
                title: "High caffeine intake",
                explanation: "You logged \(Int(caffeine)) mg of caffeine. Above ~250 mg it reliably delays sleep onset and cuts deep sleep.",
                action: "Keep it under 200 mg tomorrow and none after 2pm.",
                impact: 40
            ))
        }
        if let protein = latest.nutrition.proteinGrams, protein < 100 {
            insights.append(CoachingInsight(
                category: .nutrition,
                title: "Protein intake is low",
                explanation: "You logged \(Int(protein))g of protein. Under-fueling protein slows muscle recovery between sessions.",
                action: "Add a 30-40g protein serving to each remaining meal today.",
                impact: 30
            ))
        }
        return insights
    }

    // MARK: - Check-in metadata

    private static func metadataInsights(metadata: UserMetadata?) -> [CoachingInsight] {
        guard let metadata else { return [] }
        var insights: [CoachingInsight] = []

        if metadata.isSick {
            insights.append(CoachingInsight(
                category: .stress,
                title: "You reported feeling sick",
                explanation: "Illness raises resting HR and body temperature, which suppresses readiness regardless of sleep.",
                action: "Full rest today. Resume training only after a symptom-free day.",
                impact: 90
            ))
        }
        if let stress = metadata.workloadStress, stress >= 4 {
            insights.append(CoachingInsight(
                category: .stress,
                title: "Work stress is high (\(stress)/5)",
                explanation: "High cognitive load drains the same recovery budget as training and shows up in lower HRV within 24 hours.",
                action: "Take a 5-minute break every hour and try box breathing (4-4-4-4) before meetings.",
                impact: 45
            ))
        }
        if let fatigue = metadata.mentalFatigue, fatigue >= 4 {
            insights.append(CoachingInsight(
                category: .stress,
                title: "Mental fatigue is high (\(fatigue)/5)",
                explanation: "Mental fatigue impairs focus and reaction time even when physical readiness looks fine.",
                action: "Schedule demanding work for tomorrow; a 20-minute nap this afternoon helps.",
                impact: 45
            ))
        }
        return insights
    }

    // MARK: - Sleep consistency

    private static func consistencyInsight(history: [DailyHealthData]) -> CoachingInsight? {
        guard history.count >= 5 else { return nil }
        let score = BaselineManager.consistencyScore(from: history)
        guard score < 60 else { return nil }

        return CoachingInsight(
            category: .sleep,
            title: "Sleep schedule is inconsistent",
            explanation: "Your bedtime varies enough to score \(score)/100 on consistency. Irregular sleep timing blunts recovery even at the same duration.",
            action: "Pick a bedtime and stick within ±30 minutes of it for the next week.",
            impact: 40
        )
    }
}
