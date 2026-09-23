import Foundation

struct NutritionSummary: Codable, Hashable {
    let waterLiters: Double?
    let caffeineMg: Double?
    let proteinGrams: Double?
    /// Dietary energy (kcal) from HealthKit `dietaryEnergyConsumed` — Honest #172.
    let energyKcal: Double?
    /// Dietary carbohydrates (g) from HealthKit `dietaryCarbohydrates` — Honest #173.
    let carbohydrateGrams: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil && energyKcal == nil && carbohydrateGrams == nil
    }
    
    init(
        waterLiters: Double? = nil,
        caffeineMg: Double? = nil,
        proteinGrams: Double? = nil,
        energyKcal: Double? = nil,
        carbohydrateGrams: Double? = nil
    ) {
        self.waterLiters = waterLiters
        self.caffeineMg = caffeineMg
        self.proteinGrams = proteinGrams
        self.energyKcal = energyKcal
        self.carbohydrateGrams = carbohydrateGrams
    }
}
