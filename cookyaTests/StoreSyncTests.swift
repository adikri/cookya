import XCTest
@testable import cookya

// Yield multiple times to allow fire-and-forget sync Tasks to complete
// before assertions run. Identical semantics to drainObservers() in AuthStoreTests.
@MainActor
private func drainSync() async {
    for _ in 0..<3 { await Task.yield() }
}

// MARK: - RecipeStore

@MainActor
final class RecipeStoreSyncTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var syncService: MockSavedRecipeSyncService!

    override func setUp() {
        super.setUp()
        testSuiteName = "RecipeStoreSyncTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        syncService = MockSavedRecipeSyncService()
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: testSuiteName)
        syncService = nil; testDefaults = nil; testSuiteName = nil
        super.tearDown()
    }

    func testSaveRecipeCallsUpsert() async {
        let store = RecipeStore(userDefaults: testDefaults, syncService: syncService)
        let recipe = makeRecipe(title: "Dal Tadka")

        store.saveRecipe(recipe, for: nil)
        await drainSync()

        XCTAssertEqual(syncService.upsertedRecipes.count, 1)
        XCTAssertEqual(syncService.upsertedRecipes.first?.recipe.title, "Dal Tadka")
    }

    func testRemoveRecipesCallsDelete() async {
        let store = RecipeStore(userDefaults: testDefaults, syncService: syncService)
        store.saveRecipe(makeRecipe(title: "Dal Tadka"), for: nil)
        await drainSync()
        syncService.reset()

        store.removeRecipes(at: IndexSet([0]))
        await drainSync()

        XCTAssertEqual(syncService.deletedIds.count, 1)
    }

    func testSaveRecipeWithNilSyncServiceWorksLocally() async {
        let store = RecipeStore(userDefaults: testDefaults, syncService: nil)

        store.saveRecipe(makeRecipe(title: "Dal Tadka"), for: nil)
        await drainSync()

        XCTAssertEqual(store.recipes(for: nil).count, 1)
    }
}

// MARK: - CookedMealStore

@MainActor
final class CookedMealStoreSyncTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var syncService: MockCookedMealSyncService!

    override func setUp() {
        super.setUp()
        testSuiteName = "CookedMealStoreSyncTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        syncService = MockCookedMealSyncService()
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: testSuiteName)
        syncService = nil; testDefaults = nil; testSuiteName = nil
        super.tearDown()
    }

    func testAddRecordCallsUpsert() async {
        let store = CookedMealStore(userDefaults: testDefaults, syncService: syncService)

        store.addRecord(recipe: makeRecipe(title: "Butter Chicken"), consumptions: [], warnings: [], profile: nil)
        await drainSync()

        XCTAssertEqual(syncService.upsertedRecords.count, 1)
        XCTAssertEqual(syncService.upsertedRecords.first?.recipeTitle, "Butter Chicken")
    }

    func testDeleteRecordCallsDelete() async {
        let store = CookedMealStore(userDefaults: testDefaults, syncService: syncService)
        store.addRecord(recipe: makeRecipe(title: "Butter Chicken"), consumptions: [], warnings: [], profile: nil)
        await drainSync()
        syncService.reset()

        let record = store.records.first!
        store.deleteRecord(record)
        await drainSync()

        XCTAssertEqual(syncService.deletedIds.count, 1)
        XCTAssertEqual(syncService.deletedIds.first, record.id)
    }

    func testAddRecordWithNilSyncServiceWorksLocally() async {
        let store = CookedMealStore(userDefaults: testDefaults, syncService: nil)

        store.addRecord(recipe: makeRecipe(title: "Butter Chicken"), consumptions: [], warnings: [], profile: nil)
        await drainSync()

        XCTAssertEqual(store.records.count, 1)
    }
}

// MARK: - ProfileStore

@MainActor
final class ProfileStoreSyncTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var syncService: MockProfileSyncService!

    override func setUp() {
        super.setUp()
        testSuiteName = "ProfileStoreSyncTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        syncService = MockProfileSyncService()
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: testSuiteName)
        syncService = nil; testDefaults = nil; testSuiteName = nil
        super.tearDown()
    }

    func testCreateProfileCallsUpsert() async {
        let store = ProfileStore(userDefaults: testDefaults, syncService: syncService)

        store.createRegisteredProfile(
            name: "Adi", age: 30, weightKg: 75, heightCm: 175,
            location: nil, isVegetarian: false, avoidFoodItems: []
        )
        await drainSync()

        XCTAssertEqual(syncService.upsertedProfiles.count, 1)
        XCTAssertEqual(syncService.upsertedProfiles.first?.name, "Adi")
    }

    func testCreateProfileWithNilSyncServiceWorksLocally() async {
        let store = ProfileStore(userDefaults: testDefaults, syncService: nil)

        store.createRegisteredProfile(
            name: "Adi", age: nil, weightKg: nil, heightCm: nil,
            location: nil, isVegetarian: false, avoidFoodItems: []
        )
        await drainSync()

        XCTAssertNotNil(store.primaryProfile)
        XCTAssertEqual(store.primaryProfile?.name, "Adi")
    }
}

// MARK: - WeeklyPlanStore

@MainActor
final class WeeklyPlanStoreSyncTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var syncService: MockWeeklyPlanSyncService!

    override func setUp() {
        super.setUp()
        testSuiteName = "WeeklyPlanStoreSyncTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        syncService = MockWeeklyPlanSyncService()
    }

    override func tearDown() {
        testDefaults?.removePersistentDomain(forName: testSuiteName)
        syncService = nil; testDefaults = nil; testSuiteName = nil
        super.tearDown()
    }

    func testAddMealCallsUpsert() async {
        let store = WeeklyPlanStore(userDefaults: testDefaults, syncService: syncService)

        store.add(makeSavedRecipe(title: "Rajma Chawal"))
        await drainSync()

        XCTAssertEqual(syncService.upsertedMeals.count, 1)
        XCTAssertEqual(syncService.upsertedMeals.first?.recipeTitle, "Rajma Chawal")
    }

    func testRemoveMealCallsDelete() async {
        let store = WeeklyPlanStore(userDefaults: testDefaults, syncService: syncService)
        store.add(makeSavedRecipe(title: "Rajma Chawal"))
        await drainSync()
        syncService.reset()

        let meal = store.meals.first!
        store.remove(meal)
        await drainSync()

        XCTAssertEqual(syncService.deletedIds.count, 1)
        XCTAssertEqual(syncService.deletedIds.first, meal.id)
    }

    func testClearAllCallsClearAllMeals() async {
        let store = WeeklyPlanStore(userDefaults: testDefaults, syncService: syncService)
        store.add(makeSavedRecipe(title: "Dal"))
        store.add(makeSavedRecipe(title: "Rice"))
        await drainSync()
        syncService.reset()

        store.clearAll()
        await drainSync()

        XCTAssertEqual(syncService.clearAllCallCount, 1)
        XCTAssertTrue(store.meals.isEmpty)
    }

    func testAddMealWithNilSyncServiceWorksLocally() async {
        let store = WeeklyPlanStore(userDefaults: testDefaults, syncService: nil)

        store.add(makeSavedRecipe(title: "Rajma Chawal"))
        await drainSync()

        XCTAssertEqual(store.meals.count, 1)
    }
}

// MARK: - Mocks

@MainActor
private final class MockSavedRecipeSyncService: SavedRecipeSyncing {
    private(set) var upsertedRecipes: [SavedRecipe] = []
    private(set) var deletedIds: [UUID] = []

    func reset() { upsertedRecipes.removeAll(); deletedIds.removeAll() }

    func fetchSavedRecipes() async throws -> [SavedRecipe] { [] }
    func upsertSavedRecipe(_ recipe: SavedRecipe) async throws { upsertedRecipes.append(recipe) }
    func deleteSavedRecipe(id: UUID) async throws { deletedIds.append(id) }
}

@MainActor
private final class MockCookedMealSyncService: CookedMealSyncing {
    private(set) var upsertedRecords: [CookedMealRecord] = []
    private(set) var deletedIds: [UUID] = []

    func reset() { upsertedRecords.removeAll(); deletedIds.removeAll() }

    func fetchRecords() async throws -> [CookedMealRecord] { [] }
    func upsertRecord(_ record: CookedMealRecord) async throws { upsertedRecords.append(record) }
    func deleteRecord(id: UUID) async throws { deletedIds.append(id) }
}

@MainActor
private final class MockProfileSyncService: ProfileSyncing {
    private(set) var upsertedProfiles: [UserProfile] = []

    func fetchProfile() async throws -> UserProfile? { nil }
    func upsertProfile(_ profile: UserProfile) async throws { upsertedProfiles.append(profile) }
}

@MainActor
private final class MockWeeklyPlanSyncService: WeeklyPlanSyncing {
    private(set) var upsertedMeals: [PlannedMeal] = []
    private(set) var deletedIds: [UUID] = []
    private(set) var clearAllCallCount = 0

    func reset() { upsertedMeals.removeAll(); deletedIds.removeAll(); clearAllCallCount = 0 }

    func fetchMeals() async throws -> [PlannedMeal] { [] }
    func upsertMeal(_ meal: PlannedMeal) async throws { upsertedMeals.append(meal) }
    func deleteMeal(id: UUID) async throws { deletedIds.append(id) }
    func clearAllMeals() async throws { clearAllCallCount += 1 }
}

// MARK: - Factories

private func makeRecipe(title: String) -> Recipe {
    Recipe(
        title: title,
        ingredients: [],
        instructions: ["Cook it."],
        calories: 400,
        difficulty: .medium
    )
}

private func makeSavedRecipe(title: String) -> SavedRecipe {
    SavedRecipe(
        recipe: makeRecipe(title: title),
        profileId: UUID(),
        profileNameSnapshot: "Adi"
    )
}
