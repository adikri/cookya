import Foundation

enum BackupImportApplier {
    struct ApplyResult: Equatable {
        let restoredKeys: [String]
    }

    static func applyReplaceAll(
        _ backup: CookyaExportBackup,
        to userDefaults: UserDefaults = .standard
    ) -> ApplyResult {
        var restored: [String] = []
        let snapshot = backup.snapshot

        if let data = snapshot.pantryItemsData {
            userDefaults.set(data, forKey: AppPersistenceKey.pantryItems)
            restored.append(AppPersistenceKey.pantryItems)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.pantryItems)
        }

        if let data = snapshot.groceryItemsData {
            userDefaults.set(data, forKey: AppPersistenceKey.groceryItems)
            restored.append(AppPersistenceKey.groceryItems)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.groceryItems)
        }

        if let data = snapshot.savedRecipesData {
            userDefaults.set(data, forKey: AppPersistenceKey.savedRecipes)
            restored.append(AppPersistenceKey.savedRecipes)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.savedRecipes)
        }

        if let data = snapshot.cookedMealRecordsData {
            userDefaults.set(data, forKey: AppPersistenceKey.cookedMealRecords)
            restored.append(AppPersistenceKey.cookedMealRecords)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.cookedMealRecords)
        }

        if let data = snapshot.primaryProfileData {
            userDefaults.set(data, forKey: AppPersistenceKey.primaryProfile)
            restored.append(AppPersistenceKey.primaryProfile)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.primaryProfile)
        }

        if let value = snapshot.guestModeActive {
            userDefaults.set(value, forKey: AppPersistenceKey.guestModeActive)
            restored.append(AppPersistenceKey.guestModeActive)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.guestModeActive)
        }

        if let data = snapshot.knownInventoryItemsData {
            userDefaults.set(data, forKey: AppPersistenceKey.knownInventoryItems)
            restored.append(AppPersistenceKey.knownInventoryItems)
        } else {
            userDefaults.removeObject(forKey: AppPersistenceKey.knownInventoryItems)
        }

        return ApplyResult(restoredKeys: restored)
    }
}

