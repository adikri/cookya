import SwiftUI
import Combine

struct PantryAvailabilityCheck: Identifiable {
    let id = UUID()
    let itemName: String
    let requestedQuantityText: String
    let pantryItem: PantryItem?
    let issue: String?

    var isMissing: Bool {
        pantryItem == nil
    }

    func toReplaySelection() -> PantryRecipeSelection? {
        guard let pantryItem, issue == nil else { return nil }
        return PantryRecipeSelection(
            pantryItem: pantryItem,
            selectedQuantityText: requestedQuantityText
        )
    }
}

struct PantryConsumptionResult {
    let warnings: [String]
    let applied: Bool
}

@MainActor
final class InventoryStore: ObservableObject {
    @Published private(set) var pantryItems: [PantryItem] = []
    @Published private(set) var groceryItems: [GroceryItem] = []
    @Published private(set) var isSyncing = false
    @Published var lastSyncError: String?

    private let inventoryService: InventorySyncingService
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let pantryStorageKey = AppPersistenceKey.pantryItems
    private let groceryStorageKey = AppPersistenceKey.groceryItems
    private var hasAttemptedInitialSync = false
    private let config: AppConfig

    init(
        inventoryService: InventorySyncingService? = nil,
        userDefaults: UserDefaults = .standard,
        config: AppConfig = .live
    ) {
        self.inventoryService = inventoryService ?? BackendInventoryService()
        self.userDefaults = userDefaults
        self.config = config

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        loadCache()
    }

    var expiringSoonItems: [PantryItem] {
        usablePantryItems.filter { $0.isExpiringSoon }
    }

    var usablePantryItems: [PantryItem] {
        sortedPantryItems.filter { !$0.isExpired }
    }

    var expiredPantryItems: [PantryItem] {
        sortedPantryItems.filter(\.isExpired)
    }

    var sortedPantryItems: [PantryItem] {
        pantryItems.sorted { lhs, rhs in
            switch (lhs.expiryDate, rhs.expiryDate) {
            case let (l?, r?):
                if l != r { return l < r }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var sortedGroceryItems: [GroceryItem] {
        groceryItems.sorted { lhs, rhs in
            lhs.createdAt > rhs.createdAt
        }
    }

    func groceryItem(named name: String) -> GroceryItem? {
        let normalizedName = Self.normalizeItemName(name)
        return groceryItems.first { Self.normalizeItemName($0.name) == normalizedName }
    }

    func findUsablePantryItem(named name: String) -> PantryItem? {
        let normalizedName = Self.normalizeItemName(name)
        return usablePantryItems.first { Self.normalizeItemName($0.name) == normalizedName }
    }

    func availabilityChecks(for ingredients: [Ingredient]) -> [PantryAvailabilityCheck] {
        ingredients.map { ingredient in
            availabilityCheck(
                itemName: ingredient.name,
                requestedQuantityText: ingredient.quantity
            )
        }
    }

    func availabilityChecks(for consumptions: [PantryConsumption]) -> [PantryAvailabilityCheck] {
        consumptions.map { consumption in
            let pantryItem = usablePantryItems.first(where: { $0.id == consumption.pantryItemId })
                ?? findUsablePantryItem(named: consumption.pantryItemName)

            return availabilityCheck(
                itemName: consumption.pantryItemName,
                requestedQuantityText: consumption.usedQuantityText,
                matchedPantryItem: pantryItem
            )
        }
    }

    func availabilityIssues(for ingredients: [Ingredient]) -> [String] {
        availabilityChecks(for: ingredients).compactMap(\.issue)
    }

    func availabilityIssues(for consumptions: [PantryConsumption]) -> [String] {
        availabilityChecks(for: consumptions).compactMap(\.issue)
    }

    func replaySelections(for ingredients: [Ingredient]) -> [PantryRecipeSelection] {
        availabilityChecks(for: ingredients).compactMap { $0.toReplaySelection() }
    }

    func replaySelections(for consumptions: [PantryConsumption]) -> [PantryRecipeSelection] {
        availabilityChecks(for: consumptions).compactMap { $0.toReplaySelection() }
    }

    func refreshIfNeeded() async {
        guard !hasAttemptedInitialSync else { return }
        hasAttemptedInitialSync = true
        await refresh()
    }

    func refresh() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        AppLogger.action(
            "inventory_sync_started",
            screen: "InventoryStore",
            metadata: ["hasBackendURL": config.backendBaseURL == nil ? "false" : "true"]
        )

        func attemptSync() async throws {
            async let pantry = inventoryService.fetchPantry()
            async let grocery = inventoryService.fetchGrocery()

            let remotePantry = try await pantry
            let remoteGrocery = try await grocery

            let mergedPantry = Self.mergedPantry(local: pantryItems, remote: remotePantry)
            let dedupedPantry = Self.dedupedPantry(mergedPantry)
            pantryItems = dedupedPantry.items

            if !dedupedPantry.removedIDs.isEmpty {
                AppLogger.action(
                    "inventory_sync_deduped_pantry",
                    screen: "InventoryStore",
                    metadata: ["removedCount": String(dedupedPantry.removedIDs.count)]
                )
                let toDelete = dedupedPantry.removedIDs
                Task {
                    for id in toDelete {
                        try? await inventoryService.deletePantryItem(id: id)
                    }
                }
            }
            groceryItems = Self.mergedGrocery(local: groceryItems, remote: remoteGrocery)
            persistCache()
            lastSyncError = nil
            AppLogger.action(
                "inventory_sync_succeeded",
                screen: "InventoryStore",
                metadata: ["pantryCount": String(pantryItems.count), "groceryCount": String(groceryItems.count)]
            )
        }

        do {
            try await attemptSync()
        } catch let error as InventorySyncError {
            if case .cancelled = error {
                handleSyncError(error)
                AppLogger.action("inventory_sync_cancelled", screen: "InventoryStore")
                return
            }
            if case .networkError = error {
                AppLogger.action("inventory_sync_retrying", screen: "InventoryStore")
                try? await Task.sleep(nanoseconds: 350_000_000)
                do {
                    try await attemptSync()
                    return
                } catch let retryError as InventorySyncError {
                    handleSyncError(retryError)
                    AppLogger.action(
                        "inventory_sync_failed",
                        screen: "InventoryStore",
                        metadata: ["error": String(describing: retryError), "message": retryError.errorDescription ?? ""]
                    )
                } catch {
                    lastSyncError = "Inventory sync failed. Using the last saved data on this device."
                    AppLogger.action(
                        "inventory_sync_failed",
                        screen: "InventoryStore",
                        metadata: ["error": String(describing: error)]
                    )
                }
                return
            }

            handleSyncError(error)
            AppLogger.action(
                "inventory_sync_failed",
                screen: "InventoryStore",
                metadata: ["error": String(describing: error), "message": error.errorDescription ?? ""]
            )
        } catch {
            lastSyncError = "Inventory sync failed. Using the last saved data on this device."
            AppLogger.action(
                "inventory_sync_failed",
                screen: "InventoryStore",
                metadata: ["error": String(describing: error)]
            )
        }
    }

    func savePantryItem(_ item: PantryItem) async {
        let resolvedItem = resolvedPantryItemForSave(item)
        AppLogger.log("Pantry item saved", metadata: inventoryMetadata(for: resolvedItem))
        applyLocalPantrySave(resolvedItem, replacing: item)
        persistCache()

        do {
            let synced = try await inventoryService.upsertPantryItem(resolvedItem)
            replacePantryItemLocally(synced)
            try? await cleanupMergedPantryItemIfNeeded(original: item, resolved: resolvedItem)
            persistCache()
            lastSyncError = nil
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync pantry changes right now."
        }
    }

    func deletePantryItem(_ item: PantryItem) async {
        AppLogger.log("Pantry item deleted", metadata: ["item": item.name, "quantity": item.quantityText])
        pantryItems.removeAll { $0.id == item.id }
        persistCache()

        do {
            try await inventoryService.deletePantryItem(id: item.id)
            lastSyncError = nil
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync pantry deletion right now."
        }
    }

    func deletePantryItems(_ items: [PantryItem]) async {
        for item in items {
            await deletePantryItem(item)
        }
    }

    func restorePantryItem(_ item: PantryItem) async {
        AppLogger.log("Pantry item restored", metadata: ["item": item.name, "quantity": item.quantityText])
        replacePantryItemLocally(item)
        persistCache()

        do {
            let synced = try await inventoryService.upsertPantryItem(item)
            replacePantryItemLocally(synced)
            persistCache()
            lastSyncError = nil
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync pantry restore right now."
        }
    }

    func saveGroceryItem(_ item: GroceryItem) async {
        let resolvedItem = resolvedGroceryItemForSave(item)
        AppLogger.log("Grocery item saved", metadata: inventoryMetadata(for: resolvedItem))
        applyLocalGrocerySave(resolvedItem, replacing: item)
        persistCache()

        do {
            let synced = try await inventoryService.upsertGroceryItem(resolvedItem)
            replaceGroceryItemLocally(synced)
            try? await cleanupMergedGroceryItemIfNeeded(original: item, resolved: resolvedItem)
            persistCache()
            lastSyncError = nil
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync grocery changes right now."
        }
    }

    func deleteGroceryItem(_ item: GroceryItem) async {
        AppLogger.log("Grocery item deleted", metadata: ["item": item.name, "quantity": item.quantityText])
        groceryItems.removeAll { $0.id == item.id }
        persistCache()

        do {
            try await inventoryService.deleteGroceryItem(id: item.id)
            lastSyncError = nil
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync grocery deletion right now."
        }
    }

    func restoreGroceryItem(_ item: GroceryItem) async {
        AppLogger.log("Grocery item restored", metadata: ["item": item.name, "quantity": item.quantityText])
        replaceGroceryItemLocally(item)
        persistCache()

        do {
            let synced = try await inventoryService.upsertGroceryItem(item)
            replaceGroceryItemLocally(synced)
            persistCache()
            lastSyncError = nil
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync grocery restore right now."
        }
    }

    func markPurchased(_ item: GroceryItem) async {
        await markPurchased(item, expiryDate: nil)
    }

    func markPurchased(_ item: GroceryItem, expiryDate: Date?) async {
        await markPurchased(
            item,
            quantityText: item.quantityText,
            category: item.category,
            expiryDate: expiryDate
        )
    }

    func markPurchased(
        _ item: GroceryItem,
        quantityText: String,
        category: InventoryCategory,
        expiryDate: Date?
    ) async {
        AppLogger.log(
            "Grocery item marked purchased",
            metadata: [
                "item": item.name,
                "quantity": quantityText,
                "category": category.rawValue,
                "expirySet": expiryDate == nil ? "false" : "true"
            ]
        )
        let existingPantryBeforePurchase = pantryItems.first(where: {
            Self.normalizeItemName($0.name) == Self.normalizeItemName(item.name)
        })
        groceryItems.removeAll { $0.id == item.id }

        let purchaseCandidate = GroceryItem(
            id: item.id,
            name: item.name,
            quantityText: quantityText,
            category: category,
            note: item.note,
            source: item.source,
            reasonRecipes: item.reasonRecipes,
            createdAt: item.createdAt
        )

        let localPantryItem = mergedPantryItemForPurchase(purchaseCandidate, expiryDate: expiryDate)
        replacePantryItemLocally(localPantryItem)
        persistCache()

        do {
            let syncedPantryItem: PantryItem
            if let existingPantryItem = existingPantryBeforePurchase,
               existingPantryItem.id == localPantryItem.id {
                let mergedPantryItem = mergePantryItems(existing: existingPantryItem, incoming: localPantryItem, preferredExpiryDate: expiryDate)
                syncedPantryItem = try await inventoryService.upsertPantryItem(mergedPantryItem)
            } else {
                var purchasedPantryItem = try await inventoryService.markPurchased(groceryItem: purchaseCandidate)
                purchasedPantryItem.name = localPantryItem.name
                purchasedPantryItem.quantityText = localPantryItem.quantityText
                purchasedPantryItem.category = localPantryItem.category
                purchasedPantryItem.expiryDate = localPantryItem.expiryDate
                syncedPantryItem = purchasedPantryItem
            }
            replacePantryItemLocally(syncedPantryItem)
            do {
                try await inventoryService.deleteGroceryItem(id: item.id)
            } catch {
                // Ignore secondary cleanup failure and keep the local state consistent.
            }
            persistCache()
            lastSyncError = nil
            AppLogger.log(
                "Pantry item created from grocery",
                metadata: [
                    "item": syncedPantryItem.name,
                    "quantity": syncedPantryItem.quantityText,
                    "expirySet": syncedPantryItem.expiryDate == nil ? "false" : "true"
                ]
            )
        } catch let error as InventorySyncError {
            handleSyncError(error)
        } catch {
            lastSyncError = "Could not sync purchased grocery item right now."
        }
    }

    private func resolvedPantryItemForSave(_ item: PantryItem) -> PantryItem {
        guard let existing = pantryItems.first(where: {
            $0.id != item.id && Self.normalizeItemName($0.name) == Self.normalizeItemName(item.name)
        }) else {
            return item
        }

        let merged = mergePantryItems(existing: existing, incoming: item, preferredExpiryDate: item.expiryDate)
        AppLogger.log(
            "Duplicate pantry item merged",
            metadata: [
                "item": item.name,
                "keptId": existing.id.uuidString,
                "mergedQuantity": merged.quantityText
            ]
        )
        return merged
    }

    private func resolvedGroceryItemForSave(_ item: GroceryItem) -> GroceryItem {
        guard let existing = groceryItems.first(where: {
            $0.id != item.id && Self.normalizeItemName($0.name) == Self.normalizeItemName(item.name)
        }) else {
            return item
        }

        let merged = mergeGroceryItems(existing: existing, incoming: item)
        AppLogger.log(
            "Duplicate grocery item merged",
            metadata: [
                "item": item.name,
                "keptId": existing.id.uuidString,
                "mergedQuantity": merged.quantityText
            ]
        )
        return merged
    }

    private func mergedPantryItemForPurchase(_ groceryItem: GroceryItem, expiryDate: Date?) -> PantryItem {
        let incoming = PantryItem(
            id: groceryItem.id,
            name: groceryItem.name,
            quantityText: groceryItem.quantityText,
            category: groceryItem.category,
            expiryDate: expiryDate,
            updatedAt: .now
        )

        guard let existing = pantryItems.first(where: { Self.normalizeItemName($0.name) == Self.normalizeItemName(groceryItem.name) }) else {
            return incoming
        }

        let purchasedIsFresh = expiryDate.map { Calendar.current.startOfDay(for: $0) >= Calendar.current.startOfDay(for: .now) } ?? true
        if existing.isExpired && purchasedIsFresh {
            AppLogger.log(
                "Purchased pantry item kept separate from expired batch",
                metadata: [
                    "item": groceryItem.name,
                    "expiredBatchId": existing.id.uuidString
                ]
            )
            return incoming
        }

        return mergePantryItems(existing: existing, incoming: incoming, preferredExpiryDate: expiryDate)
    }

    private func mergePantryItems(existing: PantryItem, incoming: PantryItem, preferredExpiryDate: Date?) -> PantryItem {
        PantryItem(
            id: existing.id,
            name: incoming.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? existing.name : incoming.name,
            quantityText: Self.mergeQuantityText(existing.quantityText, incoming.quantityText),
            category: incoming.category,
            expiryDate: preferredExpiryDate ?? incoming.expiryDate ?? existing.expiryDate,
            updatedAt: .now
        )
    }

    private func mergeGroceryItems(existing: GroceryItem, incoming: GroceryItem) -> GroceryItem {
        GroceryItem(
            id: existing.id,
            name: incoming.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? existing.name : incoming.name,
            quantityText: Self.mergeQuantityText(existing.quantityText, incoming.quantityText),
            category: incoming.category,
            note: Self.mergeNotes(existing.note, incoming.note),
            source: incoming.source == .manual ? existing.source : incoming.source,
            reasonRecipes: Array(Set(existing.reasonRecipes + incoming.reasonRecipes)).sorted(),
            createdAt: existing.createdAt
        )
    }

    func consumePantryItems(_ consumptions: [PantryConsumption]) async -> PantryConsumptionResult {
        AppLogger.log(
            "Pantry consumption submitted",
            metadata: ["entries": consumptions.map { "\($0.pantryItemName)=\($0.usedQuantityText)" }.joined(separator: ", ")]
        )

        let validationWarnings = consumptionWarnings(for: consumptions)
        guard validationWarnings.isEmpty else {
            for warning in validationWarnings {
                AppLogger.log("Pantry consumption warning", metadata: ["warning": warning])
            }
            return PantryConsumptionResult(warnings: validationWarnings, applied: false)
        }

        for consumption in consumptions {
            guard let currentItem = pantryItems.first(where: { $0.id == consumption.pantryItemId }) else {
                continue
            }

            switch currentItem.applyingConsumption(consumption.usedQuantityText) {
            case .unchanged:
                continue
            case let .updated(updatedItem):
                AppLogger.log("Pantry item decremented", metadata: ["item": updatedItem.name, "newQuantity": updatedItem.quantityText])
                await savePantryItem(updatedItem)
            case .remove:
                AppLogger.log("Pantry item fully consumed", metadata: ["item": currentItem.name])
                await deletePantryItem(currentItem)
            case let .warning(message):
                AppLogger.log("Pantry consumption warning", metadata: ["warning": message])
            }
        }

        return PantryConsumptionResult(warnings: [], applied: true)
    }

    private func replacePantryItemLocally(_ item: PantryItem) {
        if let index = pantryItems.firstIndex(where: { $0.id == item.id }) {
            pantryItems[index] = item
        } else {
            pantryItems.append(item)
        }
    }

    private func replaceGroceryItemLocally(_ item: GroceryItem) {
        if let index = groceryItems.firstIndex(where: { $0.id == item.id }) {
            groceryItems[index] = item
        } else {
            groceryItems.append(item)
        }
    }

    private func applyLocalPantrySave(_ resolvedItem: PantryItem, replacing originalItem: PantryItem) {
        replacePantryItemLocally(resolvedItem)
        if resolvedItem.id != originalItem.id {
            pantryItems.removeAll { $0.id == originalItem.id }
        }
    }

    private func applyLocalGrocerySave(_ resolvedItem: GroceryItem, replacing originalItem: GroceryItem) {
        replaceGroceryItemLocally(resolvedItem)
        if resolvedItem.id != originalItem.id {
            groceryItems.removeAll { $0.id == originalItem.id }
        }
    }

    private func cleanupMergedPantryItemIfNeeded(original: PantryItem, resolved: PantryItem) async throws {
        guard resolved.id != original.id else { return }
        do {
            try await inventoryService.deletePantryItem(id: original.id)
        } catch {
            // Ignore cleanup failure and keep the merged pantry item locally.
        }
    }

    private func cleanupMergedGroceryItemIfNeeded(original: GroceryItem, resolved: GroceryItem) async throws {
        guard resolved.id != original.id else { return }
        do {
            try await inventoryService.deleteGroceryItem(id: original.id)
        } catch {
            // Ignore cleanup failure and keep the merged grocery item locally.
        }
    }

    private func loadCache() {
        if let pantryData = userDefaults.data(forKey: pantryStorageKey) {
            guard PersistencePayloadValidator.matchesExpectedTopLevel(pantryData, shape: .array) else {
                pantryItems = []
                AppLogger.action(
                    "persistence_decode_failed",
                    screen: "InventoryStore",
                    metadata: ["key": pantryStorageKey, "entity": "pantry", "error": "Unexpected top-level JSON shape"]
                )
                return
            }
            do {
                pantryItems = try decoder.decode([PantryItem].self, from: pantryData)
            } catch {
                pantryItems = []
                AppLogger.action(
                    "persistence_decode_failed",
                    screen: "InventoryStore",
                    metadata: ["key": pantryStorageKey, "entity": "pantry", "error": String(describing: error)]
                )
            }
        }

        if let groceryData = userDefaults.data(forKey: groceryStorageKey) {
            guard PersistencePayloadValidator.matchesExpectedTopLevel(groceryData, shape: .array) else {
                groceryItems = []
                AppLogger.action(
                    "persistence_decode_failed",
                    screen: "InventoryStore",
                    metadata: ["key": groceryStorageKey, "entity": "grocery", "error": "Unexpected top-level JSON shape"]
                )
                return
            }
            do {
                groceryItems = try decoder.decode([GroceryItem].self, from: groceryData)
            } catch {
                groceryItems = []
                AppLogger.action(
                    "persistence_decode_failed",
                    screen: "InventoryStore",
                    metadata: ["key": groceryStorageKey, "entity": "grocery", "error": String(describing: error)]
                )
            }
        }
    }

    private func persistCache() {
        do {
            let pantryData = try encoder.encode(pantryItems)
            userDefaults.set(pantryData, forKey: pantryStorageKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "InventoryStore",
                metadata: ["key": pantryStorageKey, "entity": "pantry", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist pantry items: \(error)")
        }

        do {
            let groceryData = try encoder.encode(groceryItems)
            userDefaults.set(groceryData, forKey: groceryStorageKey)
        } catch {
            AppLogger.action(
                "persistence_encode_failed",
                screen: "InventoryStore",
                metadata: ["key": groceryStorageKey, "entity": "grocery", "error": String(describing: error)]
            )
            assertionFailure("Failed to persist grocery items: \(error)")
        }
    }

    func reloadFromDisk() {
        loadCache()
        lastSyncError = nil
    }

    private func handleSyncError(_ error: InventorySyncError) {
        if case .missingBackendURL = error {
            lastSyncError = nil
            return
        }
        if case .cancelled = error {
            lastSyncError = nil
            return
        }
        lastSyncError = error.errorDescription
    }

    private static func mergedPantry(local: [PantryItem], remote: [PantryItem]) -> [PantryItem] {
        var byId: [UUID: PantryItem] = [:]
        byId.reserveCapacity(max(local.count, remote.count))

        for item in remote {
            byId[item.id] = item
        }
        for item in local {
            guard let existing = byId[item.id] else {
                byId[item.id] = item
                continue
            }
            // If both sides have the same item id, prefer the newer update.
            if item.updatedAt > existing.updatedAt {
                byId[item.id] = item
            }
        }

        // Prefer remote ordering for visible stability; append local-only items at end.
        var result: [PantryItem] = []
        result.reserveCapacity(byId.count)

        var seen = Set<UUID>()
        seen.reserveCapacity(byId.count)

        for item in remote {
            if let resolved = byId[item.id] {
                result.append(resolved)
                seen.insert(item.id)
            }
        }
        for item in local where !seen.contains(item.id) {
            if let resolved = byId[item.id] {
                result.append(resolved)
            }
        }
        return result
    }

    private static func mergedGrocery(local: [GroceryItem], remote: [GroceryItem]) -> [GroceryItem] {
        var byId: [UUID: GroceryItem] = [:]
        byId.reserveCapacity(max(local.count, remote.count))

        for item in remote {
            byId[item.id] = item
        }
        for item in local {
            // GroceryItem doesn't have updatedAt; keep remote if it exists, otherwise keep local.
            if byId[item.id] == nil {
                byId[item.id] = item
            }
        }

        var result: [GroceryItem] = []
        result.reserveCapacity(byId.count)

        var seen = Set<UUID>()
        seen.reserveCapacity(byId.count)

        for item in remote {
            if let resolved = byId[item.id] {
                result.append(resolved)
                seen.insert(item.id)
            }
        }
        for item in local where !seen.contains(item.id) {
            if let resolved = byId[item.id] {
                result.append(resolved)
            }
        }
        return result
    }

    private struct PantryDedupResult {
        let items: [PantryItem]
        let removedIDs: [UUID]
    }

    private static func dedupedPantry(_ items: [PantryItem]) -> PantryDedupResult {
        guard items.count > 1 else { return PantryDedupResult(items: items, removedIDs: []) }

        let grouped = Dictionary(grouping: items, by: { normalizeItemName($0.name) })
        var kept: [PantryItem] = []
        kept.reserveCapacity(items.count)
        var removed: [UUID] = []

        for (_, group) in grouped {
            if group.count == 1, let only = group.first {
                kept.append(only)
                continue
            }

            guard let canonical = group.max(by: { $0.updatedAt < $1.updatedAt }) else { continue }
            var merged = canonical

            for item in group where item.id != canonical.id {
                merged = mergePantryForDedup(existing: merged, incoming: item)
                removed.append(item.id)
            }

            kept.append(merged)
        }

        // Keep stable ordering similar to original `items`.
        let keptById = Dictionary(uniqueKeysWithValues: kept.map { ($0.id, $0) })
        var ordered: [PantryItem] = []
        ordered.reserveCapacity(keptById.count)
        var seen = Set<UUID>()
        seen.reserveCapacity(keptById.count)
        for item in items {
            if let resolved = keptById[item.id], !seen.contains(resolved.id) {
                ordered.append(resolved)
                seen.insert(resolved.id)
            }
        }
        for item in kept where !seen.contains(item.id) {
            ordered.append(item)
        }

        return PantryDedupResult(items: ordered, removedIDs: removed)
    }

    nonisolated private static func mergePantryForDedup(existing: PantryItem, incoming: PantryItem) -> PantryItem {
        PantryItem(
            id: existing.id,
            name: incoming.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? existing.name : incoming.name,
            quantityText: mergeQuantityText(existing.quantityText, incoming.quantityText),
            category: incoming.category,
            expiryDate: incoming.expiryDate ?? existing.expiryDate,
            updatedAt: max(existing.updatedAt, incoming.updatedAt)
        )
    }

    private func consumptionWarnings(for consumptions: [PantryConsumption]) -> [String] {
        consumptions.compactMap { consumption in
            guard let currentItem = pantryItems.first(where: { $0.id == consumption.pantryItemId }) else {
                let trimmedUsed = consumption.usedQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedUsed.isEmpty else { return nil }
                return "\(consumption.pantryItemName) is no longer available in pantry."
            }

            switch currentItem.applyingConsumption(consumption.usedQuantityText) {
            case .warning(let message):
                return message
            case .unchanged, .updated, .remove:
                return nil
            }
        }
    }

    private func availabilityCheck(
        itemName: String,
        requestedQuantityText: String,
        matchedPantryItem: PantryItem? = nil
    ) -> PantryAvailabilityCheck {
        let pantryItem = matchedPantryItem ?? findUsablePantryItem(named: itemName)

        guard let pantryItem else {
            return PantryAvailabilityCheck(
                itemName: itemName,
                requestedQuantityText: requestedQuantityText,
                pantryItem: nil,
                issue: "\(itemName) is not currently available in pantry."
            )
        }

        let trimmedQuantity = requestedQuantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuantity.isEmpty else {
            return PantryAvailabilityCheck(
                itemName: itemName,
                requestedQuantityText: requestedQuantityText,
                pantryItem: pantryItem,
                issue: nil
            )
        }

        switch pantryItem.applyingConsumption(trimmedQuantity) {
        case .updated, .remove, .unchanged:
            return PantryAvailabilityCheck(
                itemName: itemName,
                requestedQuantityText: requestedQuantityText,
                pantryItem: pantryItem,
                issue: nil
            )
        case let .warning(message):
            return PantryAvailabilityCheck(
                itemName: itemName,
                requestedQuantityText: requestedQuantityText,
                pantryItem: pantryItem,
                issue: message
            )
        }
    }

    nonisolated private static func normalizeItemName(_ value: String) -> String {
        KnownInventoryItemNormalizer.normalize(value)
    }

    nonisolated private static func mergeQuantityText(_ existing: String, _ incoming: String) -> String {
        let trimmedExisting = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIncoming = incoming.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedExisting.isEmpty { return trimmedIncoming }
        if trimmedIncoming.isEmpty { return trimmedExisting }
        if trimmedExisting.caseInsensitiveCompare(trimmedIncoming) == .orderedSame { return trimmedExisting }

        if let existingStructured = StructuredQuantity.parse(trimmedExisting),
           let incomingStructured = StructuredQuantity.parse(trimmedIncoming),
           existingStructured.unit == incomingStructured.unit {
            return StructuredQuantity(
                amount: existingStructured.amount + incomingStructured.amount,
                unit: existingStructured.unit
            ).displayText
        }

        return "\(trimmedExisting) + \(trimmedIncoming)"
    }

    private func inventoryMetadata(for item: PantryItem) -> [String: String] {
        [
            "item": item.name,
            "quantity": item.quantityText,
            "category": item.category.rawValue
        ]
    }

    private func inventoryMetadata(for item: GroceryItem) -> [String: String] {
        [
            "item": item.name,
            "quantity": item.quantityText,
            "category": item.category.rawValue,
            "source": item.source.rawValue
        ]
    }

    nonisolated private static func mergeNotes(_ existing: String?, _ incoming: String?) -> String? {
        let parts = [existing, incoming]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }
        return Array(Set(parts)).sorted().joined(separator: " • ")
    }
}
