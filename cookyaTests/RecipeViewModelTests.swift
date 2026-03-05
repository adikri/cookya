import XCTest
@testable import cookya

@MainActor
final class RecipeViewModelTests: XCTestCase {

    func testGenerateRecipeSuccessSetsGeneratedRecipe() async {
        let expected = Recipe(
            title: "Test Recipe",
            ingredients: [Ingredient(name: "Egg")],
            instructions: ["Step 1"],
            calories: 220,
            difficulty: .easy
        )
        let service = MockRecipeService(result: .success(expected))
        let viewModel = RecipeViewModel(recipeService: service)

        viewModel.ingredientInput = "Egg"
        viewModel.addIngredient()
        viewModel.generateRecipe()

        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.generatedRecipe?.title, expected.title)
        XCTAssertNil(viewModel.generationError)
        XCTAssertEqual(service.callCount, 1)
    }

    func testGenerateRecipeWithoutIngredientsShowsValidationError() {
        let service = MockRecipeService(result: .failure(RecipeGenerationError.networkError))
        let viewModel = RecipeViewModel(recipeService: service)

        viewModel.generateRecipe()

        XCTAssertEqual(viewModel.generationError, "Please add at least one ingredient.")
        XCTAssertEqual(service.callCount, 0)
    }

    func testGenerateRecipeServiceFailureSetsUserFacingError() async {
        let service = MockRecipeService(result: .failure(RecipeGenerationError.rateLimited))
        let viewModel = RecipeViewModel(recipeService: service)

        viewModel.ingredientInput = "Spinach"
        viewModel.addIngredient()
        viewModel.generateRecipe()

        await waitUntil { !viewModel.isLoading }

        XCTAssertEqual(viewModel.generationError, RecipeGenerationError.rateLimited.errorDescription)
        XCTAssertNil(viewModel.generatedRecipe)
        XCTAssertEqual(service.callCount, 1)
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
}

private final class MockRecipeService: RecipeGeneratingService {
    var callCount: Int = 0
    private let result: Result<Recipe, Error>

    init(result: Result<Recipe, Error>) {
        self.result = result
    }

    func generateRecipe(ingredients: [Ingredient], difficulty: Difficulty) async throws -> Recipe {
        callCount += 1
        return try result.get()
    }
}
