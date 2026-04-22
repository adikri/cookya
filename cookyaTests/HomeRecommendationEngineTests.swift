import XCTest
@testable import cookya

final class HomeRecommendationEngineTests: XCTestCase {
    func testExpiredReviewWinsOverFavoriteReady() {
        let favorite = makeSavedRecipe(title: "Favorite Soup", favorite: true)
        let engine = makeEngine(
            expiredPantryItems: [makePantryItem(name: "Milk")],
            savedRecipes: [favorite],
            savedRecipeIssues: [favorite.id: []]
        )

        XCTAssertEqual(engine.bestNextStep(), .expiredReview(count: 1))
    }

    func testFavoriteReadyWinsOverStapleAndCookAgain() {
        let favorite = makeSavedRecipe(title: "Favorite Pasta", favorite: true)
        let stapleRecord = makeRecord(title: "Dal")
        let engine = makeEngine(
            savedRecipes: [favorite],
            cookedRecords: [stapleRecord],
            staples: [MealStaple(recipeTitle: "Dal", cookCount: 3, lastCookedAt: stapleRecord.cookedAt)],
            savedRecipeIssues: [favorite.id: []]
        )

        XCTAssertEqual(engine.bestNextStep(), .favoriteReady(recipe: favorite))
    }

    func testStapleReadyWinsOverGenericCookAgain() {
        let stapleRecord = makeRecord(title: "Dal", cookedAt: Date(timeIntervalSince1970: 200))
        let latestRecord = makeRecord(title: "Toast", cookedAt: Date(timeIntervalSince1970: 300))
        let engine = makeEngine(
            cookedRecords: [latestRecord, stapleRecord],
            staples: [MealStaple(recipeTitle: "Dal", cookCount: 2, lastCookedAt: stapleRecord.cookedAt)]
        )

        XCTAssertEqual(engine.bestNextStep(), .stapleReady(record: stapleRecord))
    }

    func testReadySavedRecipeWinsOverNearMiss() {
        let ready = makeSavedRecipe(title: "Ready Curry")
        let nearMiss = makeSavedRecipe(title: "Near Miss")
        let engine = makeEngine(
            savedRecipes: [ready, nearMiss],
            savedRecipeIssues: [
                ready.id: [],
                nearMiss.id: ["Missing 1 item: Onion"]
            ],
            savedRecipeMissingCounts: [
                ready.id: 0,
                nearMiss.id: 1
            ]
        )

        XCTAssertEqual(engine.bestNextStep(), .savedRecipeReady(recipe: ready))
    }

    func testNearMissChoosesLowestMissingCount() {
        let oneAway = makeSavedRecipe(title: "One Away")
        let twoAway = makeSavedRecipe(title: "Two Away")
        let engine = makeEngine(
            savedRecipes: [twoAway, oneAway],
            savedRecipeIssues: [
                oneAway.id: ["Missing 1 item: Onion"],
                twoAway.id: ["Missing 2 items"]
            ],
            savedRecipeMissingCounts: [
                oneAway.id: 1,
                twoAway.id: 2
            ]
        )

        XCTAssertEqual(
            engine.bestNextStep(),
            .savedRecipeNearMiss(recipe: oneAway, missingCount: 1, reason: "Missing 1 item: Onion")
        )
    }

    func testUseSoonWinsOverGenericCookFromPantry() {
        let engine = makeEngine(
            expiringSoonItems: [
                makePantryItem(name: "Spinach"),
                makePantryItem(name: "Yogurt"),
                makePantryItem(name: "Tomato")
            ],
            usablePantryItems: [makePantryItem(name: "Rice")]
        )

        XCTAssertEqual(
            engine.bestNextStep(),
            .useSoon(items: [makePantryItem(name: "Spinach"), makePantryItem(name: "Yogurt")])
        )
    }

    func testReturnsCookFromPantryWhenNoHigherPriorityActionExists() {
        let engine = makeEngine(
            usablePantryItems: [makePantryItem(name: "Rice")]
        )

        XCTAssertEqual(engine.bestNextStep(), .cookFromPantry)
    }

    private func makeEngine(
        expiredPantryItems: [PantryItem] = [],
        expiringSoonItems: [PantryItem] = [],
        usablePantryItems: [PantryItem] = [],
        savedRecipes: [SavedRecipe] = [],
        cookedRecords: [CookedMealRecord] = [],
        staples: [MealStaple] = [],
        savedRecipeIssues: [UUID: [String]] = [:],
        savedRecipeMissingCounts: [UUID: Int] = [:],
        replayIssues: [UUID: [String]] = [:]
    ) -> HomeRecommendationEngine {
        HomeRecommendationEngine(
            expiredPantryItems: expiredPantryItems,
            expiringSoonItems: expiringSoonItems,
            usablePantryItems: usablePantryItems,
            savedRecipes: savedRecipes,
            cookedRecords: cookedRecords,
            staples: staples,
            savedRecipeIssues: { saved in
                savedRecipeIssues[saved.id] ?? []
            },
            savedRecipeMissingCount: { saved in
                savedRecipeMissingCounts[saved.id] ?? 0
            },
            replayIssues: { record in
                replayIssues[record.id] ?? []
            }
        )
    }

    private func makeSavedRecipe(title: String, favorite: Bool = false) -> SavedRecipe {
        SavedRecipe(
            id: UUID(),
            recipe: Recipe(
                title: title,
                ingredients: [Ingredient(name: "Onion", quantity: "1")],
                instructions: ["Cook"],
                calories: 400,
                difficulty: .easy
            ),
            profileId: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            profileNameSnapshot: "Test",
            savedAt: Date(timeIntervalSince1970: 100),
            isFavorite: favorite
        )
    }

    private func makeRecord(title: String, cookedAt: Date = Date(timeIntervalSince1970: 100)) -> CookedMealRecord {
        CookedMealRecord(
            id: UUID(),
            cookedAt: cookedAt,
            profileId: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            profileNameSnapshot: "Test",
            recipeTitle: title,
            recipeIngredients: [Ingredient(name: "Onion", quantity: "1")],
            consumptions: [],
            warnings: []
        )
    }

    private func makePantryItem(name: String) -> PantryItem {
        PantryItem(
            id: UUID(uuidString: name.hasPrefix("S") ? "00000000-0000-0000-0000-000000000201" : name.hasPrefix("Y") ? "00000000-0000-0000-0000-000000000202" : name.hasPrefix("T") ? "00000000-0000-0000-0000-000000000203" : "00000000-0000-0000-0000-000000000204")!,
            name: name,
            quantityText: "1",
            category: .pantry,
            expiryDate: nil,
            updatedAt: Date(timeIntervalSince1970: 100)
        )
    }
}
