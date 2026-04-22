import Foundation

enum HomeRecommendation: Hashable {
    case expiredReview(count: Int)
    case favoriteReady(recipe: SavedRecipe)
    case stapleReady(record: CookedMealRecord)
    case cookAgain(record: CookedMealRecord)
    case tonightsPick(recipe: SavedRecipe, reason: String)
    case savedRecipeReady(recipe: SavedRecipe)
    case savedRecipeNearMiss(recipe: SavedRecipe, missingCount: Int, reason: String)
    case useSoon(items: [PantryItem])
    case cookFromPantry
}

struct HomeRecommendationEngine {
    let expiredPantryItems: [PantryItem]
    let expiringSoonItems: [PantryItem]
    let usablePantryItems: [PantryItem]
    let savedRecipes: [SavedRecipe]
    let cookedRecords: [CookedMealRecord]
    let staples: [MealStaple]
    let nutritionGap: NutritionGap?
    let savedRecipeIssues: (SavedRecipe) -> [String]
    let savedRecipeMissingCount: (SavedRecipe) -> Int
    let replayIssues: (CookedMealRecord) -> [String]

    init(
        expiredPantryItems: [PantryItem] = [],
        expiringSoonItems: [PantryItem] = [],
        usablePantryItems: [PantryItem] = [],
        savedRecipes: [SavedRecipe] = [],
        cookedRecords: [CookedMealRecord] = [],
        staples: [MealStaple] = [],
        nutritionGap: NutritionGap? = nil,
        savedRecipeIssues: @escaping (SavedRecipe) -> [String],
        savedRecipeMissingCount: @escaping (SavedRecipe) -> Int,
        replayIssues: @escaping (CookedMealRecord) -> [String]
    ) {
        self.expiredPantryItems = expiredPantryItems
        self.expiringSoonItems = expiringSoonItems
        self.usablePantryItems = usablePantryItems
        self.savedRecipes = savedRecipes
        self.cookedRecords = cookedRecords
        self.staples = staples
        self.nutritionGap = nutritionGap
        self.savedRecipeIssues = savedRecipeIssues
        self.savedRecipeMissingCount = savedRecipeMissingCount
        self.replayIssues = replayIssues
    }

    func bestNextStep() -> HomeRecommendation? {
        if !expiredPantryItems.isEmpty {
            return .expiredReview(count: expiredPantryItems.count)
        }

        if let favoriteReadyRecipe = favoriteSavedRecipes.first(where: isSavedRecipeReady) {
            return .favoriteReady(recipe: favoriteReadyRecipe)
        }

        if let stapleRecommendationRecord {
            return .stapleReady(record: stapleRecommendationRecord)
        }

        if let latestCookedRecord, recentCookedCanBeCookedAgain(latestCookedRecord) {
            return .cookAgain(record: latestCookedRecord)
        }

        if let pick = tonightsPickRecommendation {
            return pick
        }

        if let readySavedRecipe = savedRecipes.first(where: isSavedRecipeReady) {
            return .savedRecipeReady(recipe: readySavedRecipe)
        }

        if let almostReadySavedRecipe = savedRecipes
            .compactMap({ saved -> (SavedRecipe, [String], Int)? in
                let issues = savedRecipeIssues(saved)
                let missingCount = savedRecipeMissingCount(saved)
                guard !issues.isEmpty, missingCount > 0, missingCount <= 2 else { return nil }
                return (saved, issues, missingCount)
            })
            .sorted(by: { $0.2 < $1.2 })
            .first
        {
            return .savedRecipeNearMiss(
                recipe: almostReadySavedRecipe.0,
                missingCount: almostReadySavedRecipe.2,
                reason: almostReadySavedRecipe.1.first ?? "A few ingredients are missing."
            )
        }

        if !expiringSoonItems.isEmpty {
            return .useSoon(items: Array(expiringSoonItems.prefix(2)))
        }

        if !usablePantryItems.isEmpty {
            return .cookFromPantry
        }

        return nil
    }

    private var tonightsPickRecommendation: HomeRecommendation? {
        guard let gap = nutritionGap, gap.remainingProteinG > 20 else { return nil }

        guard let best = savedRecipes
            .filter({ isSavedRecipeReady($0) && $0.recipe.protein > 0 })
            .max(by: { $0.recipe.protein < $1.recipe.protein })
        else { return nil }

        let pct = min(100, Int(Double(best.recipe.protein) / Double(gap.remainingProteinG) * 100))
        let reason = "Adds ~\(best.recipe.protein)g protein — \(pct)% of your remaining goal today"
        return .tonightsPick(recipe: best, reason: reason)
    }

    private var latestCookedRecord: CookedMealRecord? {
        cookedRecords.first
    }

    private var favoriteSavedRecipes: [SavedRecipe] {
        savedRecipes.filter(\.isFavorite)
    }

    private var stapleRecommendationRecord: CookedMealRecord? {
        for staple in staples {
            if let record = cookedRecords.first(where: { $0.recipeTitle == staple.recipeTitle && recentCookedCanBeCookedAgain($0) }) {
                return record
            }
        }
        return nil
    }

    private func isSavedRecipeReady(_ saved: SavedRecipe) -> Bool {
        savedRecipeIssues(saved).isEmpty
    }

    private func recentCookedCanBeCookedAgain(_ record: CookedMealRecord) -> Bool {
        replayIssues(record).isEmpty
    }
}
