import Foundation

/// User-reported metadata that affects readiness interpretation.
/// Research shows these factors have major impact:
/// - Alcohol suppresses HRV 24-48h
/// - Caffeine within 8h of bed hurts sleep
/// - Late workouts elevate RHR
/// - Illness/stress spike temp and RHR
struct UserMetadata: Codable, Identifiable {
    let id: UUID
    let date: Date
    let timeOfDay: CheckInTime
    
    // Morning check-in
    let subjectiveFeel: Int?      // 1-5 scale (5 = excellent)
    let workloadStress: Int?      // 1-5 scale (5 = extremely stressful) — NEW
    let mentalFatigue: Int?       // 1-5 scale (5 = completely drained) — NEW
    let alcoholConsumed: Bool
    let alcoholDrinks: Int?
    let caffeineAfter2pm: Bool
    let isSick: Bool
    let isStressed: Bool
    let hadNap: Bool              // NEW
    let napDurationMinutes: Int?  // NEW
    let napQuality: Int?          // 1-5 scale — NEW
    
    // Evening check-in
    let workoutToday: Bool
    let workoutType: String?
    let workoutRPE: Int?          // Rate of Perceived Exertion 1-10
    let workoutDurationMinutes: Int? // NEW
    let plannedWorkoutTomorrow: Bool
    let plannedWorkoutType: String?
    let plannedWorkoutIntensity: String? // light/moderate/heavy — NEW
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        timeOfDay: CheckInTime,
        subjectiveFeel: Int? = nil,
        workloadStress: Int? = nil,
        mentalFatigue: Int? = nil,
        alcoholConsumed: Bool = false,
        alcoholDrinks: Int? = nil,
        caffeineAfter2pm: Bool = false,
        isSick: Bool = false,
        isStressed: Bool = false,
        hadNap: Bool = false,
        napDurationMinutes: Int? = nil,
        napQuality: Int? = nil,
        workoutToday: Bool = false,
        workoutType: String? = nil,
        workoutRPE: Int? = nil,
        workoutDurationMinutes: Int? = nil,
        plannedWorkoutTomorrow: Bool = false,
        plannedWorkoutType: String? = nil,
        plannedWorkoutIntensity: String? = nil
    ) {
        self.id = id
        self.date = date
        self.timeOfDay = timeOfDay
        self.subjectiveFeel = subjectiveFeel
        self.workloadStress = workloadStress
        self.mentalFatigue = mentalFatigue
        self.alcoholConsumed = alcoholConsumed
        self.alcoholDrinks = alcoholDrinks
        self.caffeineAfter2pm = caffeineAfter2pm
        self.isSick = isSick
        self.isStressed = isStressed
        self.hadNap = hadNap
        self.napDurationMinutes = napDurationMinutes
        self.napQuality = napQuality
        self.workoutToday = workoutToday
        self.workoutType = workoutType
        self.workoutRPE = workoutRPE
        self.workoutDurationMinutes = workoutDurationMinutes
        self.plannedWorkoutTomorrow = plannedWorkoutTomorrow
        self.plannedWorkoutType = plannedWorkoutType
        self.plannedWorkoutIntensity = plannedWorkoutIntensity
    }
}

enum CheckInTime: String, Codable {
    case morning = "Morning"
    case evening = "Evening"
}

extension UserMetadata {
    /// Calculate readiness adjustment based on metadata
    /// Returns multiplier: 1.0 = no change, <1.0 = reduces score, >1.0 = increases
    func readinessMultiplier() -> Double {
        var multiplier = 1.0
        
        // Alcohol: -5% per drink, max -20%
        if alcoholConsumed, let drinks = alcoholDrinks {
            multiplier -= min(0.20, Double(drinks) * 0.05)
        }
        
        // Caffeine after 2pm: -5%
        if caffeineAfter2pm {
            multiplier -= 0.05
        }
        
        // Sick: -15%
        if isSick {
            multiplier -= 0.15
        }
        
        // Stressed: -5%
        if isStressed {
            multiplier -= 0.05
        }
        
        // Subjective feel: ±5% (5 = +5%, 1 = -5%)
        if let feel = subjectiveFeel {
            let feelAdjustment = (Double(feel) - 3.0) * 0.025
            multiplier += feelAdjustment
        }
        
        // Workload stress: -3% per level above 3 (Júnior 2026 — mental fatigue impairs performance)
        if let stress = workloadStress, stress > 3 {
            multiplier -= Double(stress - 3) * 0.03
        }
        
        // Mental fatigue: -4% per level above 3
        if let fatigue = mentalFatigue, fatigue > 3 {
            multiplier -= Double(fatigue - 3) * 0.04
        }
        
        // Nap: +2% for 20-30min, +4% for 30-90min (Kerkeni 2026)
        if hadNap, let duration = napDurationMinutes {
            if duration >= 20 && duration <= 30 {
                multiplier += 0.02
            } else if duration > 30 && duration <= 90 {
                multiplier += 0.04
            } else if duration > 90 {
                multiplier -= 0.02 // grogginess penalty
            }
        }
        
        // Cap between 0.6 and 1.15
        return max(0.6, min(1.15, multiplier))
    }
    
    /// Calculate cognitive readiness multiplier (for work/mental tasks)
    /// Mental fatigue has stronger impact on cognitive performance
    func cognitiveReadinessMultiplier() -> Double {
        var multiplier = 1.0
        
        // Mental fatigue: -6% per level (stronger than physical)
        if let fatigue = mentalFatigue {
            multiplier -= Double(5 - fatigue) * 0.06
        }
        
        // Workload stress: -5% per level
        if let stress = workloadStress {
            multiplier -= Double(stress - 1) * 0.05
        }
        
        // Sleep quality proxy: subjective feel
        if let feel = subjectiveFeel {
            multiplier += (Double(feel) - 3.0) * 0.03
        }
        
        // Nap bonus for cognitive recovery
        if hadNap, let duration = napDurationMinutes, duration >= 20 {
            multiplier += 0.05
        }
        
        return max(0.5, min(1.15, multiplier))
    }
    
    /// Calculate gym readiness multiplier (for heavy training)
    /// Physical strain has stronger impact
    func gymReadinessMultiplier() -> Double {
        var multiplier = 1.0
        
        // Previous day RPE: -3% per level above 6 (Pind 2021 — RPE predicts fatigue)
        if let rpe = workoutRPE, rpe > 6 {
            multiplier -= Double(rpe - 6) * 0.03
        }
        
        // Alcohol impact on strength
        if alcoholConsumed, let drinks = alcoholDrinks {
            multiplier -= min(0.25, Double(drinks) * 0.06)
        }
        
        // Sleep restriction penalty
        if let feel = subjectiveFeel, feel < 3 {
            multiplier -= 0.08
        }
        
        // Sick = no gym
        if isSick {
            multiplier -= 0.30
        }
        
        return max(0.4, min(1.1, multiplier))
    }
    
    var summaryText: String {
        var parts: [String] = []
        if let feel = subjectiveFeel {
            parts.append("Feel: \(feel)/5")
        }
        if let stress = workloadStress {
            parts.append("Work: \(stress)/5")
        }
        if let fatigue = mentalFatigue {
            parts.append("Mental: \(fatigue)/5")
        }
        if alcoholConsumed {
            parts.append("Alcohol: \(alcoholDrinks ?? 0)")
        }
        if caffeineAfter2pm { parts.append("Late caffeine") }
        if isSick { parts.append("Sick") }
        if isStressed { parts.append("Stressed") }
        if hadNap { parts.append("Nap: \(napDurationMinutes ?? 0)min") }
        if workoutToday {
            parts.append("Workout: \(workoutType ?? "") RPE\(workoutRPE ?? 0)")
        }
        return parts.joined(separator: " · ")
    }
}
