import SwiftUI

struct PantryView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore

    @State private var editorItem: PantryItem?
    @State private var expiryItem: PantryItem?
    @State private var quantityAdjustItem: PantryItem?
    @State private var isAddingItem = false
    @State private var isDiscardingExpiredItems = false
    @State private var isShowingExpiryReview = false
    @State private var deletedPantryItem: PantryItem?

    var body: some View {
        List {
            if inventoryStore.sortedPantryItems.isEmpty {
                ContentUnavailableView(
                    "No Pantry Items",
                    systemImage: "cabinet",
                    description: Text("Add ingredients you already have at home so Cookya can suggest realistic meals.")
                )
                .listRowBackground(Color.clear)
            } else {
                if !itemsNeedingExpiryReview.isEmpty {
                    Section {
                        Button {
                            isShowingExpiryReview = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Review pantry dates")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(itemsNeedingExpiryReview.count) item(s) need expiry review.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "calendar.badge.clock")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Quick Review")
                    }
                }

                if !useSoonPantryItems.isEmpty {
                    Section {
                        ForEach(useSoonPantryItems) { item in
                            pantryRow(for: item)
                        }
                    } header: {
                        Text("Use Soon")
                    } footer: {
                        Text("These items are still usable, but they should be reviewed soon to avoid waste.")
                    }
                }

                if !activePantryItems.isEmpty {
                    Section {
                        ForEach(activePantryItems) { item in
                            pantryRow(for: item)
                        }
                    } header: {
                        Text("Available")
                    }
                }

                if !expiredPantryItems.isEmpty {
                    Section {
                        ForEach(expiredPantryItems) { item in
                            pantryRow(for: item)
                        }
                    } header: {
                        Text("Expired")
                    } footer: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Expired items stay visible so you can update expiry, discard them, or review what should no longer be used.")
                            Button("Discard All") {
                                isDiscardingExpiredItems = true
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
        .navigationTitle("Pantry")
        .onAppear {
            AppLogger.screen("Pantry", metadata: ["itemCount": String(inventoryStore.pantryItems.count)])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingItem = true
                } label: {
                    Label("Add Pantry Item", systemImage: "plus")
                }
            }
        }
        .refreshable {
            await inventoryStore.refresh()
        }
        .sheet(isPresented: $isAddingItem) {
            PantryItemEditorView(item: nil) { item in
                Task { await inventoryStore.savePantryItem(item) }
            }
        }
        .sheet(item: $editorItem) { item in
            PantryItemEditorView(item: item) { updated in
                Task { await inventoryStore.savePantryItem(updated) }
            }
        }
        .sheet(item: $expiryItem) { item in
            PantryExpirySheet(item: item) { expiryDate in
                var updated = item
                updated.expiryDate = expiryDate
                updated.updatedAt = .now
                Task { await inventoryStore.savePantryItem(updated) }
            }
        }
        .sheet(item: $quantityAdjustItem) { item in
            PantryQuickAdjustSheet(item: item) { updated in
                Task { await inventoryStore.savePantryItem(updated) }
            }
        }
        .sheet(isPresented: $isShowingExpiryReview) {
            PantryBatchExpiryReviewSheet(items: itemsNeedingExpiryReview) { item, expiryDate in
                var updated = item
                updated.expiryDate = expiryDate
                updated.updatedAt = .now
                Task { await inventoryStore.savePantryItem(updated) }
            }
        }
        .alert("Discard expired items?", isPresented: $isDiscardingExpiredItems) {
            Button("Cancel", role: .cancel) {}
            Button("Discard All", role: .destructive) {
                let itemsToDelete = expiredPantryItems
                AppLogger.action(
                    "expired_items_bulk_discarded",
                    screen: "Pantry",
                    metadata: ["count": String(itemsToDelete.count)]
                )
                Task { await inventoryStore.deletePantryItems(itemsToDelete) }
            }
        } message: {
            Text("This will remove all expired pantry items. You can still update expiry individually if any item is still usable.")
        }
        .safeAreaInset(edge: .bottom) {
            if let item = deletedPantryItem {
                UndoBannerView(
                    message: "\(item.name) removed from Pantry.",
                    undoTitle: "Undo"
                ) {
                    let itemToRestore = deletedPantryItem
                    self.deletedPantryItem = nil
                    guard let itemToRestore else { return }
                    Task { await inventoryStore.restorePantryItem(itemToRestore) }
                } onDismiss: {
                    deletedPantryItem = nil
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    private var activePantryItems: [PantryItem] {
        inventoryStore.sortedPantryItems.filter { !$0.isExpired && !$0.isExpiringSoon }
    }

    private var useSoonPantryItems: [PantryItem] {
        inventoryStore.sortedPantryItems.filter(\.isExpiringSoon)
    }

    private var expiredPantryItems: [PantryItem] {
        inventoryStore.sortedPantryItems.filter(\.isExpired)
    }

    private var itemsNeedingExpiryReview: [PantryItem] {
        expiredPantryItems + useSoonPantryItems
    }

    @ViewBuilder
    private func pantryRow(for item: PantryItem) -> some View {
        Button {
            AppLogger.action("pantry_row_opened", screen: "Pantry", metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"])
            editorItem = item
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if item.isExpiringSoon {
                            Text("Use soon")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.14), in: Capsule())
                                .foregroundStyle(.orange)
                        }
                        if item.isExpired {
                            Text("Expired")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.14), in: Capsule())
                                .foregroundStyle(.red)
                        }
                    }

                    Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let expiryDate = item.expiryDate {
                    Text(expiryDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(item.isExpired ? .red : (item.isExpiringSoon ? .orange : .secondary))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                AppLogger.action(
                    "pantry_adjust_quantity_tapped",
                    screen: "Pantry",
                    metadata: ["item": item.name]
                )
                quantityAdjustItem = item
            } label: {
                Label("Adjust Quantity", systemImage: "slider.horizontal.3")
            }
            .tint(.blue)

            Button {
                AppLogger.action(
                    "pantry_expiry_action_tapped",
                    screen: "Pantry",
                    metadata: ["item": item.name, "action": "update_expiry"]
                )
                expiryItem = item
            } label: {
                Label("Update Expiry", systemImage: "calendar.badge.clock")
            }
            .tint(.orange)
        }
        .swipeActions {
            Button {
                AppLogger.action(
                    "pantry_add_to_grocery",
                    screen: "Pantry",
                    metadata: ["item": item.name]
                )
                Task {
                    await inventoryStore.saveGroceryItem(
                        GroceryItem(
                            name: item.name,
                            quantityText: item.quantityText,
                            category: item.category,
                            note: "Restock pantry",
                            source: .manual,
                            createdAt: .now
                        )
                    )
                }
            } label: {
                Label("Add to Grocery", systemImage: "cart.badge.plus")
            }
            .tint(.green)

            Button(role: .destructive) {
                AppLogger.action(
                    "expired_item_discarded",
                    screen: "Pantry",
                    metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"]
                )
                deletePantryItemWithUndo(item)
            } label: {
                Label(item.isExpired ? "Discard" : "Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                AppLogger.action(
                    "pantry_adjust_quantity_tapped",
                    screen: "Pantry",
                    metadata: ["item": item.name]
                )
                quantityAdjustItem = item
            } label: {
                Label("Adjust Quantity", systemImage: "slider.horizontal.3")
            }

            Button {
                AppLogger.action(
                    "pantry_add_to_grocery",
                    screen: "Pantry",
                    metadata: ["item": item.name]
                )
                Task {
                    await inventoryStore.saveGroceryItem(
                        GroceryItem(
                            name: item.name,
                            quantityText: item.quantityText,
                            category: item.category,
                            note: "Restock pantry",
                            source: .manual,
                            createdAt: .now
                        )
                    )
                }
            } label: {
                Label("Add to Grocery", systemImage: "cart.badge.plus")
            }

            Button {
                AppLogger.action(
                    "pantry_expiry_action_tapped",
                    screen: "Pantry",
                    metadata: ["item": item.name, "action": "update_expiry"]
                )
                expiryItem = item
            } label: {
                Label("Update Expiry", systemImage: "calendar")
            }

            Button(role: .destructive) {
                AppLogger.action(
                    "expired_item_discarded",
                    screen: "Pantry",
                    metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"]
                )
                deletePantryItemWithUndo(item)
            } label: {
                Label(item.isExpired ? "Discard" : "Delete", systemImage: "trash")
            }
        }
    }

    private func deletePantryItemWithUndo(_ item: PantryItem) {
        deletedPantryItem = item
        Task { await inventoryStore.deletePantryItem(item) }
    }
}

private struct PantryQuickAdjustSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: PantryItem
    let onSave: (PantryItem) -> Void

    @State private var quantityText: String

    init(item: PantryItem, onSave: @escaping (PantryItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _quantityText = State(initialValue: item.quantityText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.name)
                        .font(.headline)
                    Text(item.category.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Item")
                }

                Section {
                    QuantityInputView(title: "Quantity", quantityText: $quantityText)
                } header: {
                    Text("Quantity")
                } footer: {
                    Text("Use this for fast pantry corrections without opening the full edit screen.")
                }
            }
            .navigationTitle("Adjust Quantity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = item
                        updated.quantityText = quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.updatedAt = .now
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PantryView()
            .environmentObject(InventoryStore())
    }
}

struct UndoBannerView: View {
    let message: String
    let undoTitle: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(undoTitle, action: onUndo)
                .font(.subheadline.weight(.semibold))

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}
