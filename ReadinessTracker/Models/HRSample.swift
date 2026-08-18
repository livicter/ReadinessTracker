import Foundation

struct HRSample: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let bpm: Double
    
    init(id: UUID = UUID(), timestamp: Date, bpm: Double) {
        self.id = id
        self.timestamp = timestamp
        self.bpm = bpm
    }
}
