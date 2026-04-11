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

    init(
        id: UUID = UUID(),
        cookedAt: Date = .now,
        profileId: UUID,
        profileNameSnapshot: String,
        recipeTitle: String,
        recipeIngredients: [Ingredient],
        consumptions: [PantryConsumption],
        warnings: [String]
    ) {
        self.id = id
        self.cookedAt = cookedAt
        self.profileId = profileId
        self.profileNameSnapshot = profileNameSnapshot
        self.recipeTitle = recipeTitle
        self.recipeIngredients = recipeIngredients
        self.consumptions = consumptions
        self.warnings = warnings
    }
}
