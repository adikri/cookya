import XCTest
@testable import cookya

@MainActor
final class WeeklyPlanStoreTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var store: WeeklyPlanStore!

    override func setUp() {
        super.setUp()
        testSuiteName = "WeeklyPlanStoreTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        store = WeeklyPlanStore(userDefaults: testDefaults)
    }

    override func tearDown() {
        store = nil
        if let testSuiteName {
            testDefaults?.removePersistentDomain(forName: testSuiteName)
        }
        testDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    // MARK: - add

    func testAddMealAppendsToPlan() {
        let recipe = makeSavedRecipe(title: "Dal")

        store.add(recipe)

        XCTAssertEqual(store.meals.count, 1)
        XCTAssertEqual(store.meals.first?.recipeTitle, "Dal")
        XCTAssertEqual(store.meals.first?.savedRecipeId, recipe.id)
    }

    func testAddDuplicateRecipeIsIgnored() {
        let recipe = makeSavedRecipe(title: "Dal")

        store.add(recipe)
        store.add(recipe)

        XCTAssertEqual(store.meals.count, 1)
    }

    func testAddBeyondMaxLimitIsIgnored() {
        for i in 1...store.maxMeals {
            store.add(makeSavedRecipe(title: "Recipe \(i)"))
        }
        store.add(makeSavedRecipe(title: "One Too Many"))

        XCTAssertEqual(store.meals.count, store.maxMeals)
    }

    func testIsFullReturnsTrueAtMaxCapacity() {
        XCTAssertFalse(store.isFull)

        for i in 1...store.maxMeals {
            store.add(makeSavedRecipe(title: "Recipe \(i)"))
        }

        XCTAssertTrue(store.isFull)
    }

    // MARK: - contains

    func testContainsReturnsTrueForAddedRecipe() {
        let recipe = makeSavedRecipe(title: "Pasta")

        store.add(recipe)

        XCTAssertTrue(store.contains(savedRecipeId: recipe.id))
    }

    func testContainsReturnsFalseForUnadddedRecipe() {
        store.add(makeSavedRecipe(title: "Pasta"))

        XCTAssertFalse(store.contains(savedRecipeId: UUID()))
    }

    // MARK: - remove

    func testRemoveByMealRemovesCorrectEntry() {
        store.add(makeSavedRecipe(title: "Dal"))
        store.add(makeSavedRecipe(title: "Pasta"))

        store.remove(store.meals.first!)

        XCTAssertEqual(store.meals.count, 1)
        XCTAssertEqual(store.meals.first?.recipeTitle, "Pasta")
    }

    func testRemoveAtOffsetsRemovesCorrectEntry() {
        store.add(makeSavedRecipe(title: "Dal"))
        store.add(makeSavedRecipe(title: "Pasta"))

        store.remove(at: IndexSet(integer: 0))

        XCTAssertEqual(store.meals.count, 1)
        XCTAssertEqual(store.meals.first?.recipeTitle, "Pasta")
    }

    // MARK: - clearAll

    func testClearAllEmptiesPlan() {
        store.add(makeSavedRecipe(title: "Dal"))
        store.add(makeSavedRecipe(title: "Pasta"))

        store.clearAll()

        XCTAssertTrue(store.meals.isEmpty)
    }

    // MARK: - persistence

    func testMealsSurvivePersistAndReload() {
        store.add(makeSavedRecipe(title: "Dal"))
        store.add(makeSavedRecipe(title: "Pasta"))

        store.reloadFromDisk()

        XCTAssertEqual(store.meals.count, 2)
        XCTAssertEqual(store.meals.map(\.recipeTitle), ["Dal", "Pasta"])
    }

    func testClearAllPersistsEmptyPlan() {
        store.add(makeSavedRecipe(title: "Dal"))
        store.clearAll()

        store.reloadFromDisk()

        XCTAssertTrue(store.meals.isEmpty)
    }

    func testBadPersistedDataFallsBackToEmpty() {
        testDefaults.set("not valid json".data(using: .utf8), forKey: AppPersistenceKey.weeklyMealPlan)

        store.reloadFromDisk()

        XCTAssertTrue(store.meals.isEmpty)
    }

    private func makeSavedRecipe(title: String) -> SavedRecipe {
        SavedRecipe(
            id: UUID(),
            recipe: Recipe(
                title: title,
                ingredients: [],
                instructions: ["Cook"],
                calories: 400,
                difficulty: .easy
            ),
            profileId: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
            profileNameSnapshot: "Test",
            savedAt: Date(timeIntervalSince1970: 100),
            isFavorite: false
        )
    }
}
