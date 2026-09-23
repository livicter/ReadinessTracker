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
    /// Dietary vitamin E (mg) from HealthKit `dietaryVitaminE` — Honest #203.
    let vitaminEMg: Double?
    /// Dietary vitamin K (mcg) from HealthKit `dietaryVitaminK` — Honest #204.
    let vitaminKMcg: Double?
    /// Dietary vitamin B6 (mg) from HealthKit `dietaryVitaminB6` — Honest #205.
    let vitaminB6Mg: Double?
    /// Dietary thiamin (mg) from HealthKit `dietaryThiamin` — Honest #206.
    let thiaminMg: Double?
    /// Dietary riboflavin (mg) from HealthKit `dietaryRiboflavin` — Honest #207.
    let riboflavinMg: Double?
    /// Dietary niacin (mg) from HealthKit `dietaryNiacin` — Honest #208.
    let niacinMg: Double?
    /// Dietary pantothenic acid (mg) from HealthKit `dietaryPantothenicAcid` — Honest #209.
    let pantothenicAcidMg: Double?
    /// Dietary biotin (mcg) from HealthKit `dietaryBiotin` — Honest #210.
    let biotinMcg: Double?
    /// Dietary copper (mg) from HealthKit `dietaryCopper` — Honest #211.
    let copperMg: Double?
    /// Dietary selenium (mcg) from HealthKit `dietarySelenium` — Honest #212.
    let seleniumMcg: Double?
    /// Dietary manganese (mg) from HealthKit `dietaryManganese` — Honest #213.
    let manganeseMg: Double?
    /// Dietary iodine (mcg) from HealthKit `dietaryIodine` — Honest #214.
    let iodineMcg: Double?
    /// Dietary phosphorus (mg) from HealthKit `dietaryPhosphorus` — Honest #215.
    let phosphorusMg: Double?
    /// Dietary chromium (mcg) from HealthKit `dietaryChromium` — Honest #216.
    let chromiumMcg: Double?
    /// Dietary molybdenum (mcg) from HealthKit `dietaryMolybdenum` — Honest #217.
    let molybdenumMcg: Double?
    /// Dietary chloride (mg) from HealthKit `dietaryChloride` — Honest #218.
    let chlorideMg: Double?
    /// Alcoholic beverage count from HealthKit `numberOfAlcoholicBeverages` — Honest #177.
    let alcoholicBeverages: Double?
    
    var isEmpty: Bool {
        waterLiters == nil && caffeineMg == nil && proteinGrams == nil
            && energyKcal == nil && carbohydrateGrams == nil && fatGrams == nil
            && fiberGrams == nil && sugarGrams == nil && sodiumMg == nil && potassiumMg == nil && cholesterolMg == nil && saturatedFatGrams == nil && vitaminCMg == nil && vitaminDIU == nil && vitaminB12Mcg == nil && ironMg == nil && calciumMg == nil && magnesiumMg == nil && zincMg == nil && folateMcg == nil && vitaminAMcg == nil && vitaminEMg == nil && vitaminKMcg == nil && vitaminB6Mg == nil && thiaminMg == nil && riboflavinMg == nil && niacinMg == nil && pantothenicAcidMg == nil && biotinMcg == nil && copperMg == nil && seleniumMcg == nil && manganeseMg == nil && iodineMcg == nil && phosphorusMg == nil && chromiumMcg == nil && molybdenumMcg == nil && chlorideMg == nil && alcoholicBeverages == nil
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
        vitaminEMg: Double? = nil,
        vitaminKMcg: Double? = nil,
        vitaminB6Mg: Double? = nil,
        thiaminMg: Double? = nil,
        riboflavinMg: Double? = nil,
        niacinMg: Double? = nil,
        pantothenicAcidMg: Double? = nil,
        biotinMcg: Double? = nil,
        copperMg: Double? = nil,
        seleniumMcg: Double? = nil,
        manganeseMg: Double? = nil,
        iodineMcg: Double? = nil,
        phosphorusMg: Double? = nil,
        chromiumMcg: Double? = nil,
        molybdenumMcg: Double? = nil,
        chlorideMg: Double? = nil,
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
        self.vitaminEMg = vitaminEMg
        self.vitaminKMcg = vitaminKMcg
        self.vitaminB6Mg = vitaminB6Mg
        self.thiaminMg = thiaminMg
        self.riboflavinMg = riboflavinMg
        self.niacinMg = niacinMg
        self.pantothenicAcidMg = pantothenicAcidMg
        self.biotinMcg = biotinMcg
        self.copperMg = copperMg
        self.seleniumMcg = seleniumMcg
        self.manganeseMg = manganeseMg
        self.iodineMcg = iodineMcg
        self.phosphorusMg = phosphorusMg
        self.chromiumMcg = chromiumMcg
        self.molybdenumMcg = molybdenumMcg
        self.chlorideMg = chlorideMg
        self.alcoholicBeverages = alcoholicBeverages
    }
}
