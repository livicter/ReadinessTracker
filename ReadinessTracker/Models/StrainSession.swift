import Foundation

struct StrainSession: Codable, Identifiable, Hashable {
    let id: UUID
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let durationMinutes: Double
    let trimp: Double
    let contribution: Double
    
    init(
        id: UUID = UUID(),
        workoutType: String,
        startDate: Date,
        endDate: Date,
        trimp: Double = 0,
        contribution: Double = 0
    ) {
        self.id = id
        self.workoutType = workoutType
        self.startDate = startDate
        self.endDate = endDate
        self.durationMinutes = endDate.timeIntervalSince(startDate) / 60
        self.trimp = trimp
        self.contribution = contribution
    }
}
