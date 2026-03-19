import Foundation

struct SavedRecipe: Identifiable, Codable, Hashable {
    let id: UUID
    let recipe: Recipe
    let profileId: UUID
    let profileNameSnapshot: String
    let savedAt: Date

    init(
        id: UUID = UUID(),
        recipe: Recipe,
        profileId: UUID,
        profileNameSnapshot: String,
        savedAt: Date = .now
    ) {
        self.id = id
        self.recipe = recipe
        self.profileId = profileId
        self.profileNameSnapshot = profileNameSnapshot
        self.savedAt = savedAt
    }
}
