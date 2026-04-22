import Foundation

struct NutritionGoals: Codable, Hashable {
    var dailyCalories: Int
    var dailyProteinG: Int

    // Mifflin-St Jeor (gender-neutral) × 1.375 (lightly active); protein at 1.6 g/kg
    static func suggested(weightKg: Double, heightCm: Double, age: Int) -> NutritionGoals {
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 78
        let tdee = bmr * 1.375
        let calories = max(Int((tdee / 50).rounded() * 50), 1200)
        let protein = max(Int((1.6 * weightKg / 5).rounded() * 5), 50)
        return NutritionGoals(dailyCalories: calories, dailyProteinG: protein)
    }
}

struct NutritionSummary {
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let fiberG: Int

    static let zero = NutritionSummary(calories: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0)
}

struct NutritionGap: Hashable {
    let remainingCalories: Int
    let remainingProteinG: Int
}
