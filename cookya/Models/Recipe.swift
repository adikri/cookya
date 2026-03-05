import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]
    var calories: Int
    var difficulty: Difficulty

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [Ingredient],
        instructions: [String],
        calories: Int,
        difficulty: Difficulty
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.calories = calories
        self.difficulty = difficulty
    }
}
