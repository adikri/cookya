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

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case ingredients
        case instructions
        case calories
        case difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)
        calories = try container.decode(Int.self, forKey: .calories)
        difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
    }
}
