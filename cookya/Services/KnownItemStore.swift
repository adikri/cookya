import SwiftUI
import Combine

@MainActor
final class KnownItemStore: ObservableObject {
    @Published private(set) var knownItems: [KnownInventoryItem] = []

    private let storageKey = "known_inventory_items_v1"
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
        load()
    }

    var recentItems: [KnownInventoryItem] {
        knownItems.sorted { lhs, rhs in
            if lhs.lastUsedAt != rhs.lastUsedAt {
                return lhs.lastUsedAt > rhs.lastUsedAt
            }
            return lhs.usageCount > rhs.usageCount
        }
    }

    func suggestions(matching rawQuery: String) -> [KnownInventoryItem] {
        let query = KnownInventoryItemNormalizer.normalize(rawQuery)
        guard !query.isEmpty else {
            return Array(recentItems.prefix(5))
        }

        return recentItems.filter {
            $0.normalizedName.contains(query) || $0.name.localizedCaseInsensitiveContains(rawQuery)
        }
    }

    func upsertFromPantryItem(_ item: PantryItem) {
        upsert(
            name: item.name,
            category: item.category,
            quantityText: item.quantityText,
            source: .pantry
        )
    }

    func upsertFromGroceryItem(_ item: GroceryItem) {
        upsert(
            name: item.name,
            category: item.category,
            quantityText: item.quantityText,
            source: .grocery
        )
    }

    private func upsert(
        name: String,
        category: InventoryCategory,
        quantityText: String,
        source: KnownItemSource
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let normalizedName = KnownInventoryItemNormalizer.normalize(trimmedName)

        if let index = knownItems.firstIndex(where: { $0.normalizedName == normalizedName }) {
            knownItems[index].name = trimmedName
            knownItems[index].normalizedName = normalizedName
            knownItems[index].defaultCategory = category
            knownItems[index].lastQuantityText = quantityText
            knownItems[index].lastSource = source
            knownItems[index].lastUsedAt = .now
            knownItems[index].usageCount += 1
            AppLogger.log("Known item updated", metadata: ["item": trimmedName, "source": source.rawValue])
        } else {
            knownItems.append(
                KnownInventoryItem(
                    name: trimmedName,
                    defaultCategory: category,
                    lastQuantityText: quantityText,
                    lastSource: source
                )
            )
            AppLogger.log("Known item created", metadata: ["item": trimmedName, "source": source.rawValue])
        }

        persist()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }

        do {
            knownItems = try decoder.decode([KnownInventoryItem].self, from: data)
        } catch {
            knownItems = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(knownItems)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to persist known inventory items: \(error)")
        }
    }
}
