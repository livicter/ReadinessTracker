import Foundation

struct NutritionSummary: Codable, Hashable {
    let waterLiters: Double?
    let caffeineMg: Double?
    let proteinGrams: Double?
    /// Dietary energy (kcal) from HealthKit `dietaryEnergyConsumed` — Honest #172.
    let energyKcal: Double?
    /// Dietary carbohydrates (g) from HealthKit `dietaryCarbohydrates` — Honest #173.
    let carbohydrateGrams: Double?
    /// Dietary fat total (g) from HealthKit `dietaryFatTotal` — Honest #174.
    let fatGrams: Double?
    /// Dietary fiber (g) from HealthKit `dietaryFiber` — Honest #175.
    let fiberGrams: Double?
    /// Dietary sugar (g) from HealthKit `dietarySugar` — Honest #176.
    let sugarGrams: Double?
    /// Alcoholic beverage count from HealthKit `numberOfAlcoholicBeverages` — Honest #177.
    let alcoholicBeverages: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
            && energyKcal == nil && carbohydrateGrams == nil && fatGrams == nil
            && fiberGrams == nil && sugarGrams == nil && alcoholicBeverages == nil
    }
    
    init(
        waterLiters: Double? = nil,
        caffeineMg: Double? = nil,
        proteinGrams: Double? = nil,
        energyKcal: Double? = nil,
        carbohydrateGrams: Double? = nil,
        fatGrams: Double? = nil,
        fiberGrams: Double? = nil,
        sugarGrams: Double? = nil,
        alcoholicBeverages: Double? = nil
    ) {
        self.waterLiters = waterLiters
        self.caffeineMg = caffeineMg
        self.proteinGrams = proteinGrams
        self.energyKcal = energyKcal
        self.carbohydrateGrams = carbohydrateGrams
        self.fatGrams = fatGrams
        self.fiberGrams = fiberGrams
        self.sugarGrams = sugarGrams
        self.alcoholicBeverages = alcoholicBeverages
    }
}
