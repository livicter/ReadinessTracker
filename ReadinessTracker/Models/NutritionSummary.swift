import Foundation

struct NutritionSummary: Codable, Hashable {
    let waterLiters: Double?
    let caffeineMg: Double?
    let proteinGrams: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
    }
    
    init(waterLiters: Double? = nil, caffeineMg: Double? = nil, proteinGrams: Double? = nil) {
        self.waterLiters = waterLiters
        self.caffeineMg = caffeineMg
        self.proteinGrams = proteinGrams
    }
}
