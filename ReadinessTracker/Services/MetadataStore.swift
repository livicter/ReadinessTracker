import Foundation

@MainActor
class MetadataStore: ObservableObject {
    static let shared = MetadataStore()
    
    @Published var entries: [UserMetadata] = []
    
    private let key = "readiness_metadata"
    private let defaults = UserDefaults(suiteName: "group.com.readinesstracker") ?? .standard
    
    private init() {
        load()
    }
    
    func save(_ metadata: UserMetadata) {
        if let index = entries.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: metadata.date) && $0.timeOfDay == metadata.timeOfDay
        }) {
            entries[index] = metadata
        } else {
            entries.append(metadata)
        }
        entries.sort { $0.date > $1.date }
        persist()
    }
    
    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UserMetadata].self, from: data) else {
            return
        }
        entries = decoded.sorted { $0.date > $1.date }
    }
    
    func metadataFor(date: Date, timeOfDay: CheckInTime) -> UserMetadata? {
        entries.first {
            Calendar.current.isDate($0.date, inSameDayAs: date) && $0.timeOfDay == timeOfDay
        }
    }
    
    func hasCheckedInToday(_ timeOfDay: CheckInTime) -> Bool {
        metadataFor(date: Date(), timeOfDay: timeOfDay) != nil
    }
    
    func multiplierFor(date: Date) -> Double {
        guard let morning = metadataFor(date: date, timeOfDay: .morning) else { return 1.0 }
        return morning.readinessMultiplier()
    }
    
    func cognitiveMultiplierFor(date: Date) -> Double {
        guard let morning = metadataFor(date: date, timeOfDay: .morning) else { return 1.0 }
        return morning.cognitiveReadinessMultiplier()
    }
    
    func gymMultiplierFor(date: Date) -> Double {
        guard let morning = metadataFor(date: date, timeOfDay: .morning) else { return 1.0 }
        return morning.gymReadinessMultiplier()
    }
    
    /// Get previous day's evening metadata for strain decay calculation
    func previousEveningMetadata() -> UserMetadata? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return nil }
        return metadataFor(date: yesterday, timeOfDay: .evening)
    }
    
    /// Fixture morning + evening check-ins so Insights / Cognitive Load / RPE
    /// sparks have shape under `-ui-fixture`.
    func seedUIFixtureCheckIns() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Clear prior fixture mornings/evenings for idempotent re-runs.
        entries.removeAll { $0.timeOfDay == .morning || $0.timeOfDay == .evening }
        for offset in 0..<7 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let feel: Int
            let drinks: Int
            let stressed: Bool
            if offset == 0 {
                feel = 4; drinks = 0; stressed = false
            } else {
                feel = 2 + ((offset * 3) % 4) // 2…5
                drinks = offset % 3 == 0 ? (1 + (offset % 2)) : 0
                stressed = offset % 2 == 1
            }
            let fatigue: Int
            let stress: Int
            if offset == 0 {
                fatigue = 2; stress = 3
            } else {
                fatigue = 1 + ((offset * 2) % 5) // 1…5
                stress = 1 + ((offset * 3) % 5)  // 1…5
            }
            let morning = UserMetadata(
                date: date,
                timeOfDay: .morning,
                subjectiveFeel: feel,
                workloadStress: stress,
                mentalFatigue: fatigue,
                alcoholConsumed: drinks > 0,
                alcoholDrinks: drinks > 0 ? drinks : nil,
                isStressed: stressed
            )
            entries.append(morning)

            // Evening: workout RPE 1–10 (Honest #127). Rest every 4th older day.
            let didWorkout: Bool
            let rpe: Int?
            let type: String?
            if offset == 0 {
                didWorkout = true; rpe = 7; type = "Strength"
            } else if offset % 4 == 0 {
                didWorkout = false; rpe = nil; type = nil
            } else {
                didWorkout = true
                rpe = 4 + ((offset * 2) % 6) // 4…9
                type = offset % 2 == 0 ? "Run" : "Strength"
            }
            let evening = UserMetadata(
                date: date,
                timeOfDay: .evening,
                workoutToday: didWorkout,
                workoutType: type,
                workoutRPE: rpe,
                workoutDurationMinutes: didWorkout ? (30 + offset * 5) : nil
            )
            entries.append(evening)
        }
        entries.sort { $0.date > $1.date }
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(entries) {
            defaults.set(encoded, forKey: key)
        }

        // Check-in multipliers affect dual Gym/Work scores — refresh glances (Honest #43)
        WidgetExportAfterWrite.run()
    }
}
