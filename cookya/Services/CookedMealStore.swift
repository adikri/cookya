import SwiftUI
import Combine

struct MealStaple: Identifiable, Hashable {
    let id: String
    let recipeTitle: String
    let cookCount: Int
    let lastCookedAt: Date

    init(recipeTitle: String, cookCount: Int, lastCookedAt: Date) {
        self.id = recipeTitle
        self.recipeTitle = recipeTitle
        self.cookCount = cookCount
        self.lastCookedAt = lastCookedAt
    }
}

@MainActor
final class CookedMealStore: ObservableObject {
    @Published private(set) var records: [CookedMealRecord] = []

    private let guestProfileId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let storageKey = AppPersistenceKey.cookedMealRecords
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        loadRecords()
    }

    func addRecord(
        recipe: Recipe,
        consumptions: [PantryConsumption],
        warnings: [String],
        profile: UserProfile?
    ) {
        insertRecord(
            recipeTitle: recipe.title,
            recipeIngredients: recipe.ingredients,
            consumptions: consumptions,
            warnings: warnings,
            profile: profile,
            calories: recipe.calories,
            proteinG: recipe.protein,
            carbsG: recipe.carbs,
            fatG: recipe.fat,
            fiberG: recipe.fiber
        )
    }

    func records(for profile: UserProfile?) -> [CookedMealRecord] {
        let profileId = profile?.id ?? guestProfileId
        return records.filter { $0.profileId == profileId }
    }

    func addReplayRecord(
        from source: CookedMealRecord,
        consumptions: [PantryConsumption],
        warnings: [String],
        profile: UserProfile?
    ) {
        insertRecord(
            recipeTitle: source.recipeTitle,
            recipeIngredients: source.recipeIngredients,
            consumptions: consumptions,
            warnings: warnings,
            profile: profile,
            calories: source.calories,
            proteinG: source.proteinG,
            carbsG: source.carbsG,
            fatG: source.fatG,
            fiberG: source.fiberG
        )
    }

    func deleteRecord(_ record: CookedMealRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func restoreRecord(_ record: CookedMealRecord) {
        records.removeAll { $0.id == record.id }
        records.append(record)
        records.sort { lhs, rhs in
            lhs.cookedAt > rhs.cookedAt
        }
        persist()
    }

    func staples(for profile: UserProfile?) -> [MealStaple] {
        let grouped = Dictionary(grouping: records(for: profile), by: \.recipeTitle)
        return grouped.compactMap { recipeTitle, records in
            guard records.count >= 2,
                  let latest = records.map(\.cookedAt).max() else {
                return nil
            }
            return MealStaple(
                recipeTitle: recipeTitle,
                cookCount: records.count,
                lastCookedAt: latest
            )
        }
        .sorted { lhs, rhs in
            if lhs.cookCount != rhs.cookCount {
                return lhs.cookCount > rhs.cookCount
            }
            return lhs.lastCookedAt > rhs.lastCookedAt
        }
    }

    private func loadRecords() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        guard PersistencePayloadValidator.matchesExpectedTopLevel(data, shape: .array) else {
            records = []
            AppLogger.action(
                "persistence_decode_failed",
                screen: "CookedMealStore",
                metadata: ["key": storageKey, "entity": "cookedMealRecords", "error": "Unexpected top-level JSON shape"]
            )
            return
        }
        do {
            records = try decoder.decode([CookedMealRecord].self, from: data)
        } catch {
            records = []
            AppLogger.action(
                "persistence_decode_failed",
                screen: "CookedMealStore",
                metadata: ["key": storageKey, "entity": "cookedMealRecords", "error": String(describing: error)]
            )
        }
    }

    func todayNutrition(for profile: UserProfile?) -> NutritionSummary {
        let today = Calendar.current.startOfDay(for: .now)
        let todayRecords = records(for: profile).filter { $0.cookedAt >= today }
        return todayRecords.reduce(.zero) { sum, record in
            NutritionSummary(
                calories: sum.calories + record.calories,
                proteinG: sum.proteinG + record.proteinG,
                carbsG: sum.carbsG + record.carbsG,
                fatG: sum.fatG + record.fatG,
                fiberG: sum.fiberG + record.fiberG
            )
        }
    }

    func nutritionGap(for profile: UserProfile?) -> NutritionGap? {
        guard let goals = profile?.effectiveNutritionGoals else { return nil }
        let today = todayNutrition(for: profile)
        return NutritionGap(
            remainingCalories: goals.dailyCalories - today.calories,
            remainingProteinG: goals.dailyProteinG - today.proteinG
        )
    }

    private func insertRecord(
        recipeTitle: String,
        recipeIngredients: [Ingredient],
        consumptions: [PantryConsumption],
        warnings: [String],
        profile: UserProfile?,
        calories: Int = 0,
        proteinG: Int = 0,
        carbsG: Int = 0,
        fatG: Int = 0,
        fiberG: Int = 0
    ) {
        let profileId = profile?.id ?? guestProfileId
        let profileName = profile?.name ?? "Guest"

        let record = CookedMealRecord(
            profileId: profileId,
            profileNameSnapshot: profileName,
            recipeTitle: recipeTitle,
            recipeIngredients: recipeIngredients,
            consumptions: consumptions.filter { !$0.usedQuantityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            warnings: warnings,
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG
        )

        records.insert(record, at: 0)
        persist()
    }

    private func persist() {
        do {
            let data = try encoder.encode(records)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "CookedMealStore",
                metadata: ["key": storageKey, "entity": "cookedMealRecords", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist cooked meal records: \(error)")
        }
    }

    func reloadFromDisk() {
        loadRecords()
    }
}
