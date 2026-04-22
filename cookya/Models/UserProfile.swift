import Foundation

enum ProfileType: String, Codable, Hashable {
    case guest
    case registered
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var type: ProfileType
    var name: String
    var age: Int?
    var weightKg: Double?
    var heightCm: Double?
    var location: String?
    var isVegetarian: Bool
    var avoidFoodItems: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        type: ProfileType,
        name: String,
        age: Int? = nil,
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        location: String? = nil,
        isVegetarian: Bool = false,
        avoidFoodItems: [String] = [],
        nutritionGoals: NutritionGoals? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.age = age
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.location = location
        self.isVegetarian = isVegetarian
        self.avoidFoodItems = avoidFoodItems
        self.nutritionGoals = nutritionGoals
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var nutritionGoals: NutritionGoals?

    var bmi: Double? {
        guard let weightKg, let heightCm, heightCm > 0 else { return nil }
        let meters = heightCm / 100
        let value = weightKg / (meters * meters)
        return (value * 10).rounded() / 10
    }

    var suggestedNutritionGoals: NutritionGoals? {
        guard let weightKg, let heightCm, let age else { return nil }
        return NutritionGoals.suggested(weightKg: weightKg, heightCm: heightCm, age: age)
    }

    var effectiveNutritionGoals: NutritionGoals? {
        nutritionGoals ?? suggestedNutritionGoals
    }
}
