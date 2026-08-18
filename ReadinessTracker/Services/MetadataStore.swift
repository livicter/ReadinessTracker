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
    
    private func persist() {
        if let encoded = try? JSONEncoder().encode(entries) {
            defaults.set(encoded, forKey: key)
        }
    }
}
