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
    /// Dietary vitamin C (mg) from HealthKit `dietaryVitaminC` — Honest #194.
    let vitaminCMg: Double?
    /// Dietary vitamin D (IU) from HealthKit `dietaryVitaminD` — Honest #195.
    let vitaminDIU: Double?
    /// Dietary vitamin B12 (mcg) from HealthKit `dietaryVitaminB12` — Honest #196.
    let vitaminB12Mcg: Double?
    /// Dietary iron (mg) from HealthKit `dietaryIron` — Honest #197.
    let ironMg: Double?
    /// Dietary calcium (mg) from HealthKit `dietaryCalcium` — Honest #198.
    let calciumMg: Double?
    /// Dietary magnesium (mg) from HealthKit `dietaryMagnesium` — Honest #199.
    let magnesiumMg: Double?
    /// Dietary zinc (mg) from HealthKit `dietaryZinc` — Honest #200.
    let zincMg: Double?
    /// Dietary folate (mcg) from HealthKit `dietaryFolate` — Honest #201.
    let folateMcg: Double?
    /// Dietary vitamin A (mcg) from HealthKit `dietaryVitaminA` — Honest #202.
    let vitaminAMcg: Double?
    /// Alcoholic beverage count from HealthKit `numberOfAlcoholicBeverages` — Honest #177.
    let alcoholicBeverages: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
            && energyKcal == nil && carbohydrateGrams == nil && fatGrams == nil
            && fiberGrams == nil && sugarGrams == nil && sodiumMg == nil && potassiumMg == nil && cholesterolMg == nil && saturatedFatGrams == nil && vitaminCMg == nil && vitaminDIU == nil && vitaminB12Mcg == nil && ironMg == nil && calciumMg == nil && magnesiumMg == nil && zincMg == nil && folateMcg == nil && vitaminAMcg == nil && alcoholicBeverages == nil
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
        vitaminCMg: Double? = nil,
        vitaminDIU: Double? = nil,
        vitaminB12Mcg: Double? = nil,
        ironMg: Double? = nil,
        calciumMg: Double? = nil,
        magnesiumMg: Double? = nil,
        zincMg: Double? = nil,
        folateMcg: Double? = nil,
        vitaminAMcg: Double? = nil,
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
        self.vitaminCMg = vitaminCMg
        self.vitaminDIU = vitaminDIU
        self.vitaminB12Mcg = vitaminB12Mcg
        self.ironMg = ironMg
        self.calciumMg = calciumMg
        self.magnesiumMg = magnesiumMg
        self.zincMg = zincMg
        self.folateMcg = folateMcg
        self.vitaminAMcg = vitaminAMcg
        self.alcoholicBeverages = alcoholicBeverages
    }
}
