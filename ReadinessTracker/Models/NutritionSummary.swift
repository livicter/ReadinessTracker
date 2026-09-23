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
    /// Dietary sodium (mg) from HealthKit `dietarySodium` — Honest #190.
    let sodiumMg: Double?
    /// Dietary potassium (mg) from HealthKit `dietaryPotassium` — Honest #191.
    let potassiumMg: Double?
    /// Dietary cholesterol (mg) from HealthKit `dietaryCholesterol` — Honest #192.
    let cholesterolMg: Double?
    /// Dietary saturated fat (g) from HealthKit `dietaryFatSaturated` — Honest #193.
    let saturatedFatGrams: Double?
    /// Alcoholic beverage count from HealthKit `numberOfAlcoholicBeverages` — Honest #177.
    let alcoholicBeverages: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
            && energyKcal == nil && carbohydrateGrams == nil && fatGrams == nil
            && fiberGrams == nil && sugarGrams == nil && sodiumMg == nil && potassiumMg == nil && cholesterolMg == nil && saturatedFatGrams == nil && alcoholicBeverages == nil
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
        sodiumMg: Double? = nil,
        potassiumMg: Double? = nil,
        cholesterolMg: Double? = nil,
        saturatedFatGrams: Double? = nil,
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
        self.sodiumMg = sodiumMg
        self.potassiumMg = potassiumMg
        self.cholesterolMg = cholesterolMg
        self.saturatedFatGrams = saturatedFatGrams
        self.alcoholicBeverages = alcoholicBeverages
    }
}
