import Foundation

struct SavedRecipe: Identifiable, Codable, Hashable {
    let id: UUID
    let recipe: Recipe
    let profileId: UUID
    let profileNameSnapshot: String
    let savedAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        recipe: Recipe,
        profileId: UUID,
        profileNameSnapshot: String,
        savedAt: Date = .now,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.recipe = recipe
        self.profileId = profileId
        self.profileNameSnapshot = profileNameSnapshot
        self.savedAt = savedAt
        self.isFavorite = isFavorite
    }

    enum CodingKeys: String, CodingKey {
        case id
        case recipe
        case profileId
        case profileNameSnapshot
        case savedAt
        case isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recipe = try container.decode(Recipe.self, forKey: .recipe)
        profileId = try container.decode(UUID.self, forKey: .profileId)
        profileNameSnapshot = try container.decode(String.self, forKey: .profileNameSnapshot)
        savedAt = try container.decode(Date.self, forKey: .savedAt)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
}
