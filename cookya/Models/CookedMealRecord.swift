import Foundation

struct CookedMealRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let cookedAt: Date
    let profileId: UUID
    let profileNameSnapshot: String
    let recipeTitle: String
    let recipeIngredients: [Ingredient]
    let consumptions: [PantryConsumption]
    let warnings: [String]
    // Macro snapshot at time of cooking (0 for records created before nutrition layer)
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let fiberG: Int

    init(
        id: UUID = UUID(),
        cookedAt: Date = .now,
        profileId: UUID,
        profileNameSnapshot: String,
        recipeTitle: String,
        recipeIngredients: [Ingredient],
        consumptions: [PantryConsumption],
        warnings: [String],
        calories: Int = 0,
        proteinG: Int = 0,
        carbsG: Int = 0,
        fatG: Int = 0,
        fiberG: Int = 0
    ) {
        self.id = id
        self.cookedAt = cookedAt
        self.profileId = profileId
        self.profileNameSnapshot = profileNameSnapshot
        self.recipeTitle = recipeTitle
        self.recipeIngredients = recipeIngredients
        self.consumptions = consumptions
        self.warnings = warnings
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fiberG = fiberG
    }

    enum CodingKeys: String, CodingKey {
        case id, cookedAt, profileId, profileNameSnapshot
        case recipeTitle, recipeIngredients, consumptions, warnings
        case calories, proteinG, carbsG, fatG, fiberG
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        cookedAt = try c.decode(Date.self, forKey: .cookedAt)
        profileId = try c.decode(UUID.self, forKey: .profileId)
        profileNameSnapshot = try c.decode(String.self, forKey: .profileNameSnapshot)
        recipeTitle = try c.decode(String.self, forKey: .recipeTitle)
        recipeIngredients = try c.decode([Ingredient].self, forKey: .recipeIngredients)
        consumptions = try c.decode([PantryConsumption].self, forKey: .consumptions)
        warnings = try c.decode([String].self, forKey: .warnings)
        calories = try c.decodeIfPresent(Int.self, forKey: .calories) ?? 0
        proteinG = try c.decodeIfPresent(Int.self, forKey: .proteinG) ?? 0
        carbsG = try c.decodeIfPresent(Int.self, forKey: .carbsG) ?? 0
        fatG = try c.decodeIfPresent(Int.self, forKey: .fatG) ?? 0
        fiberG = try c.decodeIfPresent(Int.self, forKey: .fiberG) ?? 0
    }
}
