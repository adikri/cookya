import XCTest
@testable import cookya

@MainActor
final class RecipeViewModelTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!

    override func setUp() {
        super.setUp()
        testSuiteName = "RecipeViewModelTests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
    }

    override func tearDown() {
        if let testSuiteName {
            testDefaults?.removePersistentDomain(forName: testSuiteName)
        }
        testDefaults = nil
        testSuiteName = nil
        super.tearDown()
    }

    func testGenerateRecipeSuccessSetsGeneratedRecipe() async {
        let expected = Recipe(
            title: "Test Recipe",
            ingredients: [Ingredient(name: "Egg")],
            instructions: ["Step 1"],
            calories: 220,
            difficulty: .easy
        )
        let service = MockRecipeService(result: .success(expected))
        let viewModel = RecipeViewModel(
            recipeService: service,
            recipeStore: makeRecipeStore()
        )

        viewModel.ingredientInput = "Egg"
        viewModel.addIngredient()
        viewModel.generateRecipe(profile: nil, pantryItems: [])

        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.generatedRecipe?.title, expected.title)
        XCTAssertNil(viewModel.generationError)
        XCTAssertEqual(service.callCount, 1)
    }

    func testGenerateRecipeWithoutIngredientsShowsValidationError() {
        let service = MockRecipeService(result: .failure(RecipeGenerationError.networkError))
        let viewModel = RecipeViewModel(
            recipeService: service,
            recipeStore: makeRecipeStore()
        )

        viewModel.generateRecipe(profile: nil, pantryItems: [])

        XCTAssertEqual(viewModel.generationError, "Choose pantry items or add manual ingredients first.")
        XCTAssertEqual(service.callCount, 0)
    }

    func testGenerateRecipeServiceFailureSetsUserFacingError() async {
        let service = MockRecipeService(result: .failure(RecipeGenerationError.rateLimited))
        let viewModel = RecipeViewModel(
            recipeService: service,
            recipeStore: makeRecipeStore()
        )

        viewModel.ingredientInput = "Spinach"
        viewModel.addIngredient()
        viewModel.generateRecipe(profile: nil, pantryItems: [])

        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.generationError, RecipeGenerationError.rateLimited.errorDescription)
        XCTAssertNil(viewModel.generatedRecipe)
        XCTAssertEqual(service.callCount, 1)
    }

    func testGenerateRecipeSameNormalizedRequestUsesCache() async {
        let expected = Recipe(
            title: "Cached Recipe",
            ingredients: [Ingredient(name: "Coconut"), Ingredient(name: "Coriander")],
            instructions: ["Step 1"],
            calories: 180,
            difficulty: .easy
        )
        let service = MockRecipeService(result: .success(expected))
        let store = makeRecipeStore()
        let viewModel = RecipeViewModel(recipeService: service, recipeStore: store)

        viewModel.addIngredient(named: " Coconut ")
        viewModel.addIngredient(named: "coriander")
        viewModel.generateRecipe(profile: nil, pantryItems: [])

        await waitUntil { !viewModel.isLoading }
        XCTAssertEqual(service.callCount, 1)

        viewModel.ingredients = []
        viewModel.addIngredient(named: "coconut")
        viewModel.addIngredient(named: " coriander ")
        viewModel.generateRecipe(profile: nil, pantryItems: [])

        XCTAssertEqual(viewModel.generatedRecipe?.title, expected.title)
        XCTAssertEqual(service.callCount, 1)
    }

    func testGenerateAnotherRecipeBypassesCache() async {
        let first = Recipe(
            title: "First Recipe",
            ingredients: [Ingredient(name: "Egg")],
            instructions: ["Step 1"],
            calories: 200,
            difficulty: .easy
        )
        let second = Recipe(
            title: "Second Recipe",
            ingredients: [Ingredient(name: "Egg")],
            instructions: ["Step 1"],
            calories: 240,
            difficulty: .easy
        )
        let service = MockRecipeService(results: [.success(first), .success(second)])
        let store = makeRecipeStore()
        let viewModel = RecipeViewModel(recipeService: service, recipeStore: store)

        viewModel.addIngredient(named: "Egg")
        viewModel.generateRecipe(profile: nil, pantryItems: [])

        await waitUntil { !viewModel.isLoading }
        XCTAssertEqual(viewModel.generatedRecipe?.title, "First Recipe")
        XCTAssertEqual(service.callCount, 1)

        viewModel.generateRecipe(profile: nil, pantryItems: [], forceRefresh: true)

        await waitUntil { !viewModel.isLoading }
        XCTAssertEqual(viewModel.generatedRecipe?.title, "Second Recipe")
        XCTAssertEqual(service.callCount, 2)

        viewModel.generateRecipe(profile: nil, pantryItems: [])

        XCTAssertEqual(viewModel.generatedRecipe?.title, "Second Recipe")
        XCTAssertEqual(service.callCount, 2)
    }

    private func waitUntil(timeoutNanos: UInt64 = 2_000_000_000, condition: @escaping () -> Bool) async {
        let start = DispatchTime.now().uptimeNanoseconds

        while !condition() {
            if DispatchTime.now().uptimeNanoseconds - start > timeoutNanos {
                XCTFail("Timed out waiting for condition")
                return
            }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    private func makeRecipeStore() -> RecipeStore {
        RecipeStore(userDefaults: testDefaults, encoder: JSONEncoder(), decoder: JSONDecoder())
    }
}

private final class MockRecipeService: RecipeGeneratingService {
    var callCount: Int = 0
    private var results: [Result<Recipe, Error>]
    private(set) var lastRequest: RecipeGenerationRequest?

    init(result: Result<Recipe, Error>) {
        self.results = [result]
    }

    init(results: [Result<Recipe, Error>]) {
        self.results = results
    }

    func generateRecipe(request: RecipeGenerationRequest) async throws -> Recipe {
        callCount += 1
        lastRequest = request
        let nextResult = results.isEmpty ? .failure(RecipeGenerationError.networkError) : results.removeFirst()
        return try nextResult.get()
    }
}
