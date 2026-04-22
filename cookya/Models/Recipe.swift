import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var ingredients: [Ingredient]
    var instructions: [String]
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var fiber: Int
    var difficulty: Difficulty

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [Ingredient],
        instructions: [String],
        calories: Int,
        protein: Int = 0,
        carbs: Int = 0,
        fat: Int = 0,
        fiber: Int = 0,
        difficulty: Difficulty
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.difficulty = difficulty
    }

    enum CodingKeys: String, CodingKey {
        case id, title, ingredients, instructions
        case calories, protein, carbs, fat, fiber
        case difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decodeIfPresent(Int.self, forKey: .protein) ?? 0
        carbs = try container.decodeIfPresent(Int.self, forKey: .carbs) ?? 0
        fat = try container.decodeIfPresent(Int.self, forKey: .fat) ?? 0
        fiber = try container.decodeIfPresent(Int.self, forKey: .fiber) ?? 0
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
    }
}
