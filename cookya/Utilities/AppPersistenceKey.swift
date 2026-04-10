import Foundation

enum AppPersistenceKey {
    static let pantryItems = "pantry_items_v1"
    static let groceryItems = "grocery_items_v1"
    static let savedRecipes = "saved_recipes_v1"
    static let generatedRecipeCache = "generated_recipe_cache_v1"
    static let generatedRecipeTimestamps = "generated_recipe_cache_timestamps_v1"
    static let cookedMealRecords = "cooked_meal_records_v1"
    static let primaryProfile = "primary_profile_v1"
    static let guestModeActive = "guest_mode_active_v1"
    static let knownInventoryItems = "known_inventory_items_v1"

    // Backend snapshot sync status (local metadata only)
    static let backendSnapshotLastUploadAt = "backend_snapshot_last_upload_at_v1"
    static let backendSnapshotLastRestoreAt = "backend_snapshot_last_restore_at_v1"
    static let backendSnapshotLastError = "backend_snapshot_last_error_v1"
}
